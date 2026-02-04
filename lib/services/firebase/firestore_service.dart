import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/constants.dart';
import '../../models/user_model.dart';
import '../../models/trip_model.dart';
import '../../models/place_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users ---
  Future<void> createUser(UserModel user) async {
    try {
      await _db.collection(AppConstants.usersCollection).doc(user.id).set(user.toJson());
    } catch (e) {
      throw e;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists) return UserModel.fromJson(doc.data()!);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection(AppConstants.usersCollection).doc(user.id).update(user.toJson());
  }

  // --- Trips ---
  Future<String> createTrip(TripModel trip) async {
    try {
      // Create a document with a generated ID first so we can save the ID inside the document
      final docRef = _db.collection(AppConstants.tripsCollection).doc();
      final tripWithId = trip.copyWith(id: docRef.id);
      
      await docRef.set(tripWithId.toJson());
      return docRef.id;
    } catch (e) {
      throw 'Failed to save trip: $e';
    }
  }

  Future<List<TripModel>> getUserTrips(String userId) async {
    try {
    
      // FIX: Removed .orderBy('createdAt') to prevent "Index Required" errors.
      // We will sort the results in Dart code instead.
      final snapshot = await _db.collection(AppConstants.tripsCollection)
          .where('userId', isEqualTo: userId)
          .get();

    
      final trips = snapshot.docs.map((d) {
        try {
          // Ensure ID is included
          final data = d.data();
          data['id'] = d.id; 
          return TripModel.fromJson(data);
        } catch (e) {
          
          return null;
        }
      }).whereType<TripModel>().toList(); // Filter out failed parses

      // Sort by Date Descending (Newest first) in Memory
      trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return trips;
    } catch (e) {
       throw e;
    }
  }

  Future<TripModel?> getTrip(String tripId) async {
    try {
      final doc = await _db.collection(AppConstants.tripsCollection).doc(tripId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return TripModel.fromJson(data);
      }
      return null;
    } catch (e) {
     
      return null;
    }
  }

  Future<void> updateTrip(TripModel trip) async {
    await _db.collection(AppConstants.tripsCollection).doc(trip.id).update(trip.toJson());
  }

  Future<void> deleteTrip(String tripId) async {
    await _db.collection(AppConstants.tripsCollection).doc(tripId).delete();
  }

  // --- Bookmarks ---
  Future<void> addBookmark(String userId, PlaceModel place) async {
    await _db.collection(AppConstants.bookmarksCollection)
        .doc(userId)
        .collection('places')
        .doc(place.id)
        .set(place.toJson());
  }

  Future<void> removeBookmark(String userId, String placeId) async {
    await _db.collection(AppConstants.bookmarksCollection)
        .doc(userId)
        .collection('places')
        .doc(placeId)
        .delete();
  }

  Future<List<PlaceModel>> getUserBookmarks(String userId) async {
    final snapshot = await _db.collection(AppConstants.bookmarksCollection)
        .doc(userId)
        .collection('places')
        .get();
    return snapshot.docs.map((d) => PlaceModel.fromJson(d.data())).toList();
  }
}