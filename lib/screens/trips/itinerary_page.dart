// lib/screens/trips/itinerary_page.dart

import 'package:flutter/material.dart';
import '../../models/trip_model.dart';
import '../../services/firebase/firestore_service.dart';
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
  TripModel? _trip;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    try {
      final trip = await _firestoreService.getTrip(widget.tripId);
      if (mounted) setState(() { _trip = trip; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addActivity(int dayNumber) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddActivityPage(dayNumber: dayNumber)));
    if (result != null && result is ItineraryEvent && _trip != null) {
      final dayIndex = _trip!.itinerary.indexWhere((d) => d.dayNumber == dayNumber);
      if (dayIndex != -1) {
        final updatedEvents = [..._trip!.itinerary[dayIndex].events, result];
        final updatedItinerary = [..._trip!.itinerary];
        updatedItinerary[dayIndex] = _trip!.itinerary[dayIndex].copyWith(events: updatedEvents);
        final updatedTrip = _trip!.copyWith(itinerary: updatedItinerary);
        await _firestoreService.updateTrip(updatedTrip);
        setState(() => _trip = updatedTrip);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF13DAEC);
    final backgroundColor = isDark ? const Color(0xFF102022) : const Color(0xFFF6F8F8);
    final surfaceColor = isDark ? const Color(0xFF1A2C30) : Colors.white;
    final textMainColor = isDark ? Colors.white : const Color(0xFF0D1A1B);

    if (_isLoading) return const Scaffold(body: LoadingWidget());
    if (_trip == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text("Trip not found")));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: backgroundColor.withOpacity(0.9),
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.arrow_back, color: textMainColor), onPressed: () => Navigator.pop(context)),
                  Expanded(child: Text(_trip!.destination, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMainColor))),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _trip!.itinerary.length,
                itemBuilder: (context, index) {
                  final day = _trip!.itinerary[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Day ${day.dayNumber}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMainColor)),
                              Text(day.date, style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        if (day.events.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: TextButton.icon(
                              onPressed: () => _addActivity(day.dayNumber),
                              icon: Icon(Icons.add, color: primaryColor),
                              label: Text('Add Activity', style: TextStyle(color: primaryColor)),
                            ),
                          )
                        else
                          ...day.events.map((e) => ListTile(
                            leading: Icon(Icons.place, color: primaryColor),
                            title: Text(e.title, style: TextStyle(fontWeight: FontWeight.bold, color: textMainColor)),
                            subtitle: Text(e.time, style: TextStyle(color: Colors.grey)),
                          )).toList(),
                          if (day.events.isNotEmpty)
                            TextButton(onPressed: () => _addActivity(day.dayNumber), child: Text("Add Another", style: TextStyle(color: primaryColor))),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}