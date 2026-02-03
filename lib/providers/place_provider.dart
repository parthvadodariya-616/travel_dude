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

  // SEPARATE STATE LISTS
  List<PlaceModel> _searchResults = [];      // For the full PlaceListPage
  List<PlaceModel> _suggestions = [];        // For the HomePage dropdown
  List<PlaceModel> _popularPlaces = [];      // For the "Popular Now" section
  List<PlaceModel> _bookmarks = [];
  
  bool _isLoading = false;
  String? _error;

  // GETTERS
  List<PlaceModel> get searchResults => _searchResults;
  List<PlaceModel> get suggestions => _suggestions;
  List<PlaceModel> get popularPlaces => _popularPlaces;
  List<PlaceModel> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final List<String> _allowedCountries = [
    'India', 'United States', 'Russia', 'Japan', 'France', 
    'Israel', 'Germany', 'United Kingdom', 'Australia', 'Singapore', 
    'United Arab Emirates', 'Bhutan', 'Nepal', 'Sri Lanka', 
    'Thailand', 'Vietnam', 'South Korea', 'Brazil', 'South Africa', 
    'Italy', 'Switzerland', 'Netherlands', 'Mauritius', 'Maldives'
  ];

  // 1. FETCH POPULAR PLACES (For Home Page Default)
  Future<void> loadPopularPlaces() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await _searchService.searchPlaces(query: "Tourist Attraction");
      _popularPlaces = results.take(8).toList();
      await _fetchImagesForList(_popularPlaces);
    } catch (e) {
      _error = "Failed to load popular places";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. SEARCH SUGGESTIONS (For Dropdown ONLY)
  Future<void> searchSuggestions(String query) async {
    if (query.length < 3) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final results = await _searchService.searchPlaces(query: query);
      // Filter results as per your existing logic
      _suggestions = results.where((place) {
        if (place.country == null) return true;
        return _allowedCountries.any((c) => 
          place.country!.toLowerCase().contains(c.toLowerCase()));
      }).toList();
      
      // Fetching images for suggestions (optional, keeps UI snappy)
      await _fetchImagesForList(_suggestions);
    } catch (e) {
      print('Suggestion Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. FULL SEARCH (For PlaceListPage)
  Future<void> searchPlaces(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _searchService.searchPlaces(query: query);
      _searchResults = results.where((place) {
        if (place.country == null) return true;
        return _allowedCountries.any((c) => 
          place.country!.toLowerCase().contains(c.toLowerCase()));
      }).toList();

      await _fetchImagesForList(_searchResults);
      await LocalStorageService.addSearch(query);
    } catch (e) {
      _error = "Connection failed.";
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to fetch images for a specific list to avoid cross-pollution
  Future<void> _fetchImagesForList(List<PlaceModel> targetList) async {
    final futures = <Future<void>>[];
    final limit = targetList.length > 8 ? 8 : targetList.length;

    for (int i = 0; i < limit; i++) {
      if (targetList[i].imageUrl != null) continue;
      final future = _unsplashService.getRandomPhoto(query: targetList[i].name).then((url) {
        if (url != null) {
          targetList[i] = targetList[i].copyWith(imageUrl: url);
          notifyListeners(); 
        }
      });
      futures.add(future);
    }
    await Future.wait(futures);
  }

  // --- Bookmarking Logic stays the same ---
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