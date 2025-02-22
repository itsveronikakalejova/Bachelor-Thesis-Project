import 'package:flutter/material.dart';
import 'package:sesh/widgets/colors.dart';
import 'package:sesh/widgets/sideBar.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  _ProjectsPageState createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final List<String> projects = [
    'IPC Project',
    'Copymaster',
    'Cuberoll',
    'Pipes',
    'Programovanie',
    'Šachy',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myWhite,
      drawer: SideBar(
        onProjectsTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/projects');
        },
        onChatsTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/chats');
        },
        onTasksTap: () {
          Navigator.pop(context);
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
      body: Column(
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
                      children: projects.map((projectName) {
                        return _buildProjectTile(projectName);
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
Widget _buildProjectTile(String projectName) {
  return Card(
    color: const Color.fromARGB(255, 214, 243, 243),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    child: ListTile(
      leading: const Icon(Icons.description, color: Colors.black),
      title: Text(
        projectName,
        style: const TextStyle(fontSize: 18, color: Colors.black),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.black),
        onSelected: (String value) {
          if (value == 'delete') {
            deleteProject(projectName);
          } else if (value == 'share') {
            _showShareDialog(context, projectName);
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
        if (projectName == 'IPC Project') {
          Navigator.pushNamed(context, '/project');
        }
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
                setState(() {
                  projects.add(projectNameController.text);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
  
   void _showShareDialog(BuildContext context, String projectName) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$projectName shared'),
    ));

   showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedPrivilege = 'Can View';
        String selectedPerson = 'Majo';

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Share Project'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add People:'),
                  DropdownButton<String>(
                    value: selectedPerson,
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedPerson = newValue!;
                      });
                    },
                    items: <String>['Majo', 'Peto', 'Jano']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Privileges:'),
                  DropdownButton<String>(
                    value: selectedPrivilege,
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedPrivilege = newValue!;
                      });
                    },
                    items: <String>['Can Edit', 'Can View']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Project shared with $selectedPerson as $selectedPrivilege')),
                          );
                          Navigator.of(context).pop();
                        },
                        child: const Text('Share'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  Future<void> deleteProject(String projectName) async {
    bool delete = await _showDeleteProjectDialog(projectName);
    
    if (delete == true) {
      setState(() {
        projects.remove(projectName);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$projectName deleted'),
    ));
    }
  }
}
