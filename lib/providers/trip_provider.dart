import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import '../services/firebase/firestore_service.dart';
import '../services/local/local_storage_service.dart';

class TripProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<TripModel> _trips = [];
  bool _isLoading = false;
  String? _error;

  List<TripModel> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load Trips
  Future<void> loadTrips(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _trips = await _firestoreService.getUserTrips(userId);
      await LocalStorageService.saveTrips(_trips);
    } catch (e) {
      print('Provider Load Error: $e');
      _trips = LocalStorageService.getTrips(); // Fallback to local
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Trip
  Future<bool> createTrip(TripModel trip) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // 1. Create in Firestore and get ID
      final id = await _firestoreService.createTrip(trip);
      
      // 2. Update local model with ID
      final newTrip = trip.copyWith(id: id);
      
      // 3. Add to list and sort
      _trips.insert(0, newTrip);
      _trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // 4. Save local cache
      await LocalStorageService.saveTrips(_trips);
      return true;
    } catch (e) {
      print('Provider Create Error: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete Trip
  Future<void> deleteTrip(String tripId) async {
    try {
      await _firestoreService.deleteTrip(tripId);
      _trips.removeWhere((t) => t.id == tripId);
      await LocalStorageService.saveTrips(_trips);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}