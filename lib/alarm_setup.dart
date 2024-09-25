import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AlarmSoundPicker extends StatefulWidget {
  final Function(String) onSoundSelected;

  AlarmSoundPicker({required this.onSoundSelected});

  @override
  _AlarmSoundPickerState createState() => _AlarmSoundPickerState();
}

class _AlarmSoundPickerState extends State<AlarmSoundPicker> {
  String? _selectedSoundPath;

  Future<void> _pickAudio() async {
    String? filePath = await FilePicker.platform
        .pickFiles(
          type: FileType.audio,
        )
        .then((result) => result?.files.single.path);

    if (filePath != null) {
      setState(() {
        _selectedSoundPath = filePath;
      });
      widget.onSoundSelected(filePath);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Alarm Sound")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_selectedSoundPath ?? 'No sound selected'),
            ElevatedButton(
              onPressed: _pickAudio,
              child: Text("Pick Alarm Sound"),
            ),
          ],
        ),
      ),
    );
  }
}
