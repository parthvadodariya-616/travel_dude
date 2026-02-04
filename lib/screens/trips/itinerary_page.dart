// lib/screens/trips/itinerary_page.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/trip_model.dart';
import '../../models/place_model.dart';
import '../../services/firebase/firestore_service.dart';
import '../../services/api/weather_service.dart';
import '../../models/weather_model.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_widget.dart';
import 'add_activity_page.dart';

class ItineraryPage extends StatefulWidget {
  final String tripId;

  const ItineraryPage({Key? key, required this.tripId}) : super(key: key);

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final WeatherService _weatherService = WeatherService();
  
  TripModel? _trip;
  WeatherModel? _tripWeather; 
  Map<int, WeatherModel?> _dailyWeather = {}; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    try {
      final trip = await _firestoreService.getTrip(widget.tripId);
      if (mounted) {
        setState(() {
          _trip = trip;
          _isLoading = false;
        });
        if (trip != null) {
          // 1. Fetch main trip weather
          _loadMainWeather(trip.destination);
          
          // 2. Try to fetch weather for specific days based on activity locations
          _loadDailyWeather(trip);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMainWeather(String destination) async {
    try {
      final weather = await _weatherService.getWeatherByCityName(destination); 
      if (mounted) {
        setState(() {
          _tripWeather = weather;
        });
      }
    } catch (e) {
      print("Main Weather load error: $e");
    }
  }

  Future<void> _loadDailyWeather(TripModel trip) async {
    for (var day in trip.itinerary) {
      if (day.events.isNotEmpty) {
        final locationQuery = day.events.first.subtitle;
        if (locationQuery.isNotEmpty && locationQuery.contains(',')) {
             try {
               final weather = await _weatherService.getWeatherByCityName(locationQuery.split(',').first);
               if (mounted && weather != null) {
                 setState(() {
                   _dailyWeather[day.dayNumber] = weather;
                 });
               }
             } catch (e) {
               // Ignore
             }
        }
      }
    }
  }

  Future<void> _addActivity(int dayNumber) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddActivityPage(
          dayNumber: dayNumber,
          totalDays: _trip?.durationDays ?? 7,
        ),
      ),
    );

    if (result != null && result is Map) {
      final event = result['event'] as ItineraryEvent;
      final targetDay = result['day'] as int;
      final place = result['place'] as PlaceModel?; 

      if (_trip == null) return;

      final dayIndex = _trip!.itinerary.indexWhere((d) => d.dayNumber == targetDay);
      
      if (dayIndex != -1) {
        final updatedEvents = [..._trip!.itinerary[dayIndex].events, event];
        final updatedDay = _trip!.itinerary[dayIndex].copyWith(events: updatedEvents);
        
        final updatedItinerary = [..._trip!.itinerary];
        updatedItinerary[dayIndex] = updatedDay;
        
        String? newImageUrl = _trip!.imageUrl;
        if (place?.imageUrl != null && (newImageUrl == null || newImageUrl.isEmpty)) {
           newImageUrl = place!.imageUrl;
        }

        final updatedTrip = _trip!.copyWith(
          itinerary: updatedItinerary,
          imageUrl: newImageUrl,
          updatedAt: DateTime.now(),
        );
        
        try {
          await _firestoreService.updateTrip(updatedTrip);
          if (mounted) {
            setState(() => _trip = updatedTrip);
            if (place != null) {
               _weatherService.getWeatherByCityName(place.name).then((w) {
                 if (mounted && w != null) {
                   setState(() {
                     _dailyWeather[targetDay] = w;
                   });
                 }
               });
            }
            Helpers.showSnackBar(context, 'Plan added to Day $targetDay');
          }
        } catch (e) {
          if (mounted) Helpers.showSnackBar(context, 'Failed to add plan', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF13DAEC);
    final backgroundColor = isDark ? const Color(0xFF102022) : const Color(0xFFF6F8F8);
    final cardColor = isDark ? const Color(0xFF1A2C30) : Colors.white;
    final textMainColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSubColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (_isLoading) return const Scaffold(body: LoadingWidget());
    if (_trip == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text("Trip not found")));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(isDark, backgroundColor, borderColor, textMainColor),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTrip,
                color: primaryColor,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    _buildHeroCard(isDark, primaryColor, textSubColor),
                    const SizedBox(height: 24),
                    ..._trip!.itinerary.map((day) {
                    final dayWeather = _dailyWeather[day.dayNumber];
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDayCard(
                          dayNumber: day.dayNumber,
                          dayLabel: 'Day ${day.dayNumber}',
                          date: day.date,
                          // If no weather, show empty string instead of default cloud
                          weatherEmoji: dayWeather?.weatherEmoji ?? '', 
                          // If no weather, show '--'
                          temperature: dayWeather != null ? '${dayWeather.temperatureCelsius}°C' : '--',
                          weatherColor: Colors.orange,
                          events: day.events,
                          isDark: isDark,
                          cardColor: cardColor,
                          primaryColor: primaryColor,
                          textMainColor: textMainColor,
                          textSubColor: textSubColor,
                          borderColor: borderColor,
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    _buildAddMoreButton(isDark, borderColor, textSubColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(primaryColor),
    );
  }

  // ... (Helpers)
  
  Widget _buildHeader(bool isDark, Color backgroundColor, Color borderColor, Color textMainColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.9),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
            color: textMainColor,
          ),
          Expanded(
            child: Text(
              _trip!.destination,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textMainColor),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadTrip,
            color: textMainColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(bool isDark, Color primaryColor, Color textSubColor) {
    return Container(
      height: 192,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            _trip!.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: _trip!.imageUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_,__) => Container(color: Colors.grey[300]),
                    errorWidget: (_,__,___) => Container(color: Colors.grey[300], child: Icon(Icons.image, color: textSubColor)),
                  )
                : Container(color: Colors.grey[300], child: Center(child: Icon(Icons.image, size: 48, color: textSubColor))),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
            Positioned(
              left: 16, right: 16, bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: primaryColor.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
                        child: Text(_trip!.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0D1A1B))),
                      ),
                      const SizedBox(width: 8),
                      Text('\$${_trip!.budget?.toInt() ?? 0} Budget', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_trip!.destination, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 16, color: Colors.white70),
                      const SizedBox(width: 8),
                      Text('${Helpers.formatDate(_trip!.startDate)} - ${Helpers.formatDate(_trip!.endDate)}', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard({
    required int dayNumber,
    required String dayLabel,
    required String date,
    required String weatherEmoji,
    required String temperature,
    required Color weatherColor,
    required List<ItineraryEvent> events,
    required bool isDark,
    required Color cardColor,
    required Color primaryColor,
    required Color textMainColor,
    required Color textSubColor,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.calendar_today, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dayLabel, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textMainColor)),
                        Text(date, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSubColor)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: weatherColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: weatherColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      // Only show emoji if we have one
                      if (weatherEmoji.isNotEmpty) ...[
                        Text(weatherEmoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                      ],
                      Text(temperature, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: weatherColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => _addActivity(dayNumber),
                  icon: Icon(Icons.add_circle_outline, color: primaryColor),
                  label: Text('Add first plan', style: TextStyle(color: primaryColor)),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: events.asMap().entries.map((entry) {
                  final index = entry.key;
                  final event = entry.value;
                  final isLast = index == events.length - 1;
                  return _buildTimelineEvent(
                    icon: _getIconData(event.icon),
                    title: event.title,
                    subtitle: event.subtitle,
                    time: event.time,
                    isHighlighted: true,
                    isLast: isLast,
                    isDark: isDark,
                    textMainColor: textMainColor,
                    textSubColor: textSubColor,
                    borderColor: borderColor,
                    primaryColor: primaryColor,
                  );
                }).toList(),
              ),
            ),
            
            if (events.isNotEmpty)
              InkWell(
                onTap: () => _addActivity(dayNumber),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: borderColor.withOpacity(0.3)))),
                  child: Center(child: Text("+ Add Plan", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor))),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildTimelineEvent({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required bool isHighlighted,
    required bool isLast,
    required bool isDark,
    required Color textMainColor,
    required Color textSubColor,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Icon(icon, color: isHighlighted ? primaryColor : textSubColor, size: 24),
              if (!isLast)
                Container(width: 2, height: 60, color: borderColor, margin: const EdgeInsets.only(top: 4)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: borderColor.withOpacity(0.3)))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textMainColor)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: textSubColor)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHighlighted ? primaryColor.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(time, style: TextStyle(fontSize: 13, fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500, color: isHighlighted ? primaryColor : textSubColor)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddMoreButton(bool isDark, Color borderColor, Color textSubColor) {
    return InkWell(
      onTap: () => _addActivity(1), 
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), shape: BoxShape.circle),
              child: Icon(Icons.add, color: textSubColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text('Add Another Day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textSubColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(Color primaryColor) {
    return FloatingActionButton(
      onPressed: () => _addActivity(1),
      backgroundColor: primaryColor,
      child: const Icon(Icons.add, color: Color(0xFF0D1A1B)),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'place': return Icons.place;
      case 'restaurant': return Icons.restaurant;
      case 'commute': return Icons.directions_bus;
      case 'shopping_bag': return Icons.shopping_bag;
      default: return Icons.star;
    }
  }
}