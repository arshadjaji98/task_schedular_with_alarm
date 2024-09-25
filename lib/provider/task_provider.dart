import 'package:flutter/material.dart';

class TaskProvider with ChangeNotifier {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _taskName;

  DateTime? get selectedDate => _selectedDate;
  TimeOfDay? get selectedTime => _selectedTime;
  String? get taskName => _taskName;

  // Modify to accept null for resetting
  void selectDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Modify to accept null for resetting
  void selectTime(TimeOfDay? time) {
    _selectedTime = time;
    notifyListeners();
  }

  void setTaskName(String task) {
    _taskName = task;
    notifyListeners();
  }
}
