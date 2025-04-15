import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sesh/widgets/colors.dart';
import 'package:sesh/widgets/sideBar.dart';
import 'package:sesh/widgets/globals.dart' as globals;
import 'package:intl/intl.dart';

class Task {
  final String name;
  final String tag;
  final int? projectId;
  final String deadline;  
  final String status;

  Task({
    required this.name,
    required this.tag,
    required this.projectId,
    required this.deadline,  
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      name: json['task_name'],
      tag: json['description'], 
      projectId: json['project_id'],
      deadline: json['deadline'],
      status: json['status'],
    );
  }
}


class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Task> toDoTasks = [];
  List<Task> doingTasks = [];
  List<Task> doneTasks = [];

  bool _isLoading = true; 
  List<String> users = [];
  String selectedPerson = "";

  bool isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }


  Future<void> fetchTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('http://localhost:3000/tasks/my-tasks/?userName=${globals.username}'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('Fetched data: $data');

        setState(() {
          toDoTasks = data
              .where((task) => task['status'] == 'todo')
              .map((task) => Task.fromJson(task))
              .toList();
          doingTasks = data
              .where((task) => task['status'] == 'doing')
              .map((task) => Task.fromJson(task))
              .toList();
          doneTasks = data
              .where((task) => task['status'] == 'done')
              .map((task) => Task.fromJson(task))
              .toList();
          
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print(error);
    }
  }

  Future<int?> fetchProjectIdByName(String projectName) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/tasks/project-id/?project_name=$projectName'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['project_id']; 
      } else {
        print('Error: Unable to fetch project id');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<String> fetchProjectName(int? projectId) async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/projects/${projectId}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['name']; 
    } else {
      return ''; 
    }
  }

  Future<void> deleteTask(Task task, String column) async {
    bool delete = await _showDeleteTaskDialog(task, column);

    if (delete == true) {
      try {
        final response = await http.delete(
          Uri.parse('http://localhost:3000/tasks/delete-task'),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'taskName': task.name, 
          }),
        );

        if (response.statusCode == 200) {
          setState(() {
            if (column == 'To Do') {
              toDoTasks.remove(task);
            } else if (column == 'Doing') {
              doingTasks.remove(task);
            } else if (column == 'Done') {
              doneTasks.remove(task);
            }
          });
          print('Task deleted successfully');
        } else {
          print('Failed to delete task: ${json.decode(response.body)['error']}');
        }
      } catch (error) {
        print('Error deleting task: $error');
      }
    }
  }


  Future<void> moveTask(Task task, String fromColumn, String toColumn) async {
    setState(() {
      if (fromColumn == 'To Do') {
        toDoTasks.remove(task);
      } else if (fromColumn == 'Doing') {
        doingTasks.remove(task);
      } else if (fromColumn == 'Done') {
        doneTasks.remove(task);
      }

      if (toColumn == 'To Do') {
        toDoTasks.add(task);
      } else if (toColumn == 'Doing') {
        doingTasks.add(task);
      } else if (toColumn == 'Done') {
        doneTasks.add(task);
      }
    });

    String dbStatus = '';
    if (toColumn == 'To Do') {
      dbStatus = 'todo';
    } else if (toColumn == 'Doing') {
      dbStatus = 'doing';
    } else if (toColumn == 'Done') {
      dbStatus = 'done';
    }

    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/tasks/update-status'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'taskName': task.name, 
          'newStatus': dbStatus,  
        }),
      );

      if (response.statusCode == 200) {
        print('Task status updated successfully');
      } else {
        print('Failed to update task status: ${json.decode(response.body)['error']}');
      }
    } catch (error) {
      print('Error updating task status: $error');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
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
        title: const Text('Tasks'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() {
              isDrawerOpen = !isDrawerOpen;
            });
            if (isDrawerOpen) {
              _scaffoldKey.currentState?.openDrawer();
            } else {
              _scaffoldKey.currentState?.closeDrawer();
            }
          },
        ),
      ),
      body: _isLoading  
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16.0),
                        Expanded(
                          child: Row(
                            children: [
                              _buildTaskColumn('To Do', toDoTasks),
                              _buildTaskColumn('Doing', doingTasks),
                              _buildTaskColumn('Done', doneTasks),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: _showAddTaskDialog,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 20.0),
                          ),
                          child: const Text('Add New Task'),
                        ),
                      ],
                    ),
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
    );
  }


  Widget _buildTaskColumn(String columnTitle, List<Task> tasks) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              columnTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView(
                children: tasks.isEmpty
                    ? [Text('No tasks!')] 
                    : tasks.map((task) {
                        return _buildTaskCard(task, columnTitle);
                      }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, String column) {
    return Card(
      color: const Color.fromARGB(255, 214, 243, 243),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: SizedBox(
        height: 200.0,
        child: ListTile(
          title: Text(
            task.name,
            style: const TextStyle(fontSize: 30, color: Colors.black),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<String>(
                future: fetchProjectName(task.projectId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Loading project...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    );
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == '') {
                    return const Text(
                      'Project not found',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    );
                  } else {
                    return Text(
                      '(${snapshot.data})',
                      style: const TextStyle(fontSize: 16, color: myBlack),
                    );
                  }
                },
              ),
              Text(
                task.tag, 
                style: const TextStyle(fontSize: 20, color: Colors.grey),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (column == 'To Do')
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.orangeAccent),
                  onPressed: () {
                    moveTask(task, column, 'Doing');
                  },
                ),
              if (column == 'Doing')
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.orangeAccent),
                      onPressed: () {
                        moveTask(task, column, 'To Do');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.orangeAccent),
                      onPressed: () {
                        moveTask(task, column, 'Done');
                      },
                    ),
                  ],
                ),
              if (column == 'Done')
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.orangeAccent),
                  onPressed: () {
                    moveTask(task, column, 'Doing');
                  },
                ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  editTaskDialog(task); 
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  deleteTask(task, column);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  void editTaskDialog(Task task) async {
    TextEditingController taskNameController = TextEditingController(text: task.name);
    TextEditingController taskTagController = TextEditingController(text: task.tag);
    TextEditingController deadlineController = TextEditingController(
    text: task.deadline != null
        ? DateTime.tryParse(task.deadline)?.toLocal().toString().split(' ')[0] ?? ''
        : '',
  );


    // Získanie názvu projektu podľa ID
    String initialProjectName = await fetchProjectName(task.projectId);
    String? selectedProject = initialProjectName;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: taskNameController,
                    decoration: const InputDecoration(labelText: 'Task Name'),
                  ),
                  TextField(
                    controller: taskTagController,
                    decoration: const InputDecoration(labelText: 'Tag (Description)'),
                  ),
                  TextField(
                    controller: deadlineController,
                    decoration: const InputDecoration(labelText: 'Deadline (yyyy-mm-dd)'),
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<String>>(
                    future: fetchProjectList(globals.username),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError || !snapshot.hasData) {
                        return const Text('Error loading projects');
                      } else {
                        return DropdownButtonFormField<String>(
                          value: selectedProject,
                          decoration: const InputDecoration(labelText: 'Select Project'),
                          items: snapshot.data!.map((projectName) {
                            return DropdownMenuItem<String>(
                              value: projectName,
                              child: Text(projectName),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedProject = newValue;
                            });
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (taskNameController.text.isEmpty ||
                      taskTagController.text.isEmpty ||
                      deadlineController.text.isEmpty ||
                      selectedProject == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please complete all fields.')),
                    );
                    return;
                  }
                  final response = await http.put(
                    Uri.parse('http://localhost:3000/tasks/update-task-in-tasks'),
                    headers: <String, String>{'Content-Type': 'application/json'},
                    body: json.encode({
                      'originalName': task.name,
                      'updatedName': taskNameController.text,
                      'description': taskTagController.text,
                      'deadline': deadlineController.text,
                      'project_name': selectedProject,
                    }),
                  );

                  if (response.statusCode == 200) {
                    Navigator.of(context).pop();
                    fetchTasks();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task updated successfully!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to update task: ${json.decode(response.body)['error']}'),
                    ));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }



  Future<List<String>> fetchProjectList(String username) async {
    final response = await http.get(Uri.parse('http://localhost:3000/project/list-my-projects?username=$username'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<String> projectList = data.map((project) => project['name'] as String).toList();
      return projectList;
    } else {
      throw Exception('Failed to load projects');
    }
  }

  Future<bool> _showDeleteTaskDialog(Task task, String column) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the task: ${task.name}?'),
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

  void _showAddTaskDialog() async {
    TextEditingController taskNameController = TextEditingController();
    TextEditingController taskDescriptionController = TextEditingController();
    TextEditingController taskDeadlineController = TextEditingController();
    TextEditingController taskProjectController = TextEditingController();
    String assignedTo = globals.username; 
    String status = 'todo';  

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskNameController,
                  decoration: const InputDecoration(
                    labelText: 'Task Name',
                  ),
                ),
                TextField(
                  controller: taskDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                ),
                TextField(
                  controller: taskProjectController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                  ),
                ),
                TextField(
                  controller: taskDeadlineController,
                  decoration: const InputDecoration(
                    labelText: 'Deadline (e.g., 2024-04-30)',
                  ),
                  keyboardType: TextInputType.datetime,
                ),
              ],
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
              onPressed: () async {
                String deadline = taskDeadlineController.text;
                try {
                  DateTime parsedDeadline = DateFormat('yyyy-MM-dd').parse(deadline);
                  String formattedDeadline = DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedDeadline);

                  int? projectId = await fetchProjectIdByName(taskProjectController.text);

                  if (projectId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Project not found. Please check the project name.')),
                    );
                    return;
                  }

                  final response = await http.post(
                    Uri.parse('http://localhost:3000/tasks/add-task'),
                    headers: <String, String>{
                      'Content-Type': 'application/json',
                    },
                    body: json.encode({
                      'task_name': taskNameController.text,
                      'description': taskDescriptionController.text,
                      'status': status,  
                      'project_name': taskProjectController.text,  
                      'userName': assignedTo,  
                      'deadline': formattedDeadline
                    }),
                  );

                  if (response.statusCode == 201) {
                    setState(() {
                      toDoTasks.add(Task(
                        name: taskNameController.text,
                        status: status,
                        tag: taskDescriptionController.text,
                        projectId: projectId, 
                        deadline: formattedDeadline,  
                      ));
                    });
                    Navigator.of(context).pop(); 
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to add task: ${json.decode(response.body)['error']}'),
                    ));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid deadline format! Please use YYYY-MM-DD.')),
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
