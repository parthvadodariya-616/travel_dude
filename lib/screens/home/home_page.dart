// lib/screens/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_planner/widgets/bottom_nav.dart';
import '../../models/place_model.dart';
import '../../providers/place_provider.dart';
import '../../utils/helpers.dart';
import '../places/place_detail_page.dart';
import '../places/place_list_page.dart';
import '../profile/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Removed _selectedIndex as it is handled by BottomNavBar widget
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch popular places on init
      Provider.of<PlaceProvider>(context, listen: false).searchPlaces('Tourist Attraction');
    });
  }

  // _onBottomNavTapped is handled by the global BottomNavBar widget

  void _handleSearch(String query) {
    if (query.trim().isEmpty) {
      Helpers.showSnackBar(context, 'Please enter a destination', isError: true);
      return;
    }
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => PlaceListPage(initialQuery: query.trim()))
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placeProvider = Provider.of<PlaceProvider>(context);
    
    // Take top 8 places for the popular section
    final List<PlaceModel> _popularPlaces = placeProvider.places.take(8).toList();
    final bool _isLoading = placeProvider.isLoading;
    final String? _error = placeProvider.error; // Use actual error from provider

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF13DAEC);
    final backgroundColor = isDark ? const Color(0xFF102022) : const Color(0xFFF6F8F8);
    final surfaceColor = isDark ? const Color(0xFF1A2C30) : Colors.white;
    final textMainColor = isDark ? Colors.white : const Color(0xFF0D1A1B);
    final textSubColor = isDark ? const Color(0xFF8FBABE) : const Color(0xFF4C939A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(color: backgroundColor.withOpacity(0.9)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Smart Travel Planner',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textMainColor),
                  ),
                  Container(
                    height: 40, width: 40,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
                        child: Icon(Icons.account_circle_outlined, color: textMainColor, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => await Provider.of<PlaceProvider>(context, listen: false).searchPlaces('Tourist Attraction'),
                color: primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Hero Image
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Container(
                          width: double.infinity,
                          height: 280,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=2070&auto=format&fit=crop',
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(color: Colors.grey[300], child: Center(child: CircularProgressIndicator(color: primaryColor)));
                                  },
                                  errorBuilder: (ctx, err, stack) => Container(
                                    color: primaryColor.withOpacity(0.1),
                                    child: Icon(Icons.photo, size: 80, color: primaryColor),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, backgroundColor.withOpacity(0.8)],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Headline
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Column(
                          children: [
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.2, color: textMainColor),
                                children: [
                                  const TextSpan(text: 'Plan your student\n'),
                                  TextSpan(text: 'break today.', style: TextStyle(color: primaryColor)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Discover affordable adventures worldwide.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textSubColor)),
                          ],
                        ),
                      ),

                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 8),
                                child: Icon(Icons.search, color: primaryColor, size: 24),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textMainColor),
                                  decoration: InputDecoration(
                                    hintText: 'London, Tokyo, New York...',
                                    hintStyle: TextStyle(color: textSubColor.withOpacity(0.7)),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  onSubmitted: _handleSearch,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Search Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => _handleSearch(_searchController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: const Color(0xFF0D1A1B),
                              elevation: 0,
                              shadowColor: primaryColor.withOpacity(0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Search Destinations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceListPage())),
                        child: Text('or browse all destinations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor)),
                      ),

                      // Popular Now Section
                      Padding(
                        padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Opacity(
                                  opacity: 0.8,
                                  child: Text('Popular Now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textMainColor)),
                                ),
                                IconButton(
                                  icon: Icon(Icons.refresh, color: primaryColor),
                                  onPressed: () => Provider.of<PlaceProvider>(context, listen: false).searchPlaces('Tourist Attraction'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildPopularSection(isDark, primaryColor, surfaceColor, textMainColor, _popularPlaces, _isLoading, _error),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Use Global Bottom Nav Bar (index 0 for Home)
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildPopularSection(bool isDark, Color primaryColor, Color surfaceColor, Color textMainColor, List<PlaceModel> popularPlaces, bool isLoading, String? error) {
    if (isLoading) {
      return SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          itemBuilder: (ctx, index) => Container(
            width: 120, margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: isDark ? Colors.grey[800] : Colors.grey[300], borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    if (error != null) return Text(error, style: TextStyle(color: Colors.red[700]));

    final placesToShow = popularPlaces.isNotEmpty ? popularPlaces : []; 

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: placesToShow.length,
        itemBuilder: (ctx, index) {
          final place = placesToShow[index];
          return _buildChip(
            place.name,
            primaryColor,
            surfaceColor,
            isDark,
            onTap: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => PlaceDetailPage(place: place))
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, Color primaryColor, Color surfaceColor, bool isDark, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}