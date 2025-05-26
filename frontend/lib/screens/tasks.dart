import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sesh/widgets/colors.dart';
import 'package:sesh/widgets/sideBar.dart';
import 'package:sesh/widgets/globals.dart' as globals;
import 'package:intl/intl.dart';

// trieda Task, ktorá reprezentuje úlohu
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

  // factory metóda na vytvorenie inštancie Task z JSON objektu
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
  // kluc pre Scaffold, ktory umoznuje otvorenie a zatvorenie bocneho menu
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // zoznamy pre rozne stavy uloh
  List<Task> toDoTasks = [];
  List<Task> doingTasks = [];
  List<Task> doneTasks = [];
  bool _isLoading = true; 
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
        // dekodovanie JSON odpovede
        List<dynamic> data = json.decode(response.body);
        // filtrovanie uloh podla statusu a vytvorenie instancii Task
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
    }
  }

  // metoda na ziskanie ID projektu podla mena
  // pouziva sa na priradenie ulohy k projektu v databaze
  Future<int?> fetchProjectIdByName(String projectName) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/tasks/project-id/?project_name=$projectName'),
      );

      if (response.statusCode == 200) {
        // dekodovanie JSON odpovede
        final data = json.decode(response.body);
        return data['project_id']; 
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // metoda na ziskanie mena projektu podla ID
  // pouziva sa na zobrazenie mena projektu v detaile ulohy
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

  // metoda na zmazanie ulohy
  Future<void> deleteTask(Task task, String column) async {
    // zobrazenie dialogu na potvrdenie zmazania
    bool delete = await showDeleteTaskDialog(task, column);

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

        // ak je odpoved uspesna, odstrani ulohu z prislusneho zoznamu
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
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting task: $error'),
          ),
        );
      }
    }
  }

  // metoda na presun ulohy medzi stlpce
  // parametre su ulohy, z ktoreho stlpca a do ktoreho stlpca sa ma uloha presunut
  // aktualizuje sa aj status ulohy v databaze
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

    // aktualizacia statusu ulohy v databaze
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task status updated successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task status: ${json.decode(response.body)['error']}'),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating task status: $error'),
        ),
      );
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
          ? const Center(child: CircularProgressIndicator())
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
                              // vytvorenie stlpcov pre ulohy podla ich statusu
                              buildTaskColumn('To Do', toDoTasks),
                              buildTaskColumn('Doing', doingTasks),
                              buildTaskColumn('Done', doneTasks),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        // tlacidlo na pridanie novej ulohy
                        ElevatedButton(
                          onPressed: showAddTaskDialog,
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

  // metoda na vytvorenie stlpca s ulohami
  // zobrazuje nazov stlpca a zoznam uloh
  // parametre su nazov stlpca a zoznam uloh
  Widget buildTaskColumn(String columnTitle, List<Task> tasks) {
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
                // ak je zoznam uloh prazdny, zobrazi sa prazdna sprava
                // inak sa zobrazia karty s ulohami
                children: tasks.isEmpty
                    ? [] 
                    : tasks.map((task) {
                        // vytvorenie karty pre kazdu ulohu
                        return buildTaskCard(task, columnTitle);
                      }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // metoda na vytvorenie karty pre ulohu
  Widget buildTaskCard(Task task, String column) {
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
              // zobrazenie projektu, ku ktoremu je uloha priradena
              FutureBuilder<String>(
                // ziskanie mena projektu podla ID projektu
                // pouziva sa FutureBuilder na asynchronne ziskanie dat
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
              // zobrazenie popisu ulohy (tag)
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
                // tlacidlo na presun ulohy z To Do do Doing  
                // smer doprava
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.orangeAccent),
                  onPressed: () {
                    moveTask(task, column, 'Doing');
                  },
                ),
              // tlacidlo na presun ulohy z Doing do Done/To Do
              // smer do lava a doprava
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
              // tlacidlo na presun ulohy z Done do Doing
              // smer do lava
              if (column == 'Done')
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.orangeAccent),
                  onPressed: () {
                    moveTask(task, column, 'Doing');
                  },
                ),
              // tlacidlo na editaciu a zmazanie ulohy
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  editTaskDialog(task); 
                },
              ),
              // tlacidlo na zmazanie ulohy
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
    // ziskanie datumu deadline v lokalnom case
    // ak je deadline null, pouzije sa prazdny retazec
    // rozdeli datum na datum a cas a zobrazi iba datum
    // ignore: unnecessary_null_comparison
    text: task.deadline != null
        ? DateTime.tryParse(task.deadline)?.toLocal().toString().split(' ')[0] ?? ''
        : '',
  );

    // ziskanie mena projektu podla ID projektu
    String initialProjectName = await fetchProjectName(task.projectId);
    // premenna pre vybrany projekt, predvolene je to meno projektu ulohy
    String? selectedProject = initialProjectName;

    showDialog(
      // ignore: use_build_context_synchronously
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
                    // ziskanie zoznamu projektov pre dropdown menu
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
                // tlacidlo na ulozenie zmien
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
                  // posielanie aktualizovanych dat na server
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


  // metoda na ziskanie zoznamu projektov pre dropdown menu
  // pouziva sa na zobrazenie projektov pri editacii ulohy
  // viaze sa na prave prihlaseneho uzivatela
  Future<List<String>> fetchProjectList(String username) async {
    final response = await http.get(Uri.parse('http://localhost:3000/project-list/list-my-projects?username=$username'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<String> projectList = data.map((project) => project['name'] as String).toList();
      return projectList;
    } else {
      throw Exception('Failed to load projects');
    }
  }

  // metoda na zobrazenie dialogu na potvrdenie zmazania ulohy
  Future<bool> showDeleteTaskDialog(Task task, String column) async {
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

  // metoda na zobrazenie dialogu pre pridanie novej ulohy
  void showAddTaskDialog() async {
    TextEditingController taskNameController = TextEditingController();
    TextEditingController taskDescriptionController = TextEditingController();
    TextEditingController taskDeadlineController = TextEditingController();
    TextEditingController taskProjectController = TextEditingController();
    // priradenie prave prihlaseneho uzivatela ako 'assignedTo'
    String assignedTo = globals.username; 
    // predvolene status ulohy je 'todo'
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
            // tlacidlo na pridanie ulohy
            TextButton(
              onPressed: () async {
                String deadline = taskDeadlineController.text;
                try {
                  DateTime parsedDeadline = DateFormat('yyyy-MM-dd').parse(deadline);
                  String formattedDeadline = DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedDeadline);

                  // ziskanie ID projektu podla mena
                  int? projectId = await fetchProjectIdByName(taskProjectController.text);

                  if (projectId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Project not found. Please check the project name.')),
                    );
                    return;
                  }
                  // posielanie dat na server pre pridanie novej ulohy
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
                  // ak je odpoved uspesna, pridame novu ulohu do zoznamu
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
