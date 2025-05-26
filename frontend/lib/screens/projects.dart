import 'package:flutter/material.dart';
import 'package:sesh/widgets/colors.dart';
import 'package:sesh/widgets/sideBar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sesh/screens/project.dart';
import 'package:sesh/widgets/globals.dart' as globals;
import 'package:sesh/widgets/project_model.dart';
import 'package:sesh/widgets/shareDialog.dart';


class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

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
      Uri.parse('http://localhost:3000/projects?username=${globals.username}'),
      headers: {
        'Authorization': 'Bearer ${globals.token}',
      },
    );

    if (response.statusCode == 200) {
      // ziskaj projekty z odpovede a preved ich na zoznam fetchedProjects
      List<Project> fetchedProjects = (json.decode(response.body) as List)
          .map((data) => Project.fromJson(data))
          .toList();

      // vymaz duplicitne projekty
      setState(() {
        projects = [];
        for (var project in fetchedProjects) {
          bool exists = projects.any((existingProject) =>
              existingProject.id == project.id || existingProject.name == project.name);
          if (!exists) {
            projects.add(project);
          }
        }
        isLoading = false;
      });

      // zisti, kto je vlastnik projektu
      // a nastav isOwner pre kazdy projekt
      // isOwner bude true, ak je vlastnik projektu aktualny uzivatel
      for (var project in projects) {
        fetchProjectOwner(project);
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchProjectOwner(Project project) async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/projects/owner/${project.name}'), 
      headers: {
        'Authorization': 'Bearer ${globals.token}',
      },
    );

    if (response.statusCode == 200) {
      final ownerData = json.decode(response.body);
      final ownerName = ownerData['ownerName'];
      // nastav isOwner pre projekt na true, ak je vlastnik aktualny uzivatel
      setState(() {
        project.isOwner = ownerName == globals.username;
      });
    } 
  }


  // pridaj do databazy novy projekt s menom name a
  // s autorom username a
  // pridaj ho do zoznamu projects
  Future<void> addProject(String name) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/projects'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${globals.token}',
      },
      body: json.encode({
        'name': name,
        'username': globals.username,
      }),
    );

    if (response.statusCode == 201) {
      final newProject = Project.fromJson(json.decode(response.body));
      newProject.isOwner = true;

      setState(() {
        projects.add(newProject);
      });
    }

  }

  // zmaz projekt s id project.id z databazy a zoznamu projects
  Future<void> deleteProject(Project project) async {
    final shouldDelete = await showDeleteProjectDialog(project.name);
    if (shouldDelete) {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/projects/${project.id}'),
        headers: {
          'Authorization': 'Bearer ${globals.token}',
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

  // zobrazi dialog s potvrdenim zmazania projektu
  Future<bool> showDeleteProjectDialog(String projectName) async {
    // premenna, ktora nadobuda hodnotu true, ak uzivatel potvrdi zmazanie projektu
    // inak nadobuda hodnotu false a
    // ak uzivatel z dialogu odide, tiez nadobuda hodnotu false
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
                              // pre kazdy projekt vytvor widget s jeho informaciami
                              return buildProjectTile(context, project);
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
                      // vytvor tlacidlo pre pridanie noveho projektu
                      // pri kliknuti na tlacidlo sa zobrazi dialog 
                      // pre pridanie noveho projektu
                      ElevatedButton(
                        onPressed: showAddProjectDialog,
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
                // spodna cast obrazovky, paticka
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
    );
  }

  Widget buildProjectTile(BuildContext context, Project project) {
    // nastav farbu projektu na zelenú, ak je vlastník projektu aktuálny užívateľ
    // inak nastav farbu na sivú
    Color projectColor = project.isOwner ? myGreen : Colors.grey[300]!;

    return Card(
      color: projectColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.black),
        title: Text(
          project.name,
          style: const TextStyle(fontSize: 18, color: Colors.black),
        ),
        trailing: PopupMenuButton<String>(
          // vytvor popup menu pre moznosti projektu
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onSelected: (String value) {
            if (value == 'delete') {
              // vymaze projekt z databazy a zoznamu projektov
              deleteProject(project);
            } else if (value == 'share') {
              // zobrazi dialog pre zdieľanie projektu
              showShareDialog(context, project.name);
            } else if (value == 'edit') {
              // zobrazi dialog pre editovanie mena projektu
              editProjectName(context, project.name);
            }
          },
          // vytvor moznosti v popup menu
          // moznosti su: edit, share, delete
          // pri kliknuti na moznost sa vykona prislusna akcia vyssie
          itemBuilder: (BuildContext context) => const [
            PopupMenuItem<String>(
              value: 'edit',
              child: Text('Edit Name'),
            ),
            PopupMenuItem<String>(
              value: 'share',
              child: Text('Share Project'),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text('Delete Project'),
            ),
          ],
        ),
        // pri kliknuti na projekt sa prejde na stranku projektu
        // teda vyvojove prostredie projektu, subor project.dart
        // a preda sa mu token, userId, username a projectId
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectPage(
                token: globals.token,
                userId: globals.userId,
                username: globals.username,
                projectId: project.id,
              ),
            ),
          );
        },
      ),
    );
  }

  void editProjectName(BuildContext context, String currentName) {
    final TextEditingController _controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Project Name'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'New Project Name'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              // pri kliknuti na tlacidlo sa ulozi nove meno projektu a
              // aktualizuje sa v databaze
              // iba ak je nove meno ine ako aktualne meno
              child: const Text('Save'),
              onPressed: () async {
                final newName = _controller.text.trim();
                if (newName.isNotEmpty && newName != currentName) {
                  final response = await http.put(
                    Uri.parse('http://localhost:3000/projects/update-name/$currentName'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'newName': newName}),
                  );

                  if (response.statusCode == 200) {
                    // aktualizuj meno projektu v zozname projektov
                    Navigator.of(context).pop();
                    fetchProjects();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Project name updated successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update project name')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }


  void showAddProjectDialog() {
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
                  // pridaj projekt s menom projectName do databazy a do zoznamu projektov
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