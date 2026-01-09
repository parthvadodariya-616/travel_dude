// lib/services/local/local_storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../models/place_model.dart';
import '../../models/trip_model.dart';
import '../../utils/helpers.dart'; // Ensure Helpers is imported if used

class LocalStorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Assuming Helpers.log is available, otherwise use print
    Helpers.log('Local storage initialized', tag: 'STORAGE');
  }

  // Getter for safe access
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('LocalStorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ========== COMPATIBILITY METHODS ==========
  static Future<void> setString(String key, String value) async {
    await prefs.setString(key, value);
  }

  static Future<void> setBool(String key, bool value) async {
    await prefs.setBool(key, value);
  }

  // ========== USER DATA ==========
  static Future<void> saveUser(String userId, String email, String name) async {
    await prefs.setString(AppConstants.keyUserId, userId);
    // Ideally these keys should be in AppConstants, using literals for compatibility based on provided file
    await prefs.setString('user_email', email); 
    await prefs.setString('user_name', name);
    await prefs.setBool('is_logged_in', true);
  }

  static Future<void> clearUser() async {
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('is_logged_in');
  }
  
  // Method referenced in AuthProvider
  static Future<void> clearUserData() async {
    await clearUser();
    await prefs.remove(AppConstants.keySavedTrips);
    await prefs.remove(AppConstants.keyBookmarkedPlaces);
    await prefs.remove(AppConstants.keyRecentSearches);
  }

  static String? getUserId() => prefs.getString(AppConstants.keyUserId);
  static String? getUserEmail() => prefs.getString('user_email');
  static String? getUserName() => prefs.getString('user_name');
  static bool isLoggedIn() => prefs.getBool('is_logged_in') ?? false;

  // ========== THEME ==========
  static const String _keyThemeMode = 'theme_mode'; 

  static Future<void> saveThemeMode(String mode) async {
    await prefs.setString(_keyThemeMode, mode);
  }

  static String getThemeMode() {
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  // ========== SEARCHES ==========
  static Future<void> addSearch(String query) async {
    if (query.isEmpty) return;
    List<String> searches = getRecentSearches();
    searches.remove(query); // Remove duplicate
    searches.insert(0, query); // Add to top
    if (searches.length > 10) searches = searches.sublist(0, 10); // Limit to 10
    await prefs.setStringList(AppConstants.keyRecentSearches, searches);
  }

  static List<String> getRecentSearches() {
    return prefs.getStringList(AppConstants.keyRecentSearches) ?? [];
  }

  // ========== BOOKMARKS (Local Cache) ==========
  static Future<void> saveBookmarks(List<PlaceModel> bookmarks) async {
    try {
      final String data = jsonEncode(bookmarks.map((e) => e.toJson()).toList());
      await prefs.setString(AppConstants.keyBookmarkedPlaces, data);
    } catch (e) {
      Helpers.log('Error saving bookmarks: $e', tag: 'STORAGE');
    }
  }

  static List<PlaceModel> getBookmarks() {
    final String? data = prefs.getString(AppConstants.keyBookmarkedPlaces);
    if (data == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => PlaceModel.fromJson(e)).toList();
    } catch (e) {
      Helpers.log('Error parsing local bookmarks: $e', tag: 'STORAGE');
      return [];
    }
  }

  // ========== TRIPS (Local Cache) ==========
  static Future<void> saveTrips(List<TripModel> trips) async {
    try {
      final String data = jsonEncode(trips.map((e) => e.toJson()).toList());
      await prefs.setString(AppConstants.keySavedTrips, data);
    } catch (e) {
      Helpers.log('Error saving trips: $e', tag: 'STORAGE');
    }
  }

  static List<TripModel> getTrips() {
    final String? data = prefs.getString(AppConstants.keySavedTrips);
    if (data == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => TripModel.fromJson(e)).toList();
    } catch (e) {
      Helpers.log('Error parsing local trips: $e', tag: 'STORAGE');
      return [];
    }
  }

  // ========== IMAGE HELPERS (Unsplash Integration) ==========
  
  /// Helper to update a specific bookmark's image URL locally
  static Future<void> updateBookmarkImage(String placeId, String imageUrl) async {
    try {
      final bookmarks = getBookmarks();
      final index = bookmarks.indexWhere((p) => p.id == placeId);
      if (index != -1) {
        bookmarks[index] = bookmarks[index].copyWith(imageUrl: imageUrl);
        await saveBookmarks(bookmarks);
      }
    } catch (e) {
      Helpers.log('Error updating bookmark image: $e', tag: 'STORAGE');
    }
  }

  /// BATCH UPDATE: Use this for better performance when loading multiple images
  static Future<void> batchUpdateBookmarkImages(Map<String, String> idToUrl) async {
    if (idToUrl.isEmpty) return;
    try {
      final bookmarks = getBookmarks();
      bool changed = false;
      for (var i = 0; i < bookmarks.length; i++) {
        if (idToUrl.containsKey(bookmarks[i].id)) {
          bookmarks[i] = bookmarks[i].copyWith(imageUrl: idToUrl[bookmarks[i].id]);
          changed = true;
        }
      }
      if (changed) await saveBookmarks(bookmarks);
    } catch (e) {
      Helpers.log('Error batch updating bookmark images: $e', tag: 'STORAGE');
    }
  }

  /// Helper to update a specific trip's image URL locally
  static Future<void> updateTripImage(String tripId, String imageUrl) async {
    try {
      final trips = getTrips();
      final index = trips.indexWhere((t) => t.id == tripId);
      if (index != -1) {
        trips[index] = trips[index].copyWith(imageUrl: imageUrl);
        await saveTrips(trips);
      }
    } catch (e) {
      Helpers.log('Error updating trip image: $e', tag: 'STORAGE');
    }
  }

  /// BATCH UPDATE: Use this for better performance when loading multiple images
  static Future<void> batchUpdateTripImages(Map<String, String> idToUrl) async {
    if (idToUrl.isEmpty) return;
    try {
      final trips = getTrips();
      bool changed = false;
      for (var i = 0; i < trips.length; i++) {
        if (idToUrl.containsKey(trips[i].id)) {
          trips[i] = trips[i].copyWith(imageUrl: idToUrl[trips[i].id]);
          changed = true;
        }
      }
      if (changed) await saveTrips(trips);
    } catch (e) {
      Helpers.log('Error batch updating trip images: $e', tag: 'STORAGE');
    }
  }
}