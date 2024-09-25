import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class EditTaskDialog extends StatefulWidget {
  final String initialTaskName;
  final DateTime initialDate;
  final TimeOfDay initialTime;
  final Function(String, DateTime, TimeOfDay) onSave;

  EditTaskDialog({
    required this.initialTaskName,
    required this.initialDate,
    required this.initialTime,
    required this.onSave,
  });

  @override
  _EditTaskDialogState createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final TextEditingController taskController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    taskController.text = widget.initialTaskName;
    selectedDate = widget.initialDate;
    selectedTime = widget.initialTime;
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: selectedDate!,
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime!,
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void showMessage(String message) {
    if (Platform.isWindows) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: taskController,
            decoration: const InputDecoration(labelText: 'Task Name'),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () => selectDate(context),
                child: Text(selectedDate == null
                    ? "Select Date"
                    : DateFormat.yMd().format(selectedDate!)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => selectTime(context),
                child: Text(selectedTime == null
                    ? "Select Time"
                    : selectedTime!.format(context)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            final updatedDate = selectedDate;
            final updatedTime = selectedTime;

            if (updatedDate == null || updatedTime == null) {
              showMessage('Please select a date and time!');
              return;
            }
            widget.onSave(taskController.text, updatedDate, updatedTime);
            Navigator.of(context).pop(); // Close the dialog
            showMessage('Task edited successfully!');
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
