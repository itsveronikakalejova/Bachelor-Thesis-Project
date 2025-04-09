import 'package:flutter/material.dart';
import 'package:sesh/widgets/sideBar.dart';
import 'package:sesh/screens/chatScreen.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

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
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                    padding: const EdgeInsets.all(16.0),
                    alignment: Alignment.centerLeft,
                    color: Colors.white),
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
                          child: const Center(
                            child: Text(
                              'Select a person to chat with',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black54,
                              ),
                            ),
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
                    '© Veronika Kalejová 2025',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
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
