// lib/services/api/unsplash_service.dart

import 'package:dio/dio.dart';
import '../../config/constants.dart';
import '../../utils/helpers.dart';

class UnsplashService {
  final Dio _dio;

  // High-quality fallback images to use if API fails or returns nothing.
  // These are real Unsplash image URLs that are guaranteed to work.
  final List<String> _fallbacks = [
    'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=800&q=80', // Nature/Travel
    'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=800&q=80', // Roadtrip
    'https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&w=800&q=80', // Travel
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80', // Beach
    'https://images.unsplash.com/photo-1519074069444-1ba4fff66d16?auto=format&fit=crop&w=800&q=80', // City
  ];

  UnsplashService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.unsplashBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Authorization': 'Client-ID ${AppConstants.unsplashAccessKey}',
            },
          ),
        );

  /// Get a random photo relevant to the query.
  /// GUARANTEED to return a valid URL (will use fallback if API fails).
  Future<String> getRandomPhoto({
    required String query,
    String orientation = 'landscape',
  }) async {
    try {
      // 1. Try specific query (e.g. "Eiffel Tower")
      String? url = await _fetchPhoto(query, orientation);
      if (url != null) return url;

      // 2. Try broader query (e.g. "Paris" if query was "Paris landmark")
      // If the query has multiple words, try the first word + "travel"
      if (query.contains(' ')) {
        final simpleQuery = query.split(' ').first;
        if (simpleQuery.length > 2) { // Avoid tiny words
           url = await _fetchPhoto('$simpleQuery travel', orientation);
           if (url != null) return url;
        }
      }

      // 3. Try very generic travel query if specific failed
      url = await _fetchPhoto('travel destination', orientation);
      if (url != null) return url;

      // 4. Last resort: Return a random fallback from our list
      return _fallbacks[DateTime.now().second % _fallbacks.length];

    } catch (e) {
      Helpers.log('Unsplash Error: $e', tag: 'UNSPLASH');
      // Return fallback on error so UI doesn't break
      return _fallbacks[0];
    }
  }

  Future<String?> _fetchPhoto(String query, String orientation) async {
    try {
      // Use 'search/photos' which is often more reliable than 'photos/random' for specific terms
      final response = await _dio.get('search/photos', queryParameters: {
        'query': query,
        'orientation': orientation,
        'per_page': 1,
        'page': 1,
        'content_filter': 'high', // Ensure appropriate content
      });

      if (response.statusCode == 200 && response.data['results'] != null) {
        final List results = response.data['results'];
        if (results.isNotEmpty) {
          // Prefer 'regular' size for balance of quality and speed
          return results[0]['urls']['regular'];
        }
      }
      return null;
    } catch (e) {
      // Don't log every 404/empty result to avoid spam, just return null to trigger fallback
      return null;
    }
  }

  // Get photo for destination (Wrapper)
  Future<String> getDestinationPhoto(String destination) async {
    // Add 'travel' to context to get better scenic shots
    return await getRandomPhoto(query: '$destination travel');
  }
}