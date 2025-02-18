import 'package:flutter/material.dart';
import 'package:sesh/widgets/sideBar.dart';

GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class Task {
  String name;
  String tag;

  Task({required this.name, required this.tag});
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Task> toDoTasks = [
    Task(name: 'Sample Task 1', tag: 'IPC project'),
    Task(name: 'Sample Task 2', tag: 'Database'),
    Task(name: 'Sample Task 3', tag: 'UI design')
  ];
  List<Task> doingTasks = [Task(name: 'Sample Task 4', tag: 'Networking')];
  List<Task> doneTasks = [Task(name: 'Sample Task 5', tag: 'Backend')];

  bool isDrawerOpen = false;

  Future<void> deleteTask(Task task, String column) async {
    bool delete = await _showDeleteTaskDialog(task, column);
    
    if (delete == true) {
      setState(() {
        if (column == 'To Do') {
          toDoTasks.remove(task);
        } else if (column == 'Doing') {
          doingTasks.remove(task);
        } else if (column == 'Done') {
          doneTasks.remove(task);
        }
      });
    }
  }


  void moveTask(Task task, String fromColumn, String toColumn) {
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
  }

  void _showAddTaskDialog() {
    TextEditingController taskNameController = TextEditingController();
    TextEditingController taskTagController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskNameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                ),
              ),
              TextField(
                controller: taskTagController,
                decoration: const InputDecoration(
                  labelText: 'Project',
                ),
              ),
            ],
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
                  toDoTasks.add(Task(
                    name: taskNameController.text,
                    tag: taskTagController.text,
                  ));
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
      body: Column(
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
                children: tasks.map((task) {
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
    child: Container(
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
}