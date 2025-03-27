import 'package:flutter/material.dart';
import 'package:sesh/screens/register.dart';
import 'package:sesh/screens/projects.dart';
import 'package:sesh/widgets/colors.dart';
import 'package:sesh/screens/authService.dart';
import 'package:sesh/widgets/globals.dart' as globals;


class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myBlack,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: myBlack,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: myWhite,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.grey),
            ],
          ),
          child: SizedBox(
            width: 400,
            height: 550,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome to',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/logo.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () async {
                      final username = usernameController.text;
                      final password = passwordController.text;

                      if (username.isNotEmpty && password.isNotEmpty) {
                        final response = await authService.login(username, password);
                        if (response != null && response.containsKey('token') && response.containsKey('userId')) {
                          globals.token = response['token'];  // Uloženie tokenu
                          globals.userId = response['userId'];  // Uloženie userId
                          globals.username = response['username'];  // Uloženie mena

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Logged in as ${globals.username}')),
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectsPage(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invalid credentials')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill in all fields')),
                        );
                      }
                    },

                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 16.0),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Haven't registered yet? Create an account.",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}