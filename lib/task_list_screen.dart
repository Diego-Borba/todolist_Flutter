import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main.dart';
import 'package:google_sign_in/google_sign_in.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final List<Task> tasks = [];
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de tarefas'),
        backgroundColor: Colors.blueAccent,
        actions: [
          TextButton(
            onPressed: () async {
              await _googleSignIn.signOut();
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
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
        child: ListView.builder(
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
                setState(() {
                  tasks.add(Task(
                    name: taskName,
                    description: taskDescription,
                    startDate: selectedStartDate,
                    endDate: selectedEndDate,
                  ));
                });
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
                setState(() {
                  tasks[index] = Task(
                    name: taskName,
                    description: taskDescription,
                    startDate: selectedStartDate,
                    endDate: selectedEndDate,
                  );
                });
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

  void _confirmDelete(int index) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Tarefa'),
        content: Text(
          'Você tem certeza que deseja excluir esta tarefa?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Excluir',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        tasks.removeAt(index);
      });
    }
  }
}

class Task {
  final String name;
  final String description;
  DateTime? startDate;
  DateTime? endDate;

  Task({
    required this.name,
    required this.description,
    this.startDate,
    this.endDate,
  });
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
      margin: EdgeInsets.all(10.0),
      child: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.name,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 10.0),
            Text(
              task.description,
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            SizedBox(height: 10.0),
            Row(
              children: [
                Text(
                  'Início: ${task.startDate != null ? task.startDate!.toLocal().toString().split(' ')[0] : 'Não definido'}',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                SizedBox(width: 10.0),
                Text(
                  'Fim: ${task.endDate != null ? task.endDate!.toLocal().toString().split(' ')[0] : 'Não definido'}',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: onEdit,
                  color: Colors.blueAccent,
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: onDelete,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
