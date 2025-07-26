import 'package:cloud_firestore/cloud_firestore.dart';

class LessonService {
  final FirebaseFirestore firestore;

  LessonService({FirebaseFirestore? firestoreInstance})
      : firestore = firestoreInstance ?? FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchLessons() async {
    final snapshot = await firestore.collection('lessons').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
} 