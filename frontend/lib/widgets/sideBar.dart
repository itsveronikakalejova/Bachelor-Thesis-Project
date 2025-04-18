import 'package:flutter/material.dart';
import 'package:sesh/widgets/colors.dart';

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
      backgroundColor: myGreen,
      child: Column(
        children: [
          const SizedBox(height: 16.0),
          Image.asset(
            'assets/logo.png',
            width: 100,
            height: 100,
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
                leading: const Icon(Icons.folder, color: myBlack),
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

          // ListTile(
          //   leading: const Icon(Icons.chat, color: Colors.white),
          //   title: const Text(
          //     'Chats',
          //     style: TextStyle(color: Colors.white),
          //   ),
          //   onTap: () {
          //     Navigator.pushNamed(context, '/chats');
          //   },
          // ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: myWhite,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                leading: const Icon(Icons.task, color: myBlack),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
