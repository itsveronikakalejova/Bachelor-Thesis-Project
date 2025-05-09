import 'package:flutter/material.dart';
import 'package:sesh/screens/login.dart';
import 'package:sesh/screens/projects.dart';
import 'package:sesh/screens/tasks.dart';
// import 'package:sesh/screens/chats.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/projects': (context) => const ProjectsPage(),
        '/tasks': (context) => const TasksPage(),
        // '/chats': (context) => const ChatsPage(),
      },
    );
  }
}