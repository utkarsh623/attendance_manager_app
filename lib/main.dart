import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(PersonalAttendanceApp());
}


class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[800],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in, size: 80, color: Colors.white),
            SizedBox(height: 30),
            Text(
              "Manage your attendance",
              style: TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


class PersonalAttendanceApp extends StatefulWidget {
  @override
  State<PersonalAttendanceApp> createState() => _PersonalAttendanceAppState();
}

class _PersonalAttendanceAppState extends State<PersonalAttendanceApp> {
  bool _darkMode = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Attendance',
      theme: ThemeData(primarySwatch: Colors.blue),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.blue[800]!,
          secondary: Colors.blue,
        ),
        appBarTheme: AppBarTheme(backgroundColor: Colors.blue[900]),
      ),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: _showSplash
          ? SplashScreen()
          : SubjectListScreen(
        darkMode: _darkMode,
        setDarkMode: (v) => setState(() => _darkMode = v),
      ),
    );
  }
}


class AttendanceEntry {
  final DateTime dateTime;
  final bool present;
  final String note;
  AttendanceEntry({required this.dateTime, required this.present, this.note = ""});
}

class Subject {
  final String name;
  List<AttendanceEntry> attendanceHistory = [];
  Subject(this.name);
}


class SubjectListScreen extends StatefulWidget {
  final bool darkMode;
  final void Function(bool)? setDarkMode;
  SubjectListScreen({required this.darkMode, this.setDarkMode});
  @override
  _SubjectListScreenState createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  List<Subject> subjects = [];

  void _showAddSubjectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Subject'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter subject name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel')
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty && !subjects.any((s) => s.name == name)) {
                setState(() {
                  subjects.add(Subject(name));
                });
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRemoveSubjectDialog(Subject subject) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete \"${subject.name}\"?"),
        content: Text("Are you sure you want to delete this subject and all its attendance history?"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                subjects.remove(subject);
              });
              Navigator.pop(context);
            },
            child: Text("Delete"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _openAttendance(Subject subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubjectAttendanceScreen(subject: subject),
      ),
    ).then((_) => setState(() {}));
  }

  double _calcPercentage(Subject s) {
    if (s.attendanceHistory.isEmpty) return 0;
    final present = s.attendanceHistory.where((e) => e.present).length;
    return present / s.attendanceHistory.length * 100;
  }

  double _calcOverallPercentage() {
    int total = 0;
    int present = 0;
    for (final subj in subjects) {
      total += subj.attendanceHistory.length;
      present += subj.attendanceHistory.where((e) => e.present).length;
    }
    if (total == 0) return 0;
    return present / total * 100;
  }

  @override
  Widget build(BuildContext context) {
    final overallPct = _calcOverallPercentage();
    return Scaffold(
      appBar: AppBar(
        title: Text('Subjects'),
        actions: [
          IconButton(
            tooltip: widget.darkMode ? "Light mode" : "Dark mode",
            icon: Icon(widget.darkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: () => widget.setDarkMode?.call(!widget.darkMode),
          ),
        ],
      ),
      body: Column(
        children: [
          // Overall Attendance Summary
          Container(
            width: double.infinity,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.blueGrey[900] : Colors.blue[50],
            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "📊 Overall Attendance: ${overallPct.toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontSize: 18,
                    color: overallPct >= 75 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subjects.isNotEmpty)
                  Text(
                    "(${subjects.length} subject${subjects.length > 1 ? "s" : ""})",
                    style: TextStyle(
                      fontSize: 13, color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: subjects.isEmpty
                ? Center(
              child: Text(
                "No subjects!\nTap + to add.",
                textAlign: TextAlign.center,
              ),
            )
                : ListView.separated(
              itemCount: subjects.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (_, i) {
                final s = subjects[i];
                final pct = _calcPercentage(s);
                return ListTile(
                  title: Text(s.name),
                  subtitle: Text('Attendance: ${s.attendanceHistory.length} records | ${pct.toStringAsFixed(1)}%'),
                  leading: Icon(Icons.book, color: Colors.blue),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red,),
                        tooltip: "Delete subject",
                        onPressed: () => _showRemoveSubjectDialog(s),
                      ),
                      Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                  onTap: () => _openAttendance(s),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.grey[100],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubjectDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Subject',
      ),
    );
  }
}


class SubjectAttendanceScreen extends StatefulWidget {
  final Subject subject;
  SubjectAttendanceScreen({required this.subject});

  @override
  _SubjectAttendanceScreenState createState() => _SubjectAttendanceScreenState();
}

class _SubjectAttendanceScreenState extends State<SubjectAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

  List<AttendanceEntry> get _entriesForDay {
    final list = widget.subject.attendanceHistory
        .where((e) =>
    e.dateTime.year == _selectedDate.year &&
        e.dateTime.month == _selectedDate.month &&
        e.dateTime.day == _selectedDate.day)
        .toList();
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  double _calcPercentage() {
    if (widget.subject.attendanceHistory.isEmpty) return 0;
    final present = widget.subject.attendanceHistory.where((e) => e.present).length;
    return present / widget.subject.attendanceHistory.length * 100;
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() { _selectedDate = picked; });
  }

  void _addAttendance(bool present) {
    TextEditingController noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(present ? "Mark Present" : "Mark Absent"),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(hintText: "Optional note (e.g. Lab, Test, etc.)"),
        ),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.subject.attendanceHistory.add(
                    AttendanceEntry(
                      dateTime: DateTime.now(),
                      present: present,
                      note: noteController.text.trim(),
                    )
                );
              });
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay t) => t.format(context);

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final pct = _calcPercentage();
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject.name} Attendance'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            tooltip: "Pick a date",
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.blueGrey[900]
                : Colors.blueGrey.shade50,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 Date: ${_formatDate(_selectedDate)}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 6),
                Text('🕒 Time: ${_formatTime(now)}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 6),
                Text(
                  '📊 Attendance: ${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    color: pct >= 75 ? Colors.green : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Add new attendance for this date:',
                  style: TextStyle(fontSize: 17),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.check, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: Size(110, 44),
                      ),
                      onPressed: () => _addAttendance(true),
                      label: Text('Present'),
                    ),
                    SizedBox(width: 18),
                    ElevatedButton.icon(
                      icon: Icon(Icons.close, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: Size(110, 44),
                      ),
                      onPressed: () => _addAttendance(false),
                      label: Text('Absent'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            child: Text('History for ${_formatDate(_selectedDate)}:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _entriesForDay.isEmpty
                ? Center(child: Text('No attendance records for this date.'))
                : ListView.builder(
              itemCount: _entriesForDay.length,
              itemBuilder: (_, idx) {
                final entry = _entriesForDay[idx];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      entry.present ? Icons.check_circle : Icons.cancel,
                      color: entry.present ? Colors.green : Colors.red,
                    ),
                    title: Text('${entry.present ? "Present" : "Absent"}${entry.note.isNotEmpty ? " (${entry.note})": ""}'),
                    subtitle: Text('${entry.dateTime.hour.toString().padLeft(2,'0')}:${entry.dateTime.minute.toString().padLeft(2,'0')}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
