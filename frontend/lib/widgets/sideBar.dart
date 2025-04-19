import 'package:flutter/material.dart';
import 'package:sesh/widgets/colors.dart';
import 'package:sesh/widgets/globals.dart' as globals;

class SideBar extends StatelessWidget {
  final void Function()? onProjectsTap;
  final void Function()? onChatsTap;
  final void Function()? onTasksTap;

  const SideBar({
    super.key,
    this.onProjectsTap,
    this.onChatsTap,
    this.onTasksTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: myBlack,
      child: Column(
        children: [
          const SizedBox(height: 16.0),
          Image.asset(
            'assets/logo.png',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 8.0),
          Text(
            globals.username.isNotEmpty ? 'Hello, ${globals.username}!' : 'Welcome!',
            style: const TextStyle(
              color: myWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: myWhite,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                leading: const Icon(Icons.folder_open_rounded, color: myBlack),
                title: const Text(
                  'Projects',
                  style: TextStyle(color: myBlack),
                ),
                onTap: () {
                  Navigator.pushNamed(context, '/projects');
                },
              ),
            ),
          ),

          // CHATS
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          //   child: Container(
          //     decoration: BoxDecoration(
          //       color: myWhite,
          //       borderRadius: BorderRadius.circular(12.0),
          //     ),
          //     child: ListTile(
          //       leading: const Icon(Icons.task_alt_sharp, color: myBlack),
          //       title: const Text(
          //         'Chats',
          //         style: TextStyle(color: myBlack),
          //       ),
          //       onTap: () {
          //         Navigator.pushNamed(context, '/chats');
          //       },
          //     ),
          //   ),
          // ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: myWhite,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                leading: const Icon(Icons.task_alt_sharp, color: myBlack),
                title: const Text(
                  'Tasks',
                  style: TextStyle(color: myBlack),
                ),
                onTap: () {
                  Navigator.pushNamed(context, '/tasks');
                },
              ),
            ),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

