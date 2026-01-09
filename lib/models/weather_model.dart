// lib/models/weather_model.dart

class WeatherModel {
  final String cityName;
  final double temperature;
  final String description;
  final String weatherCondition;
  final int humidity;
  final double windSpeed;
  final String icon;
  final DateTime timestamp;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.weatherCondition,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
    required this.timestamp,
  });

  // From JSON (OpenWeather API)
  factory WeatherModel.fromOpenWeatherJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? '',
      temperature: (json['main']?['temp'] ?? 0).toDouble(),
      description: json['weather']?[0]?['description'] ?? '',
      weatherCondition: json['weather']?[0]?['main'] ?? 'Clear',
      humidity: json['main']?['humidity'] ?? 0,
      windSpeed: (json['wind']?['speed'] ?? 0).toDouble(),
      icon: json['weather']?[0]?['icon'] ?? '01d',
      timestamp: DateTime.now(),
    );
  }

  // From JSON (Firebase/Local)
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['cityName'] ?? '',
      temperature: json['temperature'] ?? 0.0,
      description: json['description'] ?? '',
      weatherCondition: json['weatherCondition'] ?? '',
      humidity: json['humidity'] ?? 0,
      windSpeed: json['windSpeed'] ?? 0.0,
      icon: json['icon'] ?? '01d',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'cityName': cityName,
      'temperature': temperature,
      'description': description,
      'weatherCondition': weatherCondition,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'icon': icon,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Get temperature in Celsius
  int get temperatureCelsius => temperature.round();

  // Get temperature in Fahrenheit
  int get temperatureFahrenheit => ((temperature * 9 / 5) + 32).round();

  // Get weather icon URL
  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';

  // Get weather emoji
  String get weatherEmoji {
    switch (weatherCondition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  // Get formatted description
  String get formattedDescription {
    return '${description[0].toUpperCase()}${description.substring(1)}';
  }

  // Copy with
  WeatherModel copyWith({
    String? cityName,
    double? temperature,
    String? description,
    String? weatherCondition,
    int? humidity,
    double? windSpeed,
    String? icon,
    DateTime? timestamp,
  }) {
    return WeatherModel(
      cityName: cityName ?? this.cityName,
      temperature: temperature ?? this.temperature,
      description: description ?? this.description,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      icon: icon ?? this.icon,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'WeatherModel(city: $cityName, temp: ${temperatureCelsius}°C, condition: $weatherCondition)';
  }
}