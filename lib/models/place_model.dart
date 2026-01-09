// lib/models/place_model.dart


class PlaceModel {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final double? rating;
  final String category;
  final String? country;
  final String? city;
  final List<String> tags;
  final bool isFree;
  final String? priceRange;
  final String? estimatedDuration;

  PlaceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.rating,
    required this.category,
    this.country,
    this.city,
    this.tags = const [],
    this.isFree = false,
    this.priceRange,
    this.estimatedDuration,
  });

  // Helper for UI to get a displayable location string
  String get location {
    if (city != null && country != null) {
      return '$city, $country';
    }
    return city ?? country ?? description; // Fallback
  }

  // --- From Nominatim (OpenStreetMap) ---
  factory PlaceModel.fromNominatimJson(Map<String, dynamic> json) {
    double lat = double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0;
    double lon = double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0;

    String displayName = json['display_name'] ?? 'Unknown Place';
    List<String> parts = displayName.split(',');
    
    String mainName = parts.isNotEmpty ? parts[0].trim() : displayName;
    String desc = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

    String category = json['type'] ?? json['class'] ?? 'Place';
    if (category.isNotEmpty) {
      category = "${category[0].toUpperCase()}${category.substring(1)}";
    }

    String? city;
    String? country;
    if (json['address'] != null) {
      city = json['address']['city'] ?? json['address']['town'] ?? json['address']['village'];
      country = json['address']['country'];
    }

    return PlaceModel(
      id: json['place_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: mainName,
      description: desc,
      latitude: lat,
      longitude: lon,
      imageUrl: null, 
      rating: 4.5, 
      category: category,
      country: country,
      city: city ?? desc, 
      tags: [json['class'] ?? 'general', json['type'] ?? 'place'],
      isFree: false, 
      priceRange: null,
      estimatedDuration: null,
    );
  }

  // From JSON (Firebase)
  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      imageUrl: json['imageUrl'],
      rating: json['rating'],
      category: json['category'] ?? '',
      country: json['country'],
      city: json['city'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      isFree: json['isFree'] ?? false,
      priceRange: json['priceRange'],
      estimatedDuration: json['estimatedDuration'],
    );
  }

  // To JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'rating': rating,
      'category': category,
      'country': country,
      'city': city,
      'tags': tags,
      'isFree': isFree,
      'priceRange': priceRange,
      'estimatedDuration': estimatedDuration,
    };
  }

  // CopyWith
  PlaceModel copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? imageUrl,
    double? rating,
    String? category,
    String? country,
    String? city,
    List<String>? tags,
    bool? isFree,
    String? priceRange,
    String? estimatedDuration,
  }) {
    return PlaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      category: category ?? this.category,
      country: country ?? this.country,
      city: city ?? this.city,
      tags: tags ?? this.tags,
      isFree: isFree ?? this.isFree,
      priceRange: priceRange ?? this.priceRange,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    );
  }
}