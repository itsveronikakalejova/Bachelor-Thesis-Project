import 'package:flutter/material.dart';
import 'package:sesh/widgets/colors.dart';
import 'package:sesh/widgets/sideBar.dart';
import 'package:sesh/widgets/globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroupChatScreen extends StatefulWidget {
  final String projectName;
  final int projectId;

  const GroupChatScreen({super.key, required this.projectName, required this.projectId});

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];  // Changed this to store maps with 'username' and 'message'

  @override
  void initState() {
    super.initState();
    _fetchMessages(); // Fetch messages when the screen is loaded
  }

  Future<void> _fetchMessages() async {
    final url = Uri.parse('http://localhost:3000/messages/getMessages?projectName=${widget.projectName}');
    
    try {
      final response = await http.get(url);

      // Skontrolujeme, či je status kód 200 (OK)
      if (response.statusCode == 200) {
        // Dekódujeme odpoveď do zoznamu dynamických objektov
        List<dynamic> data = jsonDecode(response.body);

        setState(() {
          _messages.clear();

          // Načítame všetky správy z dát a pridáme 'username' a 'message'
          for (var message in data) {
            _messages.add({
              'message': message['message'],    // A správu
              'username': message['username'],  // Pridáme aj username
            });
          }
        });
      } else {
        print('Failed to load messages');
      }
    } catch (error) {
      print('Error: $error');
    }
  }


  // Method to send a message
  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      String message = _messageController.text.trim();

      // Add the message to the local list
      setState(() {
        _messages.add({
          'username': globals.username,
          'message': message,
        });
      });

      // Clear the text field
      _messageController.clear();

      // Send the message to the server via POST request
      await _sendMessageToServer(message);
    }
  }

  // Method to send message to the server
  Future<void> _sendMessageToServer(String message) async {
    final url = Uri.parse('http://localhost:3000/messages/sendMessage');
    
    // Request body
    final body = jsonEncode({
      'projectName': widget.projectName,
      'message': message,
      'userName': globals.username,  // Use global username
    });

    // Send POST request
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        // Message was successfully sent
        print('Message sent successfully');
      } else {
        // Error while sending the message
        print('Failed to send message');
      }
    } catch (error) {
      // Handle error (e.g. connection issues)
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideBar(
        onProjectsTap: () {
          Navigator.pop(context); // Zavrie Drawer
          Future.delayed(const Duration(milliseconds: 300), () {
            Navigator.pushNamed(context, '/projects');
          });
        },
        onChatsTap: () {
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 300), () {
            Navigator.pushNamed(context, '/chats');
          });
        },
        onTasksTap: () {
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 300), () {
            Navigator.pushNamed(context, '/tasks');
          });
        },
      ),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        title: Text(
          widget.projectName,
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Go back ↩',
              style: TextStyle(color: Colors.black),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        color: const Color.fromARGB(255, 195, 233, 233), // Updated background color
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  // Skontrolujeme, či je správa od prihláseného používateľa
                  bool isCurrentUser = _messages[index]['username'] == globals.username;

                  return Align(
                    alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,  // Zarovnáme všetko doľava
                      children: [
                        // Meno používateľa
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            _messages[index]['username']!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,  // Meno bude malé
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),  // Medzera medzi menom a správou
                        // Správa v samostatnej bunke
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                          decoration: BoxDecoration(
                            color: isCurrentUser ? Colors.blueAccent : Colors.grey[300], // Modrá pre aktuálneho používateľa, sivá pre ostatných
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12.0),
                              topRight: Radius.circular(12.0),
                              bottomLeft: Radius.circular(12.0),
                              bottomRight: Radius.circular(12.0),
                            ),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: Text(
                            _messages[index]['message']!,
                            style: TextStyle(
                              color: isCurrentUser ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
