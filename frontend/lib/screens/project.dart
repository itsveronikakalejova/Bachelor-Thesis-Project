import 'package:flutter/material.dart';
import 'package:sesh/screens/groupChat.dart';
import 'package:sesh/widgets/colors.dart';
import 'package:sesh/widgets/sideBar.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sesh/widgets/shareDialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProjectPage extends StatefulWidget {
  final String token;
  final int userId;
  final String username;
  final int projectId;

  const ProjectPage({super.key, required this.token, required this.userId, required this.username, required this.projectId});

  @override
  _ProjectPageState createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  late IO.Socket socket;
  int? activeFileId;
  final TextEditingController _contentController = TextEditingController();
  List<Map<String, dynamic>> tasks = []; 
  bool isLoading = false;
  List<Map<String, dynamic>> projectFiles = [];
  String currentFileName = 'untitled.txt';
  String currentFileType = 'Document'; 

  @override
  void initState() {
    super.initState();
    // inicializacia socketu 
    socket = IO.io("http://localhost:3000", <String, dynamic>{
      // pouzivame websocket transport
      "transports": ["websocket"],
      // nepouzivame automaticke pripojenie
      "autoConnect": false,
    });
    // pripojime sa na socket
    socket.connect();
    _fetchProjectFiles();
    _fetchTasks(); 
  }

  // sluzi na prepojenie pouzivatelov, 
  // ktori pracuju na rovnakom subore
  void connectToSocketForFile(int fileId) {
    // ak je uz nejaky subor otvoreny, zavrieme ho
    if (activeFileId != null) {
      // POSIELANIE (frontend -> server)
      socket.emit('close-file', activeFileId);
    }
    // nastavime aktivny subor
    activeFileId = fileId;
    // POSIELANIE (frontend -> server)
    // pripojenie k novemu aktivnemu suboru
    socket.emit('open-file', fileId);

    // nastavime listener na zmenu suboru
    // PRIJIMANIE (server -> frontend)
    socket.on('file-changed', (data) {
      if (mounted && data['fileId'] == activeFileId) {
        setState(() {
          _contentController.text = data['content'];
        });
      }
    });
  }

  Future<void> _fetchFileContent(int fileId, String fileName) async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/project/${widget.projectId}/files/$fileId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _contentController.text = data['fileData'];
        currentFileName = fileName;
        fetchFileType(fileName).then((type) {
          setState(() {
            currentFileType = type;
          });
        });
      });
      connectToSocketForFile(fileId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch file content')),
      );
    }
  }

  // aktualizuje subor
  void sendTextUpdate(String text) {
    if (activeFileId != null) {
      socket.emit('file-update', {
        'fileId': activeFileId,
        'content': text
      });
    }
  }

  Future<void> _fetchProjectFiles() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/project/${widget.projectId}/files'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        projectFiles = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch project files')),
      );
    }
  }


  void checkForErrors() async {
    final String code = _contentController.text;
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code is empty')),
      );
      return;
    }

    const String apiUrl = "http://127.0.0.1:3000/compile/submit-code";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "code": code,
        }),
      );

      final responseData = jsonDecode(response.body);
      String message;

      if (response.statusCode == 200) {
        message = "Compilation of $currentFileName was successful.\n";
      } else {
        message = responseData.containsKey('error')
            ? "Compilation of $currentFileName failed:\n${responseData['error']}"
            : "Unknown error while compiling $currentFileName.";
      }

      _showOutputDialog(context, message);
    } catch (error) {
      _showOutputDialog(context, 'Error while sending request for $currentFileName:\n$error');
    }
  }

  void _showOutputDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Compilation Output'),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}



  Future<String> _fetchProjectName() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/project/${widget.projectId}'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Project Data: $data");  
      return data['name']; 
    } else {
      return ''; 
    }
  }

  Future<void> _fetchTasks() async {
    String projectName = await _fetchProjectName();
    
    if (projectName.isEmpty) {
      print("Project name is empty. Cannot fetch tasks.");
      return;
    }

    final url = Uri.parse('http://localhost:3000/tasks/tasks-by-project?projectName=$projectName');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        if (!mounted) return; 

        setState(() {
          tasks = data.map((task) => {
            'id': task['id'],
            'task_name': task['task_name'],
            'description': task['description'],
            'status': task['status'],
            'deadline': task['deadline'],
            'assigned_to': task['assigned_to']
          }).toList();
        });
      } else {
        print('Failed to load tasks: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching tasks: $error');
    }
  }

  Future<String> fetchFileType(String fileName) async {
    if (currentFileName.isEmpty) {
      throw Exception('No file selected');
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/project/${widget.projectId}/file-type/$currentFileName'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['fileType'];
      } else {
        throw Exception('Failed to fetch file type: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching file type: $e');
      return 'unknown';
    }
  }
 

  Future<void> updateTaskStatus(String taskName, bool isDone) async {
    String newStatus = isDone ? 'done' : 'todo'; 

    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/tasks/update-status'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'taskName': taskName,  
          'newStatus': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        print('Task status updated successfully');

        setState(() {
          for (var task in tasks) {
            if (task['task_name'] == taskName) {
              task['status'] = newStatus;
            }
          }
        });
      } else {
        print('Failed to update task status: ${json.decode(response.body)['error']}');
      }
    } catch (error) {
      print('Error updating task status: $error');
    }
  }



  Future<void> saveTextInput() async {
    final text = _contentController.text;

    final response = await http.post(
      Uri.parse('http://localhost:3000/project/${widget.projectId}/saveText'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'text': text,
        'uploadedBy': widget.userId.toString(), 
        'fileName': currentFileName,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text input saved successfully')),
      );
      _fetchProjectFiles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save text input')),
      );
    }
  }


  Future<void> addFileToDatabase(String fileName, String filetype) async {
    final text = _contentController.text;

    final response = await http.post(
      Uri.parse('http://localhost:3000/project/${widget.projectId}/files'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'fileName': fileName,
        'fileType': filetype,
        'fileData': text,
        'uploadedBy': widget.userId.toString(), 
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File added successfully')),
      );
      _fetchProjectFiles(); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add file')),
      );
    }
  }

  void showAddFileDialog() {
    final TextEditingController fileNameController = TextEditingController();
    bool isCCode = true; 

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add File'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: fileNameController,
                    decoration: const InputDecoration(
                      labelText: 'File Name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isCCode ? 'C Code' : 'Document'),
                      Switch(
                        value: isCCode,
                        onChanged: (bool value) {
                          setState(() {
                            isCCode = value;
                          });
                        },
                      ),
                    ],
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
                    final fileName = fileNameController.text;
                    if (fileName.isNotEmpty) {
                      addFileToDatabase(fileName, isCCode ? 'C_code' : 'document');
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('File name cannot be empty')),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    if (activeFileId != null) {
      socket.emit('close-file', activeFileId);
    }
    _contentController.dispose();
    if (socket.connected) {
      socket.disconnect();
      socket.dispose();
    }
    super.dispose();
  }

  void cleanupAndNavigate(String route) {
    if (socket.connected) {
      socket.disconnect();
      socket.dispose();
    }
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.pushNamed(context, route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 34, 34, 34),
      drawer: SideBar(
        onProjectsTap: () => cleanupAndNavigate('/projects'),
        // onChatsTap: () => cleanupAndNavigate('/chats'),
        onTasksTap: () => cleanupAndNavigate('/tasks'),
      ),


      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        title: FutureBuilder<String>(
        future: _fetchProjectName(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();  
          } else if (snapshot.hasError) {
            return const Text("Error loading project");
          } else if (snapshot.hasData) {
            return Text(
              snapshot.data!, 
              style: const TextStyle(color: Colors.black),
            );
          } else {
            return const Text("No Project Name");
          }
        },
      ),
        actions: [
          TextButton(
            onPressed: () {
              if (socket.connected) {
                socket.disconnect();
                socket.dispose();
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Go back ↩',
              style: TextStyle(color: Colors.black),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            color: const Color.fromARGB(255, 214, 243, 243),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: myGreen,  // Background color
                        borderRadius: BorderRadius.circular(30.0),  // Rounded corners
                      ),
                      child: TextButton(
                        onPressed: showAddFileDialog,
                        child: const Text(
                          'Add File',
                          style: TextStyle(color: myBlack),  // White text color
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),  // Space between buttons
                    Container(
                      decoration: BoxDecoration(
                        color: myGreen,  // Background color
                        borderRadius: BorderRadius.circular(30.0),  // Rounded corners
                      ),
                      child: TextButton(
                        onPressed: saveTextInput,
                        child: const Text(
                          'Save File',
                          style: TextStyle(color: myBlack),  // White text color
                        ),
                      ),
                    ),
                  ],
                ),
               Row(
                children: [
                  if (currentFileType == 'C_code') // Only show button for C code files
                    Container(
                      decoration: BoxDecoration(
                        color: myGreen,
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: TextButton(
                        onPressed: () {
                          checkForErrors();
                        },
                        child: const Text(
                          'Check for Errors',
                          style: TextStyle(color: myBlack),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: myGreen,  // Background color
                        borderRadius: BorderRadius.circular(30.0),  // Rounded corners
                      ),
                      child: TextButton(
                        onPressed: () async {
                          String projectName = await _fetchProjectName();
                          showShareDialog(context, projectName);
                        },
                        child: const Text(
                          'Share',
                          style: TextStyle(color: myBlack),  // White text color
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: myGreen,  // Background color
                        borderRadius: BorderRadius.circular(30.0),  // Rounded corners
                      ),
                      child: TextButton(
                        onPressed: () async {
                          String projectName = await _fetchProjectName();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupChat(projectName: projectName, projectId: widget.projectId),
                            ),
                          );
                        },
                        child: const Text(
                          'Open Group Chat',
                          style: TextStyle(color: myBlack),  // White text color
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 300,
                  color: const Color.fromARGB(255, 184, 233, 224),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16.0),
                      ...projectFiles.map((file) => _buildProjectTile(context, file)).toList(),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    color: const Color.fromARGB(255, 55, 63, 59),
                    padding: const EdgeInsets.all(16.0),
                    alignment: Alignment.topLeft,
                    child: Column(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _contentController,
                            maxLines: null,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Courier New',
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Type your code here...',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            onChanged: sendTextUpdate,
                            textAlignVertical: TextAlignVertical.top,
                            keyboardType: TextInputType.multiline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _buildTaskPanel(),
                ),
              ],
            ),
          ),
          Container(
            color: const Color.fromARGB(255, 34, 34, 34),
            padding: const EdgeInsets.all(8.0),
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

  Widget _buildTaskPanel() {
    return Container(
      color: myGreen,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Tasks",
            style: TextStyle(fontSize: 20, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tasks.isEmpty
                ? const Center(
                    child: Text("No tasks!", style: TextStyle(color: Colors.black)),
                  )
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      bool isDone = tasks[index]['status'] == 'done';

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Checkbox(
                            value: isDone,
                            onChanged: (bool? newValue) {
                              if (newValue != null) {
                                updateTaskStatus(tasks[index]['task_name'], newValue);
                              }
                            },
                          ),
                          title: GestureDetector(
                            onTap: () {
                              showTaskDetailsDialog(tasks[index]);
                            },
                            child: Text(
                              tasks[index]['task_name'],
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          subtitle: GestureDetector(
                            onTap: () {
                              showTaskDetailsDialog(tasks[index]);
                            },
                            child: Text(
                              tasks[index]['assigned_to'],
                              style: const TextStyle(color: Color.fromARGB(255, 19, 102, 76)),
                            ),
                          ),
                          trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  editTaskDialog(tasks[index]);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  deleteTask(tasks[index]);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add Task", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: _showAddTaskDialog,
          ),
        ],
      ),
    );
  }

  void editTaskDialog(Map<String, dynamic> task) async {
    TextEditingController nameController = TextEditingController(text: task['task_name']);
    TextEditingController descriptionController = TextEditingController(text: task['description']);
    TextEditingController deadlineController = TextEditingController(
      text: task['deadline'] != null && task['deadline'].toString().isNotEmpty
          ? task['deadline'].toString().substring(0, 10)
          : '',
    );
    String? selectedUser = task['assigned_to'];

    List<String> privilegedUsers = await fetchPrivilegedUsers();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Task"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Task Name"),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                TextField(
                  controller: deadlineController,
                  decoration: const InputDecoration(labelText: "Deadline (YYYY-MM-DD)"),
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedUser,
                  decoration: const InputDecoration(labelText: 'Assign To'),
                  items: privilegedUsers.map((username) {
                    return DropdownMenuItem<String>(
                      value: username,
                      child: Text(username),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    selectedUser = newValue;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String updatedName = nameController.text.trim();
                String description = descriptionController.text.trim();
                String deadline = deadlineController.text.trim();
                String? assignedTo = selectedUser;

                if (updatedName.isEmpty || description.isEmpty || deadline.isEmpty || assignedTo == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill in all fields.")),
                  );
                  return;
                }

                final response = await http.put(
                  Uri.parse('http://localhost:3000/tasks/update-task-in-project'),
                  headers: <String, String>{
                    'Content-Type': 'application/json',
                  },
                  body: json.encode({
                    'originalName': task['task_name'],
                    'updatedName': updatedName,
                    'description': description,
                    'deadline': "$deadline 00:00:00",
                    'assigned_to': assignedTo,
                  }),
                );

                if (response.statusCode == 200) {
                  _fetchTasks(); // reload tasks after update
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update task: ${json.decode(response.body)['error']}")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }




  Future<void> deleteTask(Map<String, dynamic> taskData) async {
  bool confirm = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the task "${taskData['task_name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/tasks/delete-task'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'taskName': taskData['task_name'],
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          tasks.remove(taskData); // Odstráni task z listu
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: ${json.decode(response.body)['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error occurred while deleting task.')),
      );
    }
  }
}


  Widget _buildProjectTile(BuildContext context, Map<String, dynamic> file) {
    return Card(
      color: const Color.fromARGB(255, 214, 243, 243),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.black),
        title: Text(
          file['file_name'],
          style: const TextStyle(fontSize: 18, color: Colors.black),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.drive_file_rename_outline_sharp, color: Colors.blue),
              onPressed: () {
                editFileName(context, file['id']);
                _fetchFileContent(file['id'], file['file_name']);
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                deleteFile(file['id']);
              },
            ),
          ],
        ),
        onTap: () {
          _fetchFileContent(file['id'], file['file_name']);
        },
      ),
    );
  }


  void editFileName(BuildContext context, int fileId) {
    final TextEditingController _nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit File Name'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Enter new file name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = _nameController.text.trim();

                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File name cannot be empty')),
                  );
                  return;
                }

                try {
                  final response = await http.put(
                    Uri.parse('http://localhost:3000/project/update-file/$fileId'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'newName': newName}),
                  );

                  if (response.statusCode == 200) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File name updated successfully')),
                    );
                    // Voliteľné: obnov zoznam
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${response.body}')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Network error: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }


  Future<void> deleteFile(int fileId) async {
    final url = Uri.parse('http://localhost:3000/project/delete-file/$fileId');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted successfully')),
        );
        _fetchProjectFiles(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete file: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting file: $e')),
      );
    }
  }


  void showTaskDetailsDialog(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(task['task_name']),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailText("Description", task['description'] ?? 'No description'),
              const SizedBox(height: 8),
              _buildDetailText("Status", task['status']),
              const SizedBox(height: 8),
              _buildDetailText("Deadline", task['deadline'] ?? 'No deadline'),
              const SizedBox(height: 8),
              _buildDetailText("Assigned to", task['assigned_to'] ?? 'Unassigned'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailText(String label, String value) {
    if (label == "Deadline" && value != 'No deadline') {
      try {
        DateTime date = DateTime.parse(value);
        value = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: Colors.black),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: value,
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() async {
    TextEditingController taskNameController = TextEditingController();
    TextEditingController taskDescriptionController = TextEditingController();
    TextEditingController taskDeadlineController = TextEditingController();
    String status = 'todo';
    String? selectedUser;

    List<String> privilegedUsers = await fetchPrivilegedUsers();

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
                  controller: taskDeadlineController,
                  decoration: const InputDecoration(
                    labelText: 'Deadline (YYYY-MM-DD)',
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity, 
                  child: DropdownButtonFormField<String>(
                    value: selectedUser,
                    decoration: const InputDecoration(
                      labelText: 'Assign To',
                    ),
                    items: privilegedUsers.map((username) {
                      return DropdownMenuItem<String>(
                        value: username,
                        child: Text(username),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedUser = newValue;
                      });
                    },
                  ),
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
                String projectName = await _fetchProjectName();
                if (projectName.isEmpty || selectedUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please complete all fields.')),
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
                    'project_name': projectName,
                    'userName': selectedUser, 
                    'deadline': taskDeadlineController.text,
                  }),
                );

                if (response.statusCode == 201) {
                  _fetchTasks();
                  Navigator.of(context).pop();
                } else {
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

  
  Future<List<String>> fetchPrivilegedUsers() async {
    String projectName = await _fetchProjectName();

    if (projectName.isEmpty) {
      throw Exception('Project name not found');
    }

    final response = await http.get(
      Uri.parse('http://localhost:3000/project-users/users-with-access?project_name=$projectName'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<String>((user) => user['username'].toString()).toList();
    } else {
      throw Exception('Failed to fetch privileged users: ${response.body}');
    }
  }
}