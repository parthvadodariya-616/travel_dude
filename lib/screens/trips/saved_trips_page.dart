import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_dude/widgets/bottom_nav.dart';
import '../../providers/trip_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/trip_card.dart';
import '../../widgets/loading_widget.dart';
import '../home/home_page.dart';
import 'create_trip_page.dart';
import 'itinerary_page.dart';

class SavedTripsPage extends StatefulWidget {
  const SavedTripsPage({Key? key}) : super(key: key);

  @override
  State<SavedTripsPage> createState() => _SavedTripsPageState();
}

class _SavedTripsPageState extends State<SavedTripsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
      if (userId != null) {
        Provider.of<TripProvider>(context, listen: false).loadTrips(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    final user = Provider.of<AuthProvider>(context).user;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textMainColor = isDark ? Colors.white : const Color(0xFF0D1A1B);
    final textSubColor = isDark ? const Color(0xFF8FBABE) : const Color(0xFF4C939A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              color: backgroundColor.withOpacity(0.9),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage())),
                    icon: Icon(Icons.arrow_back, color: textMainColor),
                  ),
                  Expanded(
                    child: Text('My Trips', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textMainColor)),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: primaryColor),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTripPage())),
                  ),
                ],
              ),
            ),

            Expanded(
              child: user == null
                  ? Center(child: Text('Please login to see your trips', style: TextStyle(color: textSubColor)))
                  : tripProvider.isLoading
                      ? const LoadingWidget()
                      : tripProvider.trips.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.flight_takeoff,
                              title: 'No Trips Yet',
                              message: 'Start planning your next adventure!',
                              buttonText: 'Create Trip',
                              onButtonPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTripPage())),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              itemCount: tripProvider.trips.length,
                              itemBuilder: (ctx, index) {
                                final trip = tripProvider.trips[index];
                                return TripCard(
                                  trip: trip,
                                  onTap: () => Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (_) => ItineraryPage(tripId: trip.id))
                                  ),
                                  onDelete: () => tripProvider.deleteTrip(trip.id),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}