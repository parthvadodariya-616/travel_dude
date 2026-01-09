// lib/services/api/weather_service.dart

import 'package:dio/dio.dart';
import '../../config/constants.dart';
import '../../models/weather_model.dart';
import '../../utils/helpers.dart';

class WeatherService {
  final Dio _dio;

  WeatherService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.openWeatherBaseUrl,
            connectTimeout: Duration(seconds: AppConstants.connectionTimeout),
            receiveTimeout: Duration(seconds: AppConstants.receiveTimeout),
          ),
        );

  // Get current weather by city name
  Future<WeatherModel?> getWeatherByCity(String cityName) async {
    try {
      Helpers.log('Getting weather for: $cityName', tag: 'WEATHER');

      final response = await _dio.get('weather', queryParameters: {
        'q': cityName,
        'appid': AppConstants.openWeatherApiKey,
        'units': 'metric', // Celsius
      });

      if (response.statusCode == 200) {
        return WeatherModel.fromOpenWeatherJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      Helpers.log('Error getting weather: ${e.message}', tag: 'WEATHER');
      throw _handleError(e);
    } catch (e) {
      Helpers.log('Unexpected error: $e', tag: 'WEATHER');
      throw 'Failed to get weather data';
    }
  }

  // Get current weather by coordinates
  Future<WeatherModel?> getWeatherByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      Helpers.log('Getting weather for coordinates', tag: 'WEATHER');

      final response = await _dio.get('weather', queryParameters: {
        'lat': latitude,
        'lon': longitude,
        'appid': AppConstants.openWeatherApiKey,
        'units': 'metric',
      });

      if (response.statusCode == 200) {
        return WeatherModel.fromOpenWeatherJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      Helpers.log('Error getting weather: ${e.message}', tag: 'WEATHER');
      throw _handleError(e);
    } catch (e) {
      Helpers.log('Unexpected error: $e', tag: 'WEATHER');
      throw 'Failed to get weather data';
    }
  }

  // Get 5-day weather forecast
  Future<List<WeatherModel>> getWeatherForecast(String cityName) async {
    try {
      Helpers.log('Getting forecast for: $cityName', tag: 'WEATHER');

      final response = await _dio.get('forecast', queryParameters: {
        'q': cityName,
        'appid': AppConstants.openWeatherApiKey,
        'units': 'metric',
        'cnt': 5, // 5 days
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['list'] != null) {
          return (data['list'] as List)
              .map((json) => WeatherModel.fromOpenWeatherJson(json))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      Helpers.log('Error getting forecast: ${e.message}', tag: 'WEATHER');
      throw _handleError(e);
    } catch (e) {
      Helpers.log('Unexpected error: $e', tag: 'WEATHER');
      throw 'Failed to get weather forecast';
    }
  }

  // Handle errors
  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Request timeout. Please try again.';
    } else if (e.type == DioExceptionType.badResponse) {
      if (e.response?.statusCode == 404) {
        return 'City not found. Please check the spelling.';
      }
      return 'Server error. Please try again later.';
    } else if (e.type == DioExceptionType.unknown) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}