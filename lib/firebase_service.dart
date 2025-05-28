import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final user = FirebaseAuth.instance.currentUser;
final uid = user?.uid;

// Save a task
Future<void> saveTask(String title, bool completed) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('tasks')
      .add({
    'title': title,
    'completed': completed,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

// Fetch user tasks as a stream
Stream<QuerySnapshot> getUserTasks() {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('tasks')
      .orderBy('timestamp', descending: true)
      .snapshots();
}
