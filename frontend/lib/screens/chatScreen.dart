import 'package:flutter/material.dart';
import 'package:sesh/widgets/sideBar.dart';


class ChatScreen extends StatefulWidget {
  final String userName;

  const ChatScreen({super.key, required this.userName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add(_messageController.text.trim());
      });
      _messageController.clear();
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
        backgroundColor: Colors.white,
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 200,
                  color: const Color.fromARGB(255, 214, 243, 243),
                  child: ListView(
                    children: [
                      _buildChatTile('Peto', context),
                      _buildChatTile('Majo', context),
                      _buildChatTile('Jozo', context),
                      _buildChatTile('Jano', context),
                      _buildChatTile('Miro', context),
                      _buildChatTile('Pato', context),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color.fromARGB(255, 195, 233, 233),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          alignment: Alignment.centerLeft,
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 44, 44, 44),
                          ),
                          child: Text(
                            widget.userName,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              return Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.all(12.0),
                                  margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                  decoration: const BoxDecoration(
                                    color: Colors.lightBlueAccent,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12.0),
                                      topRight: Radius.circular(12.0),
                                      bottomLeft: Radius.circular(12.0),
                                    ),
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  child: Text(
                                    _messages[index],
                                    style: const TextStyle(color: Colors.white),
                                  ),
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
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(8.0)),
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
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: const Color.fromARGB(255, 34, 34, 34),
            alignment: Alignment.center,
            child: const Text(
              '© Veronika Kalejová 2024',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(String name, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      color: const Color.fromARGB(255, 240, 255, 255),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueGrey,
          child: Text(
            name[0],
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(name),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(userName: name),
            ),
          );
        },
      ),
    );
  }
}
