import 'package:flutter/material.dart';
// import 'package:sesh/widgets/colors.dart';
import 'package:sesh/widgets/sideBar.dart';
import 'package:sesh/widgets/globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroupChat extends StatefulWidget {
  final String projectName;
  final int projectId;

  const GroupChat({super.key, required this.projectName, required this.projectId});

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChat> {
  final TextEditingController _messageController = TextEditingController();
  // zoznam sprav, ktore sa budu zobrazovat v chatovacej miestnosti
  // prvky v zozname su mapy s klucmi 'message' a 'username'
  final List<Map<String, String>> _messages = [];  

  @override
  void initState() {
    super.initState();
    _fetchMessages(); 
  }

  // metoda na ziskanie sprav z backendu
  Future<void> _fetchMessages() async {
    // widget.projectName sme ziskali z project.dart, kde sme ho zadali pri vytvarani GroupChat
    final url = Uri.parse('http://localhost:3000/messages/getMessages?projectName=${widget.projectName}');
    
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        setState(() {
          _messages.clear();
          // pre kazdu spravu v data, pridame do _messages mapu s klucmi 'message' a 'username'
          for (var message in data) {
            _messages.add({
              'message': message['message'],  
              'username': message['username'],  
            });
          }
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
        ),
      );
    }
  }

  // metoda na odoslanie spravy
  // kontroluje, ci je textovy vstup prazdny, ak nie, pridava spravu do zoznamu _messages
  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      String message = _messageController.text.trim();

      setState(() {
        _messages.add({
          'username': globals.username,
          'message': message,
        });
      });

      _messageController.clear();

      // odoslanie spravy na server
      await _sendMessageToServer(message);
    }
  }

  Future<void> _sendMessageToServer(String message) async {
    final url = Uri.parse('http://localhost:3000/messages/sendMessage');
    
    // telo spravy, ktore sa posle na server
    // obsahuje nazov projektu, spravu a uzivatelske meno
    final body = jsonEncode({
      'projectName': widget.projectName,
      'message': message,
      'userName': globals.username,  
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent successfully'),
        ),
      );
      } 
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideBar(
        onProjectsTap: () {
          Navigator.pop(context); 
          Future.delayed(const Duration(milliseconds: 300), () {
            Navigator.pushNamed(context, '/projects');
          });
        },
        // onChatsTap: () {
        //   Navigator.pop(context);
        //   Future.delayed(const Duration(milliseconds: 300), () {
        //     Navigator.pushNamed(context, '/chats');
        //   });
        // },
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
        color: const Color.fromARGB(255, 195, 233, 233), 
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  // kontrola, ci je sprava od aktualneho uzivatela
                  // ak ano, nastavime zarovnanie spravy doprava, inak do lava
                  bool isCurrentUser = _messages[index]['username'] == globals.username;

                  return Align(
                    alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,  
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            // zobrazenie mena uzivatela, ktory poslal spravu
                            _messages[index]['username']!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,  
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),  
                        // kontajner, ktory obsahuje samotnu spravu
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                          decoration: BoxDecoration(
                            // ak je sprava od aktualneho uzivatela, nastavime modru farbu, inak sivu
                            color: isCurrentUser ? Colors.blueAccent : Colors.grey[300], 
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12.0),
                              topRight: Radius.circular(12.0),
                              bottomLeft: Radius.circular(12.0),
                              bottomRight: Radius.circular(12.0),
                            ),
                          ),
                          // obmedzenie sirky spravy, aby nezaberala celu sirku obrazovky
                          // pouzivame MediaQuery na ziskanie sirky obrazovky
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: Text(
                            // zobrazenie samotnej spravy
                            _messages[index]['message']!,
                            // ak je sprava od aktualneho uzivatela, nastavime bielu farbu, inak ciernu
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
            // textove pole na zadanie spravy
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
                  // tlačidlo na odoslanie spravy
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
            // spodna cast obrazovky, paticka
            Container(
            color: const Color.fromARGB(255, 34, 34, 34),
            padding: const EdgeInsets.all(8.0),
            alignment: Alignment.center,
            child: const Text(
              '© Veronika Kalejová 2025',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
