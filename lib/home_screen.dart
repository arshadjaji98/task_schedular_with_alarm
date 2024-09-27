import 'package:alarm_desktop_app/alarm_setup.dart';
import 'package:alarm_desktop_app/components/dialog.dart';
import 'package:alarm_desktop_app/provider/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'components/toast_message.dart';
import 'package:audioplayers/audioplayers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> tasks = [];
  final TextEditingController taskController = TextEditingController();
  String selectedSound = 'default_sound.mp3';

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  void deleteAllTasks() {
    setState(() {
      tasks.clear();
      saveTasks();
    });
    ToastHelper.showToast('All tasks deleted successfully!');
  }

  Future<void> loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      List<dynamic> decodedTasks = json.decode(tasksJson);
      setState(() {
        for (var task in decodedTasks) {
          tasks.add({
            'name': task['name'],
            'date': DateTime.parse(task['date']),
            'time': TimeOfDay(
              hour: task['time']['hour'],
              minute: task['time']['minute'],
            ),
            'sound': task['sound'] ?? selectedSound,
          });
        }
      });
    }
  }

  Future<void> saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String tasksJson = json.encode(tasks.map((task) {
      return {
        'name': task['name'],
        'date': task['date'].toIso8601String(),
        'time': {
          'hour': task['time'].hour,
          'minute': task['time'].minute,
        },
        'sound': task['sound'],
      };
    }).toList());
    await prefs.setString('tasks', tasksJson);
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (picked != null) {
      Provider.of<TaskProvider>(context, listen: false).selectDate(picked);
    }
  }

  Future<void> selectTime(BuildContext context) async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      Provider.of<TaskProvider>(context, listen: false).selectTime(picked);
    }
  }

  void addTask(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    if (taskProvider.selectedDate == null ||
        taskProvider.selectedTime == null) {
      ToastHelper.showToast('Please select date and time!');
      return;
    }

    if (taskProvider.taskName!.isNotEmpty) {
      tasks.add({
        'name': taskProvider.taskName,
        'date': taskProvider.selectedDate,
        'time': taskProvider.selectedTime,
        'sound': selectedSound,
      });
      scheduleAlarm(taskProvider.selectedDate!, taskProvider.selectedTime!);

      saveTasks();

      taskController.clear();
      taskProvider.setTaskName('');
      taskProvider.selectDate(null);
      taskProvider.selectTime(null);

      ToastHelper.showToast('Task added successfully!');
      setState(() {});
    }
  }

  void scheduleAlarm(DateTime date, TimeOfDay time) async {
    final int alarmId = tasks.length;
    final DateTime alarmDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    print('Scheduling alarm for: $alarmDateTime');

    await AndroidAlarmManager.oneShotAt(
      alarmDateTime,
      alarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true, // Optional: for showing in alarm clock app
      rescheduleOnReboot: true, // Optional: reschedule alarms on reboot
    );
  }

  // Changed to instance method
  void alarmCallback() async {
    print('Alarm callback triggered!');

    try {
      AudioPlayer audioPlayer = AudioPlayer();
      await audioPlayer.setSource(
          AssetSource('assets/$selectedSound')); // Use the selected sound
      await audioPlayer.resume(); // or play(), depending on your version
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void editTask(BuildContext context, int index) {
    final task = tasks[index];
    showDialog(
      context: context,
      builder: (context) {
        return EditTaskDialog(
          initialTaskName: task['name'],
          initialDate: task['date'],
          initialTime: task['time'],
          onSave: (newTaskName, newDate, newTime) {
            setState(() {
              tasks[index] = {
                'name': newTaskName,
                'date': newDate,
                'time': newTime,
                'sound': task['sound'],
              };
            });
            saveTasks();
            ToastHelper.showToast('Task updated successfully!');
          },
        );
      },
    );
  }

  void _selectSound(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Alarm Sound'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Default Sound'),
                onTap: () {
                  setState(() {
                    selectedSound = 'default_sound.mp3'; // Default sound
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('Custom Sound 1'),
                onTap: () {
                  setState(() {
                    selectedSound = 'custom_sound_1.mp3'; // A predefined sound
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('Pick from File Manager'),
                onTap: () async {
                  // Open the AlarmSoundPicker and wait for the sound to be selected
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AlarmSoundPicker(
                        onSoundSelected: (soundPath) {
                          setState(() {
                            selectedSound =
                                soundPath; // Store selected sound path
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Schedule Task",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.music_note),
            onPressed: () =>
                _selectSound(context), // Allow user to select sound
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateTimeSelector(context, taskProvider),
          const SizedBox(height: 15),
          _buildTaskInputField(taskProvider),
          const SizedBox(height: 12),
          _buildAddTaskButton(context),
          const SizedBox(height: 20),
          _buildTaskList(context),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector(
      BuildContext context, TaskProvider taskProvider) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.white)]),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  taskProvider.selectedDate == null
                      ? "Select a Date"
                      : '${DateFormat.yMd().format(taskProvider.selectedDate!)}',
                  style: const TextStyle(fontSize: 18),
                ),
                ElevatedButton(
                  onPressed: () => selectDate(context),
                  child: const Text("Select Date"),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  taskProvider.selectedTime == null
                      ? "Select a Time"
                      : '${taskProvider.selectedTime!.hour}:${taskProvider.selectedTime!.minute}',
                  style: const TextStyle(fontSize: 18),
                ),
                ElevatedButton(
                  onPressed: () => selectTime(context),
                  child: Text("Select Time"),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskInputField(TaskProvider taskProvider) {
    return Card(
      child: TextField(
        controller: taskController,
        onChanged: (value) {
          taskProvider.setTaskName(value);
        },
        decoration: InputDecoration(
          labelText: "Enter Task Name",
          border: OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              taskController.clear();
              taskProvider.setTaskName('');
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAddTaskButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => addTask(context),
      child: const Text("Add a Task"),
      style: ElevatedButton.styleFrom(),
    );
  }

  Widget _buildTaskList(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            child: ListTile(
              title: Text(task['name']),
              subtitle: Text(
                  'Date: ${DateFormat.yMd().format(task['date'])} - Time: ${task['time'].hour}:${task['time'].minute}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => editTask(context, index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        tasks.removeAt(index);
                        saveTasks();
                      });
                      ToastHelper.showToast('Task deleted successfully!');
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
