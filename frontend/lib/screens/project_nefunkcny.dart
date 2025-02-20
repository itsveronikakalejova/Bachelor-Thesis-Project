import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ProjectPage extends StatefulWidget {
  final String username; // Pridáme meno užívateľa pri prihlásení

  const ProjectPage({super.key, required this.username});

  @override
  _ProjectPageState createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  final TextEditingController _contentController = TextEditingController();
  late IO.Socket socket;
  String userPermission = "Can View"; // Defaultne nastavené práva

  @override
  void initState() {
    super.initState();
    _connectToSocket();
  }

  void _connectToSocket() {
    socket = IO.io("http://127.0.0.1:2000", IO.OptionBuilder()
        .setTransports(["websocket"])
        .disableAutoConnect()
        .build());

    socket.connect();

    socket.onConnect((_) {
      print("Connected to server as ${widget.username}");
      socket.emit("join_session", {"username": widget.username});
    });

    socket.on("initial_data", (data) {
      print("Received initial data: $data");
      setState(() {
        _contentController.text = data["code"] ?? "";
        userPermission = data["permission"] ?? "Can View";
      });
    });

    socket.on("code_update", (code) {
      print("Code updated: $code");
      setState(() {
        _contentController.text = code ?? "";
      });
    });

    socket.on("permission_denied", (message) {
      print("Permission denied: $message");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });

    socket.on("permission_changed", (data) {
      print("Permission changed: $data");
      if (data["user"] == widget.username) {
        setState(() {
          userPermission = data["permission"];
        });
      }
    });

    socket.onDisconnect((_) {
      print("Disconnected from server");
    });

    socket.onError((error) {
      print("Socket error: $error");
    });
  }


  void _sendCodeUpdate() {
    if (userPermission != "Can Edit") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You don't have edit rights!")),
      );
      return;
    }

    socket.emit("update_code", {
      "username": widget.username,
      "code": _contentController.text,
    });
  }

  void _showShareDialog() {
    String selectedPrivilege = 'Can View';
    String selectedPerson = 'Majo';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Share Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select User:'),
              DropdownButton<String>(
                value: selectedPerson,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedPerson = newValue!;
                  });
                },
                items: <String>['Majo', 'Peto', 'Jano']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Select Privileges:'),
              DropdownButton<String>(
                value: selectedPrivilege,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedPrivilege = newValue!;
                  });
                },
                items: <String>['Can Edit', 'Can View']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      socket.emit("update_permission", {
                        "targetUser": selectedPerson,
                        "permission": selectedPrivilege,
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text('Share'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 34, 34, 34),
      appBar: AppBar(
        title: Text("Editing as ${widget.username} ($userPermission)"),
      ),
      body: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _contentController,
              maxLines: null,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => _sendCodeUpdate(),
              enabled: userPermission == "Can Edit",
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Type your code here...',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _showShareDialog,
            child: const Text("Share"),
          ),
        ],
      ),
    );
  }
}
