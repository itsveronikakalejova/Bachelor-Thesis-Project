import 'package:flutter/material.dart';
import 'package:sesh/widgets/colors.dart';
import 'package:sesh/widgets/sideBar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sesh/screens/project.dart';

class ProjectsPage extends StatefulWidget {
  final String token;
  final int userId;
  final String username;

  const ProjectsPage({super.key, required this.token, required this.userId, required this.username});

  @override
  _ProjectsPageState createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  List<Project> projects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/projects?username=${widget.username}'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        projects = (json.decode(response.body) as List)
            .map((data) => Project.fromJson(data))
            .toList();
        isLoading = false;
      });
    } else {
      // Handle error
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addProject(String name) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/projects'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode({
        'name': name,
        'username': widget.username,
      }),
    );

    if (response.statusCode == 201) {
      final newProject = Project.fromJson(json.decode(response.body));
      setState(() {
        projects.add(newProject);
      });
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add project')),
      );
    }
  }

  Future<void> deleteProject(Project project) async {
    final shouldDelete = await _showDeleteProjectDialog(project.name);
    if (shouldDelete) {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/projects/${project.id}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          projects.remove(project);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete project')),
        );
      }
    }
  }

  Future<bool> _showDeleteProjectDialog(String projectName) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the project: $projectName?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return shouldDelete ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myWhite,
      drawer: SideBar(
        onProjectsTap: () {
          Navigator.pushNamed(context, '/projects');
        },
        onChatsTap: () {
          Navigator.pushNamed(context, '/chats');
        },
        onTasksTap: () {
          Navigator.pushNamed(context, '/tasks');
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Projects',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16.0),
                        Expanded(
                          child: ListView(
                            children: projects.map((project) {
                              return _buildProjectTile(context, project);
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: _showAddProjectDialog,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 12.0),
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          'Add New Project',
                          style: TextStyle(fontSize: 14),
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

  Widget _buildProjectTile(BuildContext context, Project project) {
    return Card(
      color: const Color.fromARGB(255, 214, 243, 243),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.black),
        title: Text(
          project.name,
          style: const TextStyle(fontSize: 18, color: Colors.black),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onSelected: (String value) {
            if (value == 'delete') {
              deleteProject(project);
            } else if (value == 'share') {
              // _showShareDialog(context, project);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'delete',
              child: Text('Delete Project'),
            ),
            const PopupMenuItem<String>(
              value: 'share',
              child: Text('Share Project'),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectPage(
                token: widget.token,
                userId: widget.userId,
                username: widget.username,
                projectId: project.id,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddProjectDialog() {
    TextEditingController projectNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Project'),
          content: TextField(
            controller: projectNameController,
            decoration: const InputDecoration(
              labelText: 'Project Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final projectName = projectNameController.text;
                if (projectName.isNotEmpty) {
                  addProject(projectName);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a project name')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class Project {
  final int id;
  final String name;

  Project({required this.id, required this.name});

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
    );
  }
}