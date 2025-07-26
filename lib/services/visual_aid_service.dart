import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class VisualAidService {
  final FirebaseFirestore _firestore;
  static const String _offlineBox = 'visual_aids_offline';
  
  VisualAidService({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance {
    _initHive();
  }

  Future<void> _initHive() async {
    if (!Hive.isBoxOpen(_offlineBox)) {
      Directory dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
      await Hive.openBox(_offlineBox);
    }
  }

  // Save visual aid to Firestore
  Future<String> saveVisualAid({
    required String teacherId,
    required String subject,
    required String topic,
    required String visualContent,
    required String explanation,
    required String language,
    required String gradeLevel,
    bool aiGenerated = true,
  }) async {
    try {
      final visualAidData = {
        'teacherId': teacherId,
        'subject': subject,
        'topic': topic,
        'visualContent': visualContent,
        'explanation': explanation,
        'language': language,
        'gradeLevel': gradeLevel,
        'aiGenerated': aiGenerated,
        'generatedAt': FieldValue.serverTimestamp(),
        'usageCount': 0,
        'effectiveness': 0,
        'ratingCount': 0,
        'averageRating': 0.0,
        'tags': _generateTags(subject, topic),
        'isPublic': false, // For sharing between teachers
      };

      final docRef = await _firestore.collection('visual_aids').add(visualAidData);
      
      // Also save to offline cache
      await _saveToOfflineCache(docRef.id, visualAidData);
      
      print('[VisualAidService] Visual aid saved successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('[VisualAidService] Error saving visual aid: $e');
      // Save to offline queue for later sync
      await _queueForOfflineSync(visualAidData);
      rethrow;
    }
  }

  // Get visual aids for a teacher
  Future<List<Map<String, dynamic>>> getTeacherVisualAids(String teacherId) async {
    try {
      final snapshot = await _firestore
          .collection('visual_aids')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('generatedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('[VisualAidService] Error fetching teacher visual aids: $e');
      // Return offline cached data
      return await _getOfflineVisualAids(teacherId);
    }
  }

  // Get visual aids by subject
  Future<List<Map<String, dynamic>>> getVisualAidsBySubject(String subject) async {
    try {
      final snapshot = await _firestore
          .collection('visual_aids')
          .where('subject', isEqualTo: subject)
          .where('isPublic', isEqualTo: true)
          .orderBy('usageCount', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('[VisualAidService] Error fetching visual aids by subject: $e');
      return [];
    }
  }

  // Search visual aids
  Future<List<Map<String, dynamic>>> searchVisualAids(String query) async {
    try {
      // Simple search implementation - in production, use Algolia or similar
      final snapshot = await _firestore
          .collection('visual_aids')
          .where('isPublic', isEqualTo: true)
          .get();

      final results = snapshot.docs.where((doc) {
        final data = doc.data();
        final searchText = '${data['topic']} ${data['subject']} ${data['tags']}'.toLowerCase();
        return searchText.contains(query.toLowerCase());
      }).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      return results;
    } catch (e) {
      print('[VisualAidService] Error searching visual aids: $e');
      return [];
    }
  }

  // Update visual aid effectiveness rating
  Future<void> rateVisualAid(String visualAidId, int rating) async {
    try {
      final docRef = _firestore.collection('visual_aids').doc(visualAidId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;

        final data = doc.data()!;
        final currentRating = data['averageRating'] ?? 0.0;
        final ratingCount = data['ratingCount'] ?? 0;
        
        final newRatingCount = ratingCount + 1;
        final newAverageRating = ((currentRating * ratingCount) + rating) / newRatingCount;

        transaction.update(docRef, {
          'averageRating': newAverageRating,
          'ratingCount': newRatingCount,
          'effectiveness': newAverageRating.round(),
        });
      });

      print('[VisualAidService] Visual aid rated successfully');
    } catch (e) {
      print('[VisualAidService] Error rating visual aid: $e');
    }
  }

  // Increment usage count
  Future<void> incrementUsageCount(String visualAidId) async {
    try {
      await _firestore.collection('visual_aids').doc(visualAidId).update({
        'usageCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('[VisualAidService] Error incrementing usage count: $e');
    }
  }

  // Share visual aid (make public)
  Future<void> shareVisualAid(String visualAidId) async {
    try {
      await _firestore.collection('visual_aids').doc(visualAidId).update({
        'isPublic': true,
        'sharedAt': FieldValue.serverTimestamp(),
      });
      print('[VisualAidService] Visual aid shared successfully');
    } catch (e) {
      print('[VisualAidService] Error sharing visual aid: $e');
    }
  }

  // Get visual aid analytics
  Future<Map<String, dynamic>> getVisualAidAnalytics(String teacherId) async {
    try {
      final snapshot = await _firestore
          .collection('visual_aids')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      final visualAids = snapshot.docs.map((doc) => doc.data()).toList();
      
      int totalVisualAids = visualAids.length;
      int totalUsage = visualAids.fold(0, (sum, aid) => sum + (aid['usageCount'] ?? 0));
      double averageRating = visualAids.isEmpty ? 0 : 
          visualAids.fold(0.0, (sum, aid) => sum + (aid['averageRating'] ?? 0)) / totalVisualAids;
      
      // Subject distribution
      Map<String, int> subjectDistribution = {};
      for (var aid in visualAids) {
        final subject = aid['subject'] ?? 'unknown';
        subjectDistribution[subject] = (subjectDistribution[subject] ?? 0) + 1;
      }

      return {
        'totalVisualAids': totalVisualAids,
        'totalUsage': totalUsage,
        'averageRating': averageRating,
        'subjectDistribution': subjectDistribution,
        'mostUsedSubject': subjectDistribution.entries
            .reduce((a, b) => a.value > b.value ? a : b).key,
      };
    } catch (e) {
      print('[VisualAidService] Error getting analytics: $e');
      return {
        'totalVisualAids': 0,
        'totalUsage': 0,
        'averageRating': 0.0,
        'subjectDistribution': {},
        'mostUsedSubject': 'none',
      };
    }
  }

  // Offline caching methods
  Future<void> _saveToOfflineCache(String id, Map<String, dynamic> data) async {
    final box = await Hive.openBox(_offlineBox);
    data['id'] = id;
    data['cachedAt'] = DateTime.now().toIso8601String();
    await box.put(id, data);
  }

  Future<List<Map<String, dynamic>>> _getOfflineVisualAids(String teacherId) async {
    final box = await Hive.openBox(_offlineBox);
    final allData = box.values.toList();
    
    return allData.where((data) => 
        data['teacherId'] == teacherId).map((data) => 
        Map<String, dynamic>.from(data)).toList();
  }

  Future<void> _queueForOfflineSync(Map<String, dynamic> data) async {
    final box = await Hive.openBox(_offlineBox);
    data['queuedForSync'] = true;
    data['queuedAt'] = DateTime.now().toIso8601String();
    await box.add(data);
  }

  // Sync offline data
  Future<void> syncOfflineData() async {
    final box = await Hive.openBox(_offlineBox);
    final queuedData = box.values.where((data) => data['queuedForSync'] == true).toList();
    
    for (var data in queuedData) {
      try {
        await saveVisualAid(
          teacherId: data['teacherId'],
          subject: data['subject'],
          topic: data['topic'],
          visualContent: data['visualContent'],
          explanation: data['explanation'],
          language: data['language'],
          gradeLevel: data['gradeLevel'],
          aiGenerated: data['aiGenerated'] ?? true,
        );
        await box.delete(data);
      } catch (e) {
        print('[VisualAidService] Error syncing offline data: $e');
      }
    }
  }

  // Generate tags for search
  List<String> _generateTags(String subject, String topic) {
    final tags = [subject, topic];
    
    // Add subject-specific tags
    switch (subject.toLowerCase()) {
      case 'math':
        tags.addAll(['mathematics', 'calculation', 'numbers']);
        break;
      case 'science':
        tags.addAll(['experiment', 'observation', 'discovery']);
        break;
      case 'english':
        tags.addAll(['language', 'grammar', 'communication']);
        break;
      case 'hindi':
        tags.addAll(['भाषा', 'व्याकरण', 'संचार']);
        break;
    }
    
    return tags;
  }

  // Delete visual aid
  Future<void> deleteVisualAid(String visualAidId) async {
    try {
      await _firestore.collection('visual_aids').doc(visualAidId).delete();
      
      // Also remove from offline cache
      final box = await Hive.openBox(_offlineBox);
      await box.delete(visualAidId);
      
      print('[VisualAidService] Visual aid deleted successfully');
    } catch (e) {
      print('[VisualAidService] Error deleting visual aid: $e');
    }
  }

  // Get trending visual aids
  Future<List<Map<String, dynamic>>> getTrendingVisualAids() async {
    try {
      final snapshot = await _firestore
          .collection('visual_aids')
          .where('isPublic', isEqualTo: true)
          .orderBy('usageCount', descending: true)
          .orderBy('averageRating', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('[VisualAidService] Error fetching trending visual aids: $e');
      return [];
    }
  }
} 