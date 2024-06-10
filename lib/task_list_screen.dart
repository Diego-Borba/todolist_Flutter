import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> tasks = [];
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('auth_token');
    });
    print('Token de autenticação carregado: $_authToken');
    if (_authToken != null) {
      await _fetchTasks();
    } else {
      _showSnackBar(
          'Token de autenticação não encontrado. Faça login novamente.');
      _navigateToLogin();
    }
  }

  Future<void> _fetchTasks() async {
    if (_authToken == null) {
      _showSnackBar('Token de autenticação ausente.');
      _navigateToLogin();
      return;
    }

    final url = Uri.parse('http://10.0.2.2:8080/todo');
    final headers = {
      'Authorization': 'Bearer $_authToken',
    };

    try {
      final response =
          await http.get(url, headers: headers).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          tasks = data.map((taskData) => Task.fromJson(taskData)).toList();
        });
      } else {
        print('Error response: ${response.body}');
        _showSnackBar('Erro ao carregar tarefas: ${response.statusCode}');
        if (response.statusCode == 401 || response.statusCode == 403) {
          _navigateToLogin();
        }
      }
    } catch (e) {
      _showSnackBar('Erro de conexão: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginScreen(),
      ),
    );
  }

  Future<void> _createTask(String name, String description, DateTime? startDate,
      DateTime? endDate) async {
    final url = Uri.parse('http://10.0.2.2:8080/todo');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_authToken',
    };
    final body = jsonEncode({
      'name': name,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    });

    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(Duration(seconds: 10));

      if (mounted) {
        if (response.statusCode == 201 || response.statusCode == 200) {
          _showSnackBar('Tarefa criada com sucesso!');
          _fetchTasks(); // Recarrega as tarefas após a criação bem-sucedida
        } else {
          print('Error response: ${response.body}');
          _showSnackBar('Erro ao criar tarefa: ${response.statusCode}');
        }
      }
    } catch (e) {
      _showSnackBar('Erro de conexão: $e');
    }
  }

  Future<void> _updateTask(String id, String name, String description,
      DateTime? startDate, DateTime? endDate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      _navigateToLogin();
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8080/todo'), // URL correta
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id': id, // Inclui o ID no corpo da requisição
          'name': name,
          'description': description,
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Tarefa atualizada com sucesso.');
        _fetchTasks();
      } else if (response.statusCode == 403) {
        _showSnackBar('Permissão negada. Faça login novamente.');
        _navigateToLogin();
      } else if (response.statusCode == 401) {
        _showSnackBar('Sessão expirada. Faça login novamente.');
        _navigateToLogin();
      } else {
        _showSnackBar('Erro ao atualizar tarefa.');
      }
    } catch (e) {
      _showSnackBar('Erro de conexão: $e');
    }
  }

  Future<void> _deleteTask(String id) async {
    final url = Uri.parse('http://10.0.2.2:8080/todo/$id');
    final headers = {
      'Authorization': 'Bearer $_authToken',
    };

    try {
      final response = await http
          .delete(url, headers: headers)
          .timeout(Duration(seconds: 10));

      if (mounted) {
        if (response.statusCode == 204 || response.statusCode == 200) {
          _showSnackBar('Tarefa excluída com sucesso!');
          _fetchTasks(); // Recarrega as tarefas após a exclusão bem-sucedida
        } else {
          print('Error response: ${response.body}');
          _showSnackBar('Erro ao excluir tarefa: ${response.statusCode}');
          if (response.statusCode == 500) {
            _showSnackBar('Erro ao excluir tarefa: Erro interno do servidor.');
          }
        }
      }
    } catch (e) {
      _showSnackBar('Erro de conexão: $e');
    }
  }

  Future<void> _signOutGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    _navigateToLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de tarefas'),
        backgroundColor: Colors.blueAccent,
        actions: [
          TextButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('auth_token');
              await _signOutGoogle();
              _navigateToLogin();
            },
            child: const Text(
              'Sair',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: tasks.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return TaskCard(
                    task: tasks[index],
                    onEdit: () => _editTask(index),
                    onDelete: () => _confirmDelete(index),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTask(),
        icon: Icon(Icons.add),
        label: Text('Adicionar nova tarefa'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueAccent,
      ),
    );
  }

  void _addTask() async {
    final taskNameController = TextEditingController();
    final taskDescriptionController = TextEditingController();
    DateTime? selectedStartDate;
    DateTime? selectedEndDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nova Tarefa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: taskNameController,
              decoration: InputDecoration(labelText: 'Nome da Tarefa'),
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            TextField(
              controller: taskDescriptionController,
              decoration: InputDecoration(labelText: 'Descrição'),
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      selectedStartDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      setState(() {});
                    },
                    child: Text(
                      selectedStartDate != null
                          ? 'Início: ${selectedStartDate!.toLocal().toString().split(' ')[0]}'
                          : 'Selecionar data de início',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      selectedEndDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      setState(() {});
                    },
                    child: Text(
                      selectedEndDate != null
                          ? 'Fim: ${selectedEndDate!.toLocal().toString().split(' ')[0]}'
                          : 'Selecionar data de fim',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () {
              final taskName = taskNameController.text;
              final taskDescription = taskDescriptionController.text;
              if (taskName.isNotEmpty) {
                _createTask(taskName, taskDescription, selectedStartDate,
                    selectedEndDate);
              }
              Navigator.pop(context);
            },
            child: Text(
              'Salvar',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  void _editTask(int index) async {
    final task = tasks[index];
    final taskNameController = TextEditingController(text: task.name);
    final taskDescriptionController =
        TextEditingController(text: task.description);
    DateTime? selectedStartDate = task.startDate;
    DateTime? selectedEndDate = task.endDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Tarefa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: taskNameController,
              decoration: InputDecoration(labelText: 'Nome da Tarefa'),
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            TextField(
              controller: taskDescriptionController,
              decoration: InputDecoration(labelText: 'Descrição'),
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      selectedStartDate = await showDatePicker(
                        context: context,
                        initialDate: selectedStartDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      setState(() {});
                    },
                    child: Text(
                      selectedStartDate != null
                          ? 'Início: ${selectedStartDate!.toLocal().toString().split(' ')[0]}'
                          : 'Selecionar data de início',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      selectedEndDate = await showDatePicker(
                        context: context,
                        initialDate: selectedEndDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      setState(() {});
                    },
                    child: Text(
                      selectedEndDate != null
                          ? 'Fim: ${selectedEndDate!.toLocal().toString().split(' ')[0]}'
                          : 'Selecionar data de fim',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () {
              final taskName = taskNameController.text;
              final taskDescription = taskDescriptionController.text;
              if (taskName.isNotEmpty) {
                _updateTask(task.id, taskName, taskDescription,
                    selectedStartDate, selectedEndDate);
              }
              Navigator.pop(context);
            },
            child: Text(
              'Salvar',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int index) {
    final task = tasks[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Tarefa'),
        content:
            Text('Tem certeza que deseja excluir a tarefa "${task.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () {
              _deleteTask(task.id);
              Navigator.pop(context);
            },
            child: Text(
              'Excluir',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  TaskCard({
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(task.name, style: TextStyle(fontFamily: 'Poppins')),
        subtitle:
            Text(task.description, style: TextStyle(fontFamily: 'Poppins')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  final String id; // Alterado para String
  final String name;
  final String description;
  final DateTime? startDate;
  final DateTime? endDate;

  Task({
    required this.id,
    required this.name,
    required this.description,
    this.startDate,
    this.endDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'], // Agora trata o ID como String
      name: json['name'],
      description: json['description'],
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }
}
