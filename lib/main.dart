import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Sign in the user anonymously
  await FirebaseAuth.instance.signInAnonymously();

  runApp(TaskApp());
}


class TaskApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task App',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: TaskHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Topic {
  String name;
  double progress;

  Topic({required this.name, this.progress = 0.0});

  bool get isCompleted => progress >= 1.0;

  // Convert a Firestore document to a Topic object
  factory Topic.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Topic(
      name: data['name'],
      progress: data['progress'] ?? 0.0,
    );
  }

  // Convert a Topic object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'progress': progress,
    };
  }
}


class Chapter {
  String id;
  String name;
  List<Topic> topics;

  Chapter({required this.id, required this.name, required this.topics});

  double get completionPercent {
    if (topics.isEmpty) return 0.0;
    double sum = topics.fold(0, (prev, t) => prev + t.progress);
    return sum / topics.length;
  }

  // Convert a Firestore document to a Chapter object
  factory Chapter.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chapter(
      id: doc.id, // Store the document ID
      name: data['name'],
      topics: List<Topic>.from(data['topics'].map((t) => Topic.fromFirestore(t))),
    );
  }

  // Convert a Chapter object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'topics': topics.map((t) => t.toMap()).toList(), // Assuming Topic has a toMap method
    };
  }
}


class Subject {
  final String id;
  final String name;
  List<Chapter> chapters;

  Subject({required this.id, required this.name, this.chapters = const []});

  // Convert a Firestore document to a Subject object
  factory Subject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subject(
      id: doc.id,
      name: data['name'],
      chapters: List<Chapter>.from(data['chapters'].map((c) => Chapter.fromFirestore(c))), // Assuming Chapter has a fromFirestore method
    );
  }

  // Convert a Subject object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'chapters': chapters.map((c) => c.toMap()).toList(), // Assuming Chapter has a toMap method
    };
  }
}


class Task {
  final String? id; // Add this line
  final String title;
  final DateTime deadline;
  bool isDone;

  Task({this.id, required this.title, required this.deadline, this.isDone = false});

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id, // Store the document ID
      title: data['title'],
      deadline: (data['deadline'] as Timestamp).toDate(),
      isDone: data['isDone'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'deadline': deadline,
      'isDone': isDone,
    };
  }
}

class TaskHomePage extends StatefulWidget {
  @override
  _TaskHomePageState createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  final List<Task> _tasks = [];
  final TextEditingController _controller = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadTasks(); // Load tasks from Firestore when the widget initializes
  }

  // Load tasks from Firestore
  Future<void> _loadTasks() async {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .get();

    setState(() {
      _tasks.clear(); // Clear existing tasks
      for (var doc in snapshot.docs) {
        _tasks.add(Task.fromFirestore(doc)); // Convert each document to a Task
      }
      _tasks.sort((a, b) => a.deadline.compareTo(b.deadline)); // Sort tasks by deadline
    });
  }

  // Add a new task
  void _addTask() {
    _controller.clear();
    _selectedDate = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.blueGrey[800],
              title: const Text(
                "Add Task",
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _controller,
                    cursorColor: Colors.orangeAccent,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Task',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade200,
                      foregroundColor: Colors.blueGrey[900],
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: Colors.orange.shade200,
                                onPrimary: Colors.black,
                                surface: Colors.blueGrey[800]!,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setStateDialog(() => _selectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text("Select Deadline"),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _selectedDate == null
                        ? "Deadline not selected"
                        : "Deadline: ${DateFormat('dd MMM yyyy').format(_selectedDate!)}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: Colors.orange[200])),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[200],
                    foregroundColor: Colors.blueGrey[900],
                  ),
                  onPressed: () {
                    if (_controller.text.isNotEmpty && _selectedDate != null) {
                      final newTask = Task(
                        title: _controller.text,
                        deadline: _selectedDate!,
                      );
                      _addTaskToFirestore(newTask); // Save task to Firestore
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Save the task to Firestore
  Future<void> _addTaskToFirestore(Task task) async {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .add(task.toMap()); // Convert Task to Map and save
    _loadTasks(); // Reload tasks after adding
  }

  // Toggle task completion status
  void _toggleDone(Task task) {
    setState(() {
      task.isDone = !task.isDone;
    });
    _updateTaskInFirestore(task); // Update task status in Firestore
  }

  // Update task in Firestore
  Future<void> _updateTaskInFirestore(Task task) async {
    if (task.id == null) return; // Ensure the task has an ID
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id) // Use the document ID
        .update({'isDone': task.isDone}); // Update the task's isDone status
  }

  // Delete a task
  void _deleteTask(Task task) {
    setState(() {
      _tasks.remove(task);
    });
    _deleteTaskFromFirestore(task); // Delete task from Firestore
  }

  // Delete task from Firestore
  Future<void> _deleteTaskFromFirestore(Task task) async {
    if (task.id == null) return; // Ensure the task has an ID
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id) // Use the document ID
        .delete(); // Delete the task document
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[700],
        title: Text('My Tasks', style: TextStyle(color: Colors.orange[100]),
        ),
        iconTheme: IconThemeData(color: Colors.orange[100]),
      ),
      drawer: Drawer(
        backgroundColor: Colors.orange[100], // 1. Set drawer background color
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueGrey[900], // 2. Set DrawerHeader background color
              ),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.orange[100], fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.track_changes),
              title: Text("Completion Mode"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SubjectPage()),
                );
              },
            ),
          ],
        ),
      ),

      body: _tasks.isEmpty
          ? const Center(child: Text("No tasks yet. Add one!"))
          : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(15),
              color: Colors.transparent, // Inside matches the background
            ),
            child: ListTile(
              leading: Theme(
                data: Theme.of(context).copyWith(
                  unselectedWidgetColor: Colors.orange[200], // Checkbox border color when unchecked
                ),
                child: Checkbox(
                  value: task.isDone,
                  onChanged: (value) => _toggleDone(task),
                  activeColor: Colors.orange[200], // Fill color when checked
                  checkColor: Colors.blueGrey[900], // Tick color
                ),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  color: Colors.white,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.orange[200], // Strikethrough color
                  decorationThickness: 2, // Optional: makes the line bolder
                ),
              ),
              subtitle: Text(
                "Deadline: ${DateFormat('dd MMM yyyy').format(task.deadline)}",
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red[300]),
                onPressed: () => _deleteTask(task),
              ),
            ),

          );

        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        foregroundColor: Colors.blueGrey[900],
        backgroundColor: Colors.orange[200],
        child: const Icon(Icons.add),
      ),
    );
  }
}

//subject page
class SubjectPage extends StatefulWidget {
  @override
  _SubjectPageState createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  List<Subject> subjects = [];
  bool isEditing = false;
  Set<int> selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadSubjects(); // Load subjects from Firestore when the widget initializes
  }

  // Load subjects from Firestore
  Future<void> _loadSubjects() async {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .get();

    setState(() {
      subjects.clear(); // Clear existing subjects
      for (var doc in snapshot.docs) {
        subjects.add(Subject.fromFirestore(doc)); // Convert each document to a Subject
      }
    });
  }

  // Add a new subject
  void addSubject() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.blueGrey[800],
          title: const Text(
            'Add Subject',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            cursorColor: Colors.orangeAccent,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter subject name',
              hintStyle: const TextStyle(color: Colors.white70),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orangeAccent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final newSubject = Subject(
                    id: UniqueKey().toString(), // Generate a unique ID
                    name: controller.text,
                  );
                  _addSubjectToFirestore(newSubject); // Save subject to Firestore
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Add',
                style: TextStyle(color: Colors.orange.shade200),
              ),
            ),
          ],
        );
      },
    );
  }

  // Save the subject to Firestore
  Future<void> _addSubjectToFirestore(Subject subject) async {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .add(subject.toMap()); // Convert Subject to Map and save
    _loadSubjects(); // Reload subjects after adding
  }

  void toggleEditing() {
    setState(() {
      isEditing = !isEditing;
      selectedIndices.clear();
    });
  }

  // Delete selected subjects
  void deleteSelected() {
    setState(() {
      final sortedIndices = selectedIndices.toList()..sort((a, b) => b.compareTo(a));
      for (var index in sortedIndices) {
        _deleteSubjectFromFirestore(subjects[index]); // Delete from Firestore
        subjects.removeAt(index); // Remove from local list
      }
      selectedIndices.clear();
      isEditing = false;
    });
  }

  // Delete subject from Firestore
  Future<void> _deleteSubjectFromFirestore(Subject subject) async {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID

    final chapterSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(subject.id) // Use the stored ID
        .collection('chapters')
        .get();

    // Delete each chapter and its topics
    for (var chapterDoc in chapterSnapshot.docs) {
      // Delete topics associated with the chapter
      final topicSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(subject.id)
          .collection('chapters')
          .doc(chapterDoc.id) // Use the chapter ID
          .collection('topics')
          .get();

      for (var topicDoc in topicSnapshot.docs) {
        await topicDoc.reference.delete(); // Delete each topic
      }

      // Now delete the chapter itself
      await chapterDoc.reference.delete(); // Delete the chapter document
    }

    // Finally, delete the subject document
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(subject.id) // Use the stored ID
        .delete(); // Delete the subject document
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[700],
        title: Text('Subjects', style: TextStyle(color: Colors.orange[100])),
        iconTheme: IconThemeData(color: Colors.orange[100]),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: selectedIndices.isEmpty ? null : deleteSelected,
              tooltip: 'Delete Selected',
            ),
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit),
            onPressed: toggleEditing,
            tooltip: isEditing ? 'Cancel Edit' : 'Edit',
          ),
        ],
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndices.contains(index);
          return GestureDetector(
            onTap: () {
              if (isEditing) {
                setState(() {
                  if (isSelected) {
                    selectedIndices.remove(index);
                  } else {
                    selectedIndices.add(index);
                  }
                });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChapterPage(
                        subjectId: subjects[index].id,
                        subjectName: subjects[index].name,
                    ),// Assuming `id` is a String property of Subject
                  ),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.red[300] : Colors.orange[200],
                borderRadius: BorderRadius.circular(16.0),
                border: isSelected
                    ? Border.all(color: Colors.redAccent, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  subjects[index].name,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: isEditing
          ? null
          : FloatingActionButton(
        onPressed: addSubject,
        foregroundColor: Colors.blueGrey[900],
        backgroundColor: Colors.orange[200],
        child: Icon(Icons.add),
      ),
    );
  }
}


//chapter page

class ChapterPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  ChapterPage({required this.subjectId, required this.subjectName});

  @override
  _ChapterPageState createState() => _ChapterPageState();
}

class _ChapterPageState extends State<ChapterPage> {
  List<Chapter> chapters = [];
  bool isEditing = false;
  Set<int> selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadChapters(); // Load chapters when the page initializes
  }

  // Load chapters from Firestore
  Future<void> _loadChapters() async {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(widget.subjectId) // Use subjectId instead of subject
        .collection('chapters')
        .get();

    List<Chapter> loadedChapters = [];

    for (var doc in snapshot.docs) {
      // Load topics for each chapter
      Chapter chapter = Chapter.fromFirestore(doc);
      await _loadTopicsForChapter(chapter); // Wait for topics to load
      loadedChapters.add(chapter);
    }

    setState(() {
      chapters = loadedChapters; // Update state with loaded chapters
    });
  }

  // Load topics for a specific chapter
  Future<void> _loadTopicsForChapter(Chapter chapter) async {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    final topicSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(widget.subjectId)
        .collection('chapters')
        .doc(chapter.id)
        .collection('topics')
        .get();

    chapter.topics = topicSnapshot.docs.map((doc) {
      return Topic.fromFirestore(doc);
    }).toList();
  }

  // Add a new chapter
  void addChapter() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey[800],
        title: const Text(
          'Add Chapter',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          cursorColor: Colors.orangeAccent,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter chapter name',
            hintStyle: const TextStyle(color: Colors.white70),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orangeAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final newChapter = Chapter(
                  id: UniqueKey().toString(), // Generate a unique ID
                  name: controller.text,
                  topics: [],
                );
                _addChapterToFirestore(newChapter); // Save chapter to Firestore
                Navigator.pop(context);
              }
            },
            child: Text(
              'Add',
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ),
        ],
      ),
    );
  }

  // Save the chapter to Firestore
  Future<void> _addChapterToFirestore(Chapter chapter) async {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(widget.subjectId)
        .collection('chapters')
        .add(chapter.toMap()); // Convert Chapter to Map and save
    _loadChapters(); // Reload chapters after adding
  }

  // Calculate chapter progress
  double calculateChapterProgress(Chapter chapter) {
    if (chapter.topics.isEmpty) return 0.0;
      double total = chapter.topics.fold(0.0, (sum, t) => sum + t.progress);
      return total / chapter.topics.length;
  }



  // Delete selected chapters
  void deleteSelectedChapters() {
    setState(() {
      final indices = selectedIndices.toList()..sort((a, b) => b.compareTo(a));
      for (var index in indices) {
        _deleteChapterFromFirestore(chapters[index]); // Delete from Firestore
        chapters.removeAt(index); // Remove from local list
      }
      selectedIndices.clear();
      isEditing = false;
    });
  }



  // Delete chapter from Firestore
  Future<void> _deleteChapterFromFirestore(Chapter chapter) async {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID

    // First, delete all topics associated with the chapter
    final topicSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(widget.subjectId) // Use the subject ID
        .collection('chapters')
        .doc(chapter.id) // Use the chapter ID
        .collection('topics')
        .get();

    // Delete each topic
    for (var doc in topicSnapshot.docs) {
      await doc.reference.delete();
    }

    // Now delete the chapter itself
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(widget.subjectId) // Use the subject ID
        .collection('chapters')
        .doc(chapter.id) // Use the chapter ID
        .delete(); // Delete the chapter document
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[700],
        title: Text('${widget.subjectName} - Chapters', style: TextStyle(color: Colors.orange[100])),
        iconTheme: IconThemeData(color: Colors.orange[100]),
        actions: isEditing
            ? [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: selectedIndices.isNotEmpty ? deleteSelectedChapters : null,
            color: selectedIndices.isNotEmpty ? Colors.orange[200] : Colors.orange[100]?.withOpacity(0.5),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.orange[200]),
            onPressed: () {
              setState(() {
                isEditing = false;
                selectedIndices.clear();
              });
            },
          ),
        ]
            : [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              setState(() {
                isEditing = true;
              });
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: chapters.length,
        itemBuilder: (context, index) {

          double progress = chapters[index].completionPercent;

          return ListTile(
            tileColor: isEditing && selectedIndices.contains(index)
                ? Colors.orange[100]?.withOpacity(0.2)
                : null,
            leading: isEditing
                ? Checkbox(
              activeColor: Colors.orange[300],
              checkColor: Colors.blueGrey[900],
              value: selectedIndices.contains(index),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    selectedIndices.add(index);
                  } else {
                    selectedIndices.remove(index);
                  }
                });
              },
            )
                : null,
            title: Text(
              chapters[index].name,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              "Completion: ${(progress * 100).toStringAsFixed(1)}%", // Display progress
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: CircularPercentIndicator(
              radius: 20.0,
              lineWidth: 5.0,
              percent: progress,
              center: Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(color: Colors.orange[200], fontSize: 12),
              ),
              progressColor: Colors.orange[200],
            ),
            onTap: isEditing
                ? () {
              setState(() {
                if (selectedIndices.contains(index)) {
                  selectedIndices.remove(index);
                } else {
                  selectedIndices.add(index);
                }
              });
            }
                : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TopicPage(
                      chapterId: chapters[index].id,
                    subjectId: widget.subjectId,
                    chapterName: chapters[index].name,
                  ), // Use the correct property

                ),
              ).then((_) {
                // Refresh the chapter data after returning from the TopicPage
                _loadChapters();
              });
            },
          );
        },
      ),
      floatingActionButton: isEditing
          ? null
          : FloatingActionButton(
        onPressed: addChapter,
        foregroundColor: Colors.blueGrey[900],
        backgroundColor: Colors.orange[200],
        child: const Icon(Icons.add),
      ),
    );
  }
}



//topic page
class TopicPage extends StatefulWidget {
  final String chapterId;
  final String chapterName;// Pass chapter ID to identify which chapter's topics to manage
  final String subjectId;

  TopicPage({required this.chapterId, required this.subjectId, required this.chapterName});

  @override
  _TopicPageState createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  List<Topic> topics = [];
  bool isEditing = false;
  Set<int> selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadTopics(); // Load topics when the page initializes
  }

  // Load topics from Firestore
  Future<void> _loadTopics() async {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(widget.subjectId) // Ensure this is correct
        .collection('chapters')
        .doc(widget.chapterId) // Use chapter ID
        .collection('topics')
        .get();

    setState(() {
      topics = snapshot.docs.map((doc) {
        print("Loaded topic ID: ${doc.id}"); // Log each loaded topic ID
        return Topic.fromFirestore(doc);
      }).toList();
      print("Topics loaded: $topics");
    });
  }




  // Add a new topic
  void addTopic() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey[800],
        title: const Text(
          'Add Topic',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          cursorColor: Colors.orangeAccent,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter topic name',
            hintStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orangeAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final newTopic = Topic(name: controller.text, progress: 0.0);
                _addTopicToFirestore(newTopic); // Save topic to Firestore
                Navigator.pop(context);
              }
            },
            child: Text(
              'Add',
              style: TextStyle(color: Colors.orange[200]),
            ),
          ),
        ],
      ),
    );
  }



  // Save the topic to Firestore
  Future<void> _addTopicToFirestore(Topic topic) async {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(widget.subjectId) // Use subject ID
        .collection('chapters')
        .doc(widget.chapterId) // Use chapter ID
        .collection('topics')
        .add(topic.toMap())
        .then((value) {
      print("Topic added successfully");
      _loadTopics(); // Load topics after successfully adding
    })
        .catchError((error) {
      print("Failed to add topic: $error");
    });
  }




  // Update the progress of a topic
  void updateProgress(int index, double value) {
    setState(() {
      topics[index].progress = value; // Update local progress
      _updateTopicInFirestore(topics[index]); // Update in Firestore
    });
  }

  // Update topic in Firestore
  // Update topic in Firestore
  Future<void> _updateTopicInFirestore(Topic topic) async {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subjects')
        .doc(widget.subjectId) // Ensure subject ID is used
        .collection('chapters')
        .doc(widget.chapterId) // Ensure chapter ID is used
        .collection('topics')
        .where('name', isEqualTo: topic.name) // Find the topic by name
        .get();

    if (snapshot.docs.isNotEmpty) {
      final docId = snapshot.docs.first.id; // Get the document ID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .doc(widget.subjectId) // Ensure subject ID is used
          .collection('chapters')
          .doc(widget.chapterId) // Ensure chapter ID is used
          .collection('topics')
          .doc(docId)
          .update({
        'name': topic.name,
        'progress': topic.progress, // Ensure progress is included
      });
    }
  }


  // Toggle topic selection for deletion
  void toggleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
      } else {
        selectedIndices.add(index);
      }
    });
  }

  // Delete selected topics
  void deleteSelectedTopics() {
    setState(() {
      final indices = selectedIndices.toList()..sort((a, b) => b.compareTo(a));
      for (var i in indices) {
        _deleteTopicFromFirestore(topics[i]); // Delete from Firestore
        topics.removeAt(i); // Remove from local list
      }
      selectedIndices.clear();
      isEditing = false;
    });
  }

  // Delete topic from Firestore
  Future<void> _deleteTopicFromFirestore(Topic topic) async {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chapters')
        .doc(widget.chapterId) // Use chapter ID
        .collection('topics')
        .where('name', isEqualTo: topic.name) // Find the topic by name
        .get();

    if (snapshot.docs.isNotEmpty) {
      final docId = snapshot.docs.first.id; // Get the document ID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('chapters')
          .doc(widget.chapterId)
          .collection('topics')
          .doc(docId)
          .delete(); // Delete the topic document
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[700],
        title: Text('${widget.chapterName} - Topics', style: TextStyle(color: Colors.orange[100])),
        iconTheme: IconThemeData(color: Colors.orange[100]),
        actions: isEditing
            ? [
          IconButton(
            icon: Icon(Icons.delete),
            color: selectedIndices.isNotEmpty
                ? Colors.orange[200]
                : Colors.orange[100]?.withOpacity(0.5),
            onPressed: selectedIndices.isNotEmpty ? deleteSelectedTopics : null,
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.orange[200]),
            onPressed: () {
              setState(() {
                isEditing = false;
                selectedIndices.clear();
              });
            },
          )
        ]
            : [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              setState(() {
                isEditing = true;
              });
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: topics.length,
        itemBuilder: (context, index) {
          var topic = topics[index];
          bool isSelected = selectedIndices.contains(index);
          return ListTile(
            onTap: isEditing ? () => toggleSelection(index) : null,
            leading: isEditing
                ? Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? Colors.orange[200] : Colors.white70,
            )
                : null,
            title: Text(
              topic.name,
              style: TextStyle(
                color: Colors.white,
                decoration: isEditing && isSelected ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
            subtitle: isEditing
                ? null
                : SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.orange[200],
                inactiveTrackColor: Colors.orange[200]!.withOpacity(0.3),
                thumbColor: Colors.orange[200],
                overlayColor: Colors.orange[200]!.withOpacity(0.2),
                valueIndicatorColor: Colors.orange[200],
                valueIndicatorTextStyle: const TextStyle(color: Colors.black),
              ),
              child: Slider(
                value: topic.progress,
                onChanged: (value) => updateProgress(index, value),
                min: 0.0,
                max: 1.0,
                divisions: 100,
                label: '${(topic.progress * 100).toInt()}%',
              ),
            ),
          );
        },
      ),
      floatingActionButton: isEditing
          ? null
          : FloatingActionButton(
        onPressed: addTopic,
        foregroundColor: Colors.blueGrey[900],
        backgroundColor: Colors.orange[200],
        child: const Icon(Icons.add),
      ),
    );
  }
}

