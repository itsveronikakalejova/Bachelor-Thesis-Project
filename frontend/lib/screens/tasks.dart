import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sesh/widgets/sideBar.dart';
import 'package:sesh/widgets/globals.dart' as globals;

GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class Task {
  String name;
  String tag;
  String status;

  Task({required this.name, required this.tag, required this.status});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      name: json['task_name'],
      tag: json['description'],
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
  List<Task> toDoTasks = [];
  List<Task> doingTasks = [];
  List<Task> doneTasks = [];

  bool _isLoading = true; // Add a loading state
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
      _isLoading = true; // Set loading to true while fetching
    });

    try {
      final response = await http.get(Uri.parse('http://localhost:3000/tasks/my-tasks/?userName=${globals.username}'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('Fetched data: $data'); // Log the data to check its structure
        setState(() {
          toDoTasks = data.where((task) => task['status'] == 'todo').map((task) => Task.fromJson(task)).toList();
          doingTasks = data.where((task) => task['status'] == 'doing').map((task) => Task.fromJson(task)).toList(); 
          doneTasks = data.where((task) => task['status'] == 'done').map((task) => Task.fromJson(task)).toList();
          _isLoading = false; // Set loading to false once data is fetched
        });
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (error) {
      setState(() {
        _isLoading = false; // Set loading to false in case of an error
      });
      print(error);
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
            'taskName': task.name,  // Odoslanie názvu úlohy na odstránenie
          }),
        );

        if (response.statusCode == 200) {
          // Úspešne odstránené z databázy, aktualizujeme UI
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
      // Remove the task from the current column
      if (fromColumn == 'To Do') {
        toDoTasks.remove(task);
      } else if (fromColumn == 'Doing') {
        doingTasks.remove(task);
      } else if (fromColumn == 'Done') {
        doneTasks.remove(task);
      }

      // Add the task to the new column
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

    // Send a PUT request to update the task status in the database
    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/tasks/update-status'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'taskName': task.name,  // Send the task name
          'newStatus': dbStatus,  // Send the new status (toColumn)
        }),
      );

      if (response.statusCode == 200) {
        // Success
        print('Task status updated successfully');
      } else {
        // Handle error
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
      body: _isLoading  // Show the loading indicator when the tasks are being fetched
          ? Center(child: CircularProgressIndicator())  // Show loading indicator
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
                    '© Veronika Kalejová 2024',
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
                    ? [Text('No tasks available')] // Display a message when no tasks are available
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
        height: 150.0, 
        child: ListTile(
          title: Text(
            task.name,
            style: const TextStyle(fontSize: 30, color: Colors.black),
          ),
          subtitle: Text(
            task.tag,
            style: const TextStyle(fontSize: 20, color: Colors.grey),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (column == 'To Do')
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                  onPressed: () {
                    moveTask(task, column, 'Doing');
                  },
                ),
              if (column == 'Doing')
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.blue),
                      onPressed: () {
                        moveTask(task, column, 'To Do');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                      onPressed: () {
                        moveTask(task, column, 'Done');
                      },
                    ),
                  ],
                ),
              if (column == 'Done')
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.blue),
                  onPressed: () {
                    moveTask(task, column, 'Doing');
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

  void _showAddTaskDialog() {
  TextEditingController taskNameController = TextEditingController();
  TextEditingController taskDescriptionController = TextEditingController();
  TextEditingController taskDeadlineController = TextEditingController();
  TextEditingController taskProjectController = TextEditingController();  // New controller for project name
  String assignedTo = globals.username;  // Assuming 'globals.username' holds the username of the logged-in user.
  String status = 'todo';  // Default status to 'To Do'

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
              // Add the task to the backend (server)
              final response = await http.post(
                Uri.parse('http://localhost:3000/tasks/add-task'),
                headers: <String, String>{
                  'Content-Type': 'application/json',
                },
                body: json.encode({
                  'task_name': taskNameController.text,
                  'description': taskDescriptionController.text,
                  'status': status,  // Default status 'todo'
                  'project_name': taskProjectController.text,  // Project name from input field
                  'userName': assignedTo,  // Sending logged-in user's username
                }),
              );

              if (response.statusCode == 201) {
                // If the task was successfully added, update the UI
                setState(() {
                  toDoTasks.add(Task(
                    name: taskNameController.text,
                    tag: taskProjectController.text,  // Using project name as the 'tag'
                    status: status,
                  ));
                });
                Navigator.of(context).pop();  // Close the dialog
              } else {
                // If something went wrong, show an error message
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Failed to add task: ${json.decode(response.body)['error']}'),
                ));
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
