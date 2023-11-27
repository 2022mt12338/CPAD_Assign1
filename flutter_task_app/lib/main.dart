import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'task.dart';
import 'edit_task_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final keyApplicationId = 'AbwwVYEPktAQHRx4k7dc8EJLaQu6z8cfMiFFy6v3';
  final keyClientKey = 'DTKRQWwdWnOgX01aZROSJEX2iQVFaVSwDKA4MkhE'; // Optional
  final keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl, 
    clientKey: keyClientKey, 
    autoSendSessionId: true,
    debug: true // Turn off before deploying the app  
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Task App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TaskListScreen(),
    );
  }
}

Future<List<Task>> fetchTasks() async {
  final response = await ParseObject('Task').getAll();

  if (response.success && response.results != null) {
    return response.results!.map((e) => Task.fromParse(e)).toList();
  } else {
    // Handle the error
    throw Exception('Failed to load tasks');
  }
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  void loadTasks() async {
    try {
      final response = await ParseObject('Task').getAll();
      if (response.success && response.results != null) {
        setState(() {
          tasks = response.results?.map((e) => Task.fromParse(e)).toList() ?? [];
        });
      } else {
        showErrorDialog('Failed to load tasks');
      }
    } catch (e) {
      showErrorDialog('An error occurred while loading tasks');
    }
  }

  void deleteTask(String objectId) async {
    final taskToDelete = ParseObject('Task')
      ..set('objectId', objectId);
    var response = await taskToDelete.delete();

    if (response.success) {
      loadTasks(); // Refresh the task list
    } else {
      showErrorDialog('Failed to delete the task. Please try again.');
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks'),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            title: Text(task.title),
            subtitle: Text(task.description),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(task: task),
                ),
              );
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditTaskScreen(task: task),
                      ),
                    ).then((value) {
                      if (value == true) {
                        loadTasks();
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Task'),
                        content: Text('Are you sure you want to delete this task?'),
                        actions: [
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: Text('Delete'),
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                              deleteTask(task.objectId); // Call the delete method
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => NewTaskScreen()),
        ).then((_) => loadTasks()),
        child: Icon(Icons.add),
      ),
    );
  }
}

class NewTaskScreen extends StatefulWidget {
  @override
  _NewTaskScreenState createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Task'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            ElevatedButton(
              onPressed: () => createTask(_titleController.text, _descController.text),
              child: Text('Save Task'),
            ),
          ],
        ),
      ),
    );
  }

  void createTask(String title, String description) async {
    // Check for empty fields
    if (title.isEmpty || description.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('All fields are required.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    final task = ParseObject('Task')
      ..set('Title', title)
      ..set('Description', description);
    final response = await task.save();

    if (response.success) {
      Navigator.pop(context); // Return to the previous screen if the save is successful
    } else {
      final errorMessage = response.error?.message ?? 'Unknown error';
      // If the task creation failed, show an error message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to save the task. Error: $errorMessage'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

}



class TaskDetailScreen extends StatelessWidget {
  final Task task;

  TaskDetailScreen({required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Title: ${task.title}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Description: ${task.description}', style: TextStyle(fontSize: 18)),
            // You can add more details here
          ],
        ),
      ),
    );
  }
}