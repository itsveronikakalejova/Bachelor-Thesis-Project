import 'package:flutter/material.dart';

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
      backgroundColor: const Color.fromARGB(255, 34, 34, 34),
      child: Column(
        children: [
          const SizedBox(height: 16.0),
          Image.asset(
            'assets/logo.png',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 16.0),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.black),
                prefixIcon: Icon(Icons.search, color: Colors.black),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          ListTile(
            leading: const Icon(Icons.folder, color: Colors.white),
            title: const Text(
              'Projects',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pushNamed(context, '/projects');
            },
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
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.white),
            title: const Text(
              'Tasks',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pushNamed(context, '/tasks');
            },
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
