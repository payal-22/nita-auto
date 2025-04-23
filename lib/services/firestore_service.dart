import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Stream of travel details for graph
  Stream<QuerySnapshot> getTravelDetailsStream() {
    // Get today's date in YYYY-MM-DD format
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return _firestore
        .collection('travel_details')
        .where('travel_date', isEqualTo: today)
        .snapshots();
  }

  // Add travel details
  Future<void> addTravelDetails({
    required String travelTime,
    required String travelDate,
    required int peopleCount,
  }) async {
    try {
      await _firestore.collection('travel_details').add({
        'travel_time': travelTime,
        'travel_date': travelDate,
        'people_count': peopleCount,
        'user_id': currentUserId,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding travel details: $e');
      rethrow;
    }
  }

  // Add a comment
  Future<void> addComment(String comment) async {
    try {
      await _firestore.collection('comments').add({
        'text': comment,
        'user_id': currentUserId,
        'username': await getUsernameById(currentUserId),
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  // Get stream of comments
  Stream<QuerySnapshot> getCommentsStream() {
    return _firestore
        .collection('comments')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // Helper to get username by ID
  Future<String> getUsernameById(String? userId) async {
    if (userId == null) return 'Anonymous';

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc.get('username') ?? 'User' : 'User';
    } catch (e) {
      return 'User';
    }
  }
}
