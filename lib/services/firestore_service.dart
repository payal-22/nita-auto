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

  // Get travel details for a specific date
  Stream<QuerySnapshot> getTravelDetailsForDate(String date) {
    return _firestore
        .collection('travel_details')
        .where('travel_date', isEqualTo: date)
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
      String username = await getUsernameById(currentUserId);

      await _firestore.collection('comments').add({
        'text': comment,
        'user_id': currentUserId,
        'username': username,
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
      if (userDoc.exists) {
        // Try to get 'name' field first, then 'username', then fallback
        final data = userDoc.data() as Map<String, dynamic>?;
        return data?['name'] ?? data?['username'] ?? 'User';
      }
      return 'User';
    } catch (e) {
      print('Error getting username: $e');
      return 'User';
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc.data() : null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Get current user's travel history
  Stream<QuerySnapshot> getUserTravelHistory() {
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('travel_details')
        .where('user_id', isEqualTo: currentUserId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // Delete a travel detail (only by the user who created it)
  Future<void> deleteTravelDetail(
      String documentId, String creatorUserId) async {
    if (currentUserId != creatorUserId) {
      throw Exception('You can only delete your own travel details');
    }

    try {
      await _firestore.collection('travel_details').doc(documentId).delete();
    } catch (e) {
      print('Error deleting travel detail: $e');
      rethrow;
    }
  }

  // Get analytics data for admin or insights
  Future<Map<String, dynamic>> getTravelAnalytics() async {
    try {
      final snapshot = await _firestore.collection('travel_details').get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalTrips': 0,
          'totalPeople': 0,
          'averagePeoplePerTrip': 0,
          'popularTimes': <String, int>{},
        };
      }

      int totalTrips = snapshot.docs.length;
      int totalPeople = 0;
      Map<String, int> timeFrequency = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalPeople += (data['people_count'] as int? ?? 0);

        String time = data['travel_time'] as String? ?? '';
        if (time.isNotEmpty) {
          timeFrequency[time] = (timeFrequency[time] ?? 0) + 1;
        }
      }

      // Sort popular times
      var sortedTimes = timeFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      Map<String, int> popularTimes = Map.fromEntries(sortedTimes.take(5));

      return {
        'totalTrips': totalTrips,
        'totalPeople': totalPeople,
        'averagePeoplePerTrip': totalPeople / totalTrips,
        'popularTimes': popularTimes,
      };
    } catch (e) {
      print('Error getting analytics: $e');
      return {
        'totalTrips': 0,
        'totalPeople': 0,
        'averagePeoplePerTrip': 0,
        'popularTimes': <String, int>{},
      };
    }
  }
}
