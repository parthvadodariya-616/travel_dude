// lib/screens/places/place_list_page.dart

import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_planner/widgets/bottom_nav.dart';
import '../../models/place_model.dart';
import '../../providers/place_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/place_card.dart'; // Import Global Nav

import '../home/home_page.dart';
import 'place_detail_page.dart';

class PlaceListPage extends StatefulWidget {
  final String? initialQuery;
  
  const PlaceListPage({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<PlaceListPage> createState() => _PlaceListPageState();
}

class _PlaceListPageState extends State<PlaceListPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final List<String> _filters = ['All', 'Nature', 'City', 'Historical', 'Trending'];
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final placeProvider = Provider.of<PlaceProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        placeProvider.loadBookmarks(authProvider.user!.id);
      }

      if (widget.initialQuery != null) {
        _searchController.text = widget.initialQuery!;
        placeProvider.searchPlaces(widget.initialQuery!);
      } else {
        if (placeProvider.places.isEmpty) {
           placeProvider.searchPlaces("Tourist Attraction");
        }
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      if (query.length > 2) {
        Provider.of<PlaceProvider>(context, listen: false).searchPlaces(query);
      }
    });
  }

  void _onFilterSelected(int index) {
    setState(() => _selectedFilterIndex = index);
    String query = _filters[index] == 'All' ? 'Tourist Attraction' : '${_filters[index]} landmarks';
    if (_searchController.text.isNotEmpty) {
      query = '${_searchController.text} ${_filters[index]}';
    }
    Provider.of<PlaceProvider>(context, listen: false).searchPlaces(query);
  }

  void _toggleBookmark(PlaceModel place) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final placeProvider = Provider.of<PlaceProvider>(context, listen: false);

    if (authProvider.user == null) {
      Helpers.showSnackBar(context, 'Please login to bookmark places', isError: true);
      return;
    }

    placeProvider.toggleBookmark(authProvider.user!.id, place);
    Helpers.showSnackBar(context, placeProvider.isBookmarked(place.id) ? 'Bookmark removed' : 'Place bookmarked!');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placeProvider = Provider.of<PlaceProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = isDark ? const Color(0xFF1A2C30) : Colors.white;
    final textMainColor = isDark ? Colors.white : const Color(0xFF0D1A1B);
    final textSubColor = isDark ? const Color(0xFF8FBABE) : const Color(0xFF4C939A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(color: backgroundColor.withOpacity(0.9)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Explore Places', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textMainColor)),
                      IconButton(
                        onPressed: () {
                           if (Provider.of<AuthProvider>(context, listen: false).user != null) {
                             placeProvider.loadBookmarks(Provider.of<AuthProvider>(context, listen: false).user!.id);
                           }
                        },
                        icon: Icon(Icons.refresh, color: primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
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
                            onChanged: _onSearchChanged,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textMainColor),
                            decoration: InputDecoration(
                              hintText: 'Type to search...',
                              hintStyle: TextStyle(color: textSubColor.withOpacity(0.7)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onSubmitted: (value) {
                               if(value.isNotEmpty) placeProvider.searchPlaces(value);
                            },
                          ),
                        ),
                        if (placeProvider.isLoading)
                           Padding(
                             padding: const EdgeInsets.only(right: 16),
                             child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)),
                           )
                        else
                          IconButton(
                            onPressed: () {
                              if (_searchController.text.isNotEmpty) placeProvider.searchPlaces(_searchController.text);
                            },
                            icon: Icon(Icons.send, color: primaryColor, size: 20),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Material(
                      color: isSelected ? primaryColor : surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => _onFilterSelected(index),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.black : textMainColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _buildContent(placeProvider, isDark, primaryColor, textMainColor, textSubColor),
            ),
          ],
        ),
      ),
      // Use Global Bottom Nav Bar
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildContent(PlaceProvider placeProvider, bool isDark, Color primaryColor, Color textMainColor, Color textSubColor) {
    if (placeProvider.isLoading && placeProvider.places.isEmpty) {
      return ListShimmer(shimmerItem: const PlaceCardShimmer(), itemCount: 5);
    }

    if (placeProvider.error != null) {
      return ErrorDisplayWidget(
        message: placeProvider.error!, 
        onRetry: () => placeProvider.searchPlaces(_searchController.text.isNotEmpty ? _searchController.text : "Tourist Attraction")
      );
    }

    if (placeProvider.places.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.travel_explore,
        title: 'No Places Found',
        message: 'Try a different keyword',
        buttonText: 'Reset',
        onButtonPressed: () {
          _searchController.clear();
          placeProvider.searchPlaces('Tourist Attraction');
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: placeProvider.places.length,
      itemBuilder: (context, index) {
        final place = placeProvider.places[index];
        final isBookmarked = placeProvider.isBookmarked(place.id);
        return PlaceCard(
          place: place,
          isBookmarked: isBookmarked,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailPage(place: place))),
          onBookmark: () => _toggleBookmark(place),
        );
      },
    );
  }
}