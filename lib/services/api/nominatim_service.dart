// lib/services/api/nominatim_service.dart

import 'package:dio/dio.dart';
import '../../config/constants.dart';
import '../../models/place_model.dart';

class NominatimService {
  final Dio _dio;

  NominatimService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: '', // Full URL used in requests
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            headers: {
              // REQUIRED by OpenStreetMap: Identify your app
              'User-Agent': 'SmartTravelPlanner_StudentApp/1.0',
            },
          ),
        );

  Future<List<PlaceModel>> searchPlaces({required String query}) async {
    try {
      final response = await _dio.get(
        AppConstants.nominatimBaseUrl,
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1, // Get city/country info
          'limit': 15,         // Max results
          'extratags': 1,      // Get category info
          'accept-language': 'en', // Force English results
        },
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((json) {
          try {
            return PlaceModel.fromNominatimJson(json);
          } catch (e) {
            print('Parsing error for item: $e');
            return null;
          }
        }).whereType<PlaceModel>().toList();
      }
      return [];
    } catch (e) {
      throw 'Failed to connect to search service.';
    }
  }
}