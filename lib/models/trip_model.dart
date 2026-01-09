// lib/models/trip_model.dart

class TripModel {
  final String id;
  final String userId;
  final String destination;
  final String? destinationCountry;
  final DateTime startDate;
  final DateTime endDate;
  final double? budget;
  final double spent; // NEW PARAMETER
  final String status; // NEW PARAMETER (upcoming, ongoing, completed, cancelled)
  final String? budgetSaved;
  final int travelers;
  final String? tripType;
  final String? imageUrl;
  final double? rating;
  final String? badge;
  final List<ItineraryDay> itinerary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  TripModel({
    required this.id,
    required this.userId,
    required this.destination,
    this.destinationCountry,
    required this.startDate,
    required this.endDate,
    this.budget,
    this.spent = 0.0, // NEW PARAMETER with default value
    this.status = 'upcoming', // NEW PARAMETER with default value
    this.budgetSaved,
    this.travelers = 1,
    this.tripType,
    this.imageUrl,
    this.rating,
    this.badge,
    this.itinerary = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  // Get trip duration in days
  int get durationDays {
    return endDate.difference(startDate).inDays + 1;
  }

  // Get formatted date range
  String get dateRange {
    final start = '${startDate.month}/${startDate.day}';
    final end = '${endDate.month}/${endDate.day}';
    return '$start - $end';
  }

  // Get budget remaining
  double get budgetRemaining {
    if (budget == null) return 0.0;
    return budget! - spent;
  }

  // Get budget spent percentage
  double get budgetSpentPercentage {
    if (budget == null || budget == 0) return 0.0;
    return (spent / budget!) * 100;
  }

  // Get budget saved percentage (legacy support)
  double get budgetSavedPercentage {
    if (budgetSaved == null || budget == null || budget == 0) return 0.0;
    try {
      final saved = double.parse(budgetSaved!.replaceAll(RegExp(r'[^0-9.]'), ''));
      return saved / budget!;
    } catch (e) {
      return 0.0;
    }
  }

  // Check if trip is active/ongoing
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  // Check if trip is upcoming
  bool get isUpcoming {
    return DateTime.now().isBefore(startDate);
  }

  // Check if trip is completed
  bool get isCompleted {
    return DateTime.now().isAfter(endDate);
  }

  // From JSON (Firebase)
  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      destination: json['destination'] ?? '',
      destinationCountry: json['destinationCountry'],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now(),
      budget: json['budget'] != null ? (json['budget'] as num).toDouble() : null,
      spent: json['spent'] != null ? (json['spent'] as num).toDouble() : 0.0,
      status: json['status'] ?? 'upcoming',
      budgetSaved: json['budgetSaved'],
      travelers: json['travelers'] ?? 1,
      tripType: json['tripType'],
      imageUrl: json['imageUrl'],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      badge: json['badge'],
      itinerary: json['itinerary'] != null
          ? (json['itinerary'] as List)
              .map((item) => ItineraryDay.fromJson(item))
              .toList()
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      isSynced: json['isSynced'] ?? false,
    );
  }

  // To JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'destination': destination,
      'destinationCountry': destinationCountry,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'budget': budget,
      'spent': spent,
      'status': status,
      'budgetSaved': budgetSaved,
      'travelers': travelers,
      'tripType': tripType,
      'imageUrl': imageUrl,
      'rating': rating,
      'badge': badge,
      'itinerary': itinerary.map((day) => day.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  // Copy with
  TripModel copyWith({
    String? id,
    String? userId,
    String? destination,
    String? destinationCountry,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    double? spent,
    String? status,
    String? budgetSaved,
    int? travelers,
    String? tripType,
    String? imageUrl,
    double? rating,
    String? badge,
    List<ItineraryDay>? itinerary,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return TripModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      destination: destination ?? this.destination,
      destinationCountry: destinationCountry ?? this.destinationCountry,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      status: status ?? this.status,
      budgetSaved: budgetSaved ?? this.budgetSaved,
      travelers: travelers ?? this.travelers,
      tripType: tripType ?? this.tripType,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      badge: badge ?? this.badge,
      itinerary: itinerary ?? this.itinerary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() {
    return 'TripModel(id: $id, destination: $destination, days: $durationDays, status: $status)';
  }
}

// Itinerary Day Model
class ItineraryDay {
  final int dayNumber;
  final String date;
  final String? weather;
  final int? temperature;
  final List<ItineraryEvent> events;

  ItineraryDay({
    required this.dayNumber,
    required this.date,
    this.weather,
    this.temperature,
    this.events = const [],
  });

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    return ItineraryDay(
      dayNumber: json['dayNumber'] ?? 1,
      date: json['date'] ?? '',
      weather: json['weather'],
      temperature: json['temperature'],
      events: json['events'] != null
          ? (json['events'] as List)
              .map((item) => ItineraryEvent.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'date': date,
      'weather': weather,
      'temperature': temperature,
      'events': events.map((event) => event.toJson()).toList(),
    };
  }

  // Copy with method for updating events
  ItineraryDay copyWith({
    int? dayNumber,
    String? date,
    String? weather,
    int? temperature,
    List<ItineraryEvent>? events,
  }) {
    return ItineraryDay(
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      weather: weather ?? this.weather,
      temperature: temperature ?? this.temperature,
      events: events ?? this.events,
    );
  }
}

// Itinerary Event Model
class ItineraryEvent {
  final String title;
  final String subtitle;
  final String time;
  final String icon;
  final bool isHighlighted;
  final String? tag;

  ItineraryEvent({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    this.isHighlighted = false,
    this.tag,
  });

  factory ItineraryEvent.fromJson(Map<String, dynamic> json) {
    return ItineraryEvent(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      time: json['time'] ?? '',
      icon: json['icon'] ?? 'place',
      isHighlighted: json['isHighlighted'] ?? false,
      tag: json['tag'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'time': time,
      'icon': icon,
      'isHighlighted': isHighlighted,
      'tag': tag,
    };
  }

  // Copy with method
  ItineraryEvent copyWith({
    String? title,
    String? subtitle,
    String? time,
    String? icon,
    bool? isHighlighted,
    String? tag,
  }) {
    return ItineraryEvent(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      time: time ?? this.time,
      icon: icon ?? this.icon,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      tag: tag ?? this.tag,
    );
  }
}