// lib/providers/place_provider.dart

import 'package:flutter/foundation.dart';
import '../models/place_model.dart';
import '../services/api/nominatim_service.dart';
import '../services/api/unsplash_service.dart';
import '../services/firebase/firestore_service.dart';
import '../services/local/local_storage_service.dart';

class PlaceProvider with ChangeNotifier {
  final NominatimService _searchService = NominatimService();
  final UnsplashService _unsplashService = UnsplashService();
  final FirestoreService _firestoreService = FirestoreService();

  List<PlaceModel> _places = [];
  List<PlaceModel> _bookmarks = [];
  bool _isLoading = false;
  String? _error;

  List<PlaceModel> get places => _places;
  List<PlaceModel> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // List of friendly/allowed countries to filter results
  final List<String> _allowedCountries = [
    'India', 'United States', 'Russia', 'Japan', 'France', 
    'Israel', 'Germany', 'United Kingdom', 'Australia', 'Singapore', 
    'United Arab Emirates', 'Bhutan', 'Nepal', 'Sri Lanka', 
    'Thailand', 'Vietnam', 'South Korea', 'Brazil', 'South Africa', 
    'Italy', 'Switzerland', 'Netherlands', 'Mauritius', 'Maldives'
  ];

  // Combined Search Method: OpenStreetMap + Unsplash
  Future<void> searchPlaces(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔍 Searching for: $query');
      
      // 1. Get places from OpenStreetMap (Nominatim)
      final nominatimResults = await _searchService.searchPlaces(query: query);
      
      if (nominatimResults.isEmpty) {
         _places = [];
         _error = "No results found for '$query'";
      } else {
        // FILTER: Keep only places from allowed countries
        
        _places = nominatimResults.where((place) {
          if (place.country == null) return true; // Keep if country unknown
          return _allowedCountries.any((c) => 
            place.country!.toLowerCase().contains(c.toLowerCase()));
        }).toList();

        if (_places.isEmpty && nominatimResults.isNotEmpty) {
           // Optional: You could show the results anyway if the user explicitly searched for them,
           // but your request says "not include". So we keep it empty or show a subset.
           // Let's show zero results to strict adherence.
           _error = "No results found.";
        }

        // Notify immediately to show text results while images load
        notifyListeners(); 

        // 2. Fetch images from Unsplash for each place in parallel
        await _fetchImagesForPlaces(_places);
        
        // 3. Save search to history
        await LocalStorageService.addSearch(query);
      }
    } catch (e) {
      print('❌ Search Failed: $e');
      _error = "Connection failed. Check internet.";
      _places = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to fetch images and update the list
  Future<void> _fetchImagesForPlaces(List<PlaceModel> places) async {
    // Limit to top 8 to save bandwidth and API calls
    final limit = places.length > 8 ? 8 : places.length;
    
    // Create a list of futures to fetch images in parallel
    final futures = <Future<void>>[];

    for (int i = 0; i < limit; i++) {
      final place = places[i];
      
      // Skip if already has image (unlikely for new search)
      if (place.imageUrl != null) continue;

      final future = _unsplashService.getRandomPhoto(query: place.name).then((url) {
        if (url != null) {
          // Update the specific place in the list
          // We find index again to be safe in case list changed (though unlikely here)
          final index = _places.indexWhere((p) => p.id == place.id);
          if (index != -1) {
            _places[index] = _places[index].copyWith(imageUrl: url);
            // Notify listener for each image load to show progress visually
            notifyListeners(); 
          }
        }
      }).catchError((e) {
        print("Image load error for ${place.name}: $e");
      });

      futures.add(future);
    }

    // Wait for all image fetches to complete (optional, but good for "loading" state if you want to wait)
    // We choose NOT to await the entire batch blocking the UI, so the loop above handles notifications.
    // However, if we wanted to ensure all are loaded before 'isLoading' becomes false in searchPlaces, we would await:
    await Future.wait(futures);
  }

  // --- Bookmarking Logic ---
  Future<void> loadBookmarks(String userId) async {
    try {
      _bookmarks = await _firestoreService.getUserBookmarks(userId);
      await LocalStorageService.saveBookmarks(_bookmarks);
    } catch (e) {
      _bookmarks = LocalStorageService.getBookmarks();
    }
    notifyListeners();
  }

  Future<void> toggleBookmark(String userId, PlaceModel place) async {
    final isSaved = _bookmarks.any((p) => p.id == place.id);
    if (isSaved) {
      _bookmarks.removeWhere((p) => p.id == place.id);
      notifyListeners();
      await _firestoreService.removeBookmark(userId, place.id);
    } else {
      _bookmarks.add(place);
      notifyListeners();
      await _firestoreService.addBookmark(userId, place);
    }
    await LocalStorageService.saveBookmarks(_bookmarks);
  }

  bool isBookmarked(String id) => _bookmarks.any((p) => p.id == id);
}