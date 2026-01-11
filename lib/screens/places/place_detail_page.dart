// lib/screens/places/place_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
import 'package:url_launcher/url_launcher.dart'; // Required for opening external maps
import '../../models/place_model.dart';
import '../../models/weather_model.dart';
import '../../services/api/weather_service.dart';
import '../trips/create_trip_page.dart';

class PlaceDetailPage extends StatefulWidget {
  final PlaceModel place;

  const PlaceDetailPage({Key? key, required this.place}) : super(key: key);

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  final WeatherService _weatherService = WeatherService();
  WeatherModel? _weather;
  bool _isLoadingWeather = true;
  bool isFavorite = false;
  bool isExpanded = false;

  // Track map theme state
  bool _isSatelliteView = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final query = widget.place.city ?? widget.place.name;
      final weather = await _weatherService.getWeatherByCityName(query);
      
      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
      print("Error loading weather: $e");
    }
  }

  // --- NEW: Helper to Open Google Maps ---
  Future<void> _openGoogleMaps() async {
    final double lat = widget.place.latitude;
    final double lng = widget.place.longitude;
    // Uses the universal Google Maps URL format (works on Android/iOS/Web)
    final Uri googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: Could show a snackbar here if desired
      print('Could not launch Google Maps');
    }
  }

  // --- MAP FUNCTIONALITY ---
  void _showMap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Use StatefulBuilder to handle local state (Theme Switching) inside the modal
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85, 
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle Bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.place.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.white 
                                      : Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _isSatelliteView ? "Satellite View" : "Street View",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  
                  // The Map with Overlaid Buttons
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(widget.place.latitude, widget.place.longitude),
                              initialZoom: 15.0,
                              minZoom: 3.0,
                              maxZoom: 18.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all,
                              ),
                            ),
                            children: [
                              TileLayer(
                                // Switch between OSM (Default) and Esri (Satellite)
                                urlTemplate: _isSatelliteView
                                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.smarttravelplanner.app',
                                // Attribution for Satellite
                                tileProvider: NetworkTileProvider(),
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(widget.place.latitude, widget.place.longitude),
                                    width: 80,
                                    height: 80,
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.redAccent,
                                          size: 40,
                                        ),
                                        if (!_isSatelliteView) // Hide label in satellite if it's too cluttered
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                                            ),
                                            child: Text(
                                              widget.place.name,
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // Copyright attribution (Good practice)
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  color: Colors.black.withOpacity(0.5),
                                  child: Text(
                                    _isSatelliteView ? 'Esri, Maxar, Earthstar Geographics' : '© OpenStreetMap contributors',
                                    style: const TextStyle(color: Colors.white, fontSize: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // --- BUTTON 1: Theme Switcher (Satellite/Default) ---
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Column(
                              children: [
                                Material(
                                  elevation: 4,
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  color: Colors.white,
                                  child: InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        _isSatelliteView = !_isSatelliteView;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Icon(
                                        _isSatelliteView ? Icons.layers_clear : Icons.layers,
                                        color: Colors.black87,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Label for the button (optional)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _isSatelliteView ? 'Default' : 'Satellite',
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // --- BUTTON 2: Get Directions (Google Maps) ---
                          Positioned(
                            bottom: 24,
                            right: 16,
                            child: FloatingActionButton.extended(
                              onPressed: _openGoogleMaps,
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              icon: const Icon(Icons.directions),
                              label: const Text('Directions'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Standard build method (same as before)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF13DAEC);
    final backgroundColor = isDark ? const Color(0xFF102022) : const Color(0xFFF6F8F8);
    final textMainColor = isDark ? Colors.white : const Color(0xFF0D1A1B);
    final textSubColor = isDark ? const Color(0xFF8FBABE) : const Color(0xFF4C939A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.45,
                pinned: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              isFavorite = !isFavorite;
                            });
                          },
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.place.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.place.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: primaryColor.withOpacity(0.2),
                                child: Icon(Icons.photo, size: 80, color: primaryColor),
                              ),
                              placeholder: (context, url) => Container(color: Colors.grey[300]),
                            )
                          : Container(
                              color: primaryColor.withOpacity(0.2),
                              child: Icon(Icons.photo, size: 80, color: primaryColor),
                            ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 32,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (widget.place.country ?? 'Unknown').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.place.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.place.location,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.place.rating != null) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.place.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0, -16, 0),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWeatherWidget(isDark, primaryColor, textMainColor, textSubColor),
                        const SizedBox(height: 24),
                        _buildTagChips(isDark, primaryColor, textMainColor, textSubColor),
                        const SizedBox(height: 24),
                        _buildDescription(isDark, primaryColor, textMainColor, textSubColor),
                        const SizedBox(height: 24),
                        _buildMapPreview(isDark, primaryColor),
                        const SizedBox(height: 24),
                        _buildBestTimeInfo(isDark, primaryColor, textMainColor, textSubColor),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF102022).withOpacity(0.8)
                    : Colors.white.withOpacity(0.8),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                           Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateTripPage(initialPlace: widget.place),
                              ),
                            );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: primaryColor.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.calendar_month, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Add to Itinerary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 100,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... (Keep existing _buildWeatherWidget, _buildTagChips, _buildDescription, _buildBestTimeInfo)
  Widget _buildWeatherWidget(bool isDark, Color primaryColor, Color textMain, Color textSub) {
    if (_isLoadingWeather) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_weather == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Text("Weather information unavailable", style: TextStyle(color: textSub)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT WEATHER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${_weather!.temperatureCelsius}°C',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _weather!.formattedDescription,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSub,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _weather!.weatherEmoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChips(bool isDark, Color primaryColor, Color textMain, Color textSub) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(widget.place.category, Icons.category, primaryColor, true, isDark, textMain, textSub),
        if (widget.place.priceRange != null)
           _buildChip(widget.place.priceRange!, Icons.attach_money, Colors.grey, false, isDark, textMain, textSub),
      ],
    );
  }

  Widget _buildChip(
    String label,
    IconData icon,
    Color color,
    bool isPrimary,
    bool isDark,
    Color textMain,
    Color textSub,
  ) {
    final primaryColor = const Color(0xFF13DAEC);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary
            ? primaryColor.withOpacity(0.1)
            : (isDark ? Colors.grey[800] : Colors.grey[100]),
        border: isPrimary
            ? Border.all(color: primaryColor.withOpacity(0.2), width: 1)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isPrimary
                ? primaryColor
                : (isDark ? Colors.grey[300] : Colors.grey[600]),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
              color: isPrimary
                  ? primaryColor
                  : (isDark ? Colors.grey[300] : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(bool isDark, Color primaryColor, Color textMain, Color textSub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textMain,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.place.description.isNotEmpty ? widget.place.description : 'No description available.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: textSub,
          ),
          maxLines: isExpanded ? null : 3,
          overflow: isExpanded ? null : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Row(
            children: [
              Text(
                isExpanded ? 'Read less' : 'Read more',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreview(bool isDark, Color primaryColor) {
    return GestureDetector(
      onTap: _showMap,
      child: Container(
        height: 140, 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(widget.place.latitude, widget.place.longitude),
                    initialZoom: 13.0, 
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.smarttravelplanner.app',
                    ),
                    MarkerLayer(
                      markers: [
                         Marker(
                          point: LatLng(widget.place.latitude, widget.place.longitude),
                          width: 60,
                          height: 60,
                          child: Icon(
                            Icons.location_on,
                            color: primaryColor,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Center(
                child: ElevatedButton.icon(
                  onPressed: _showMap,
                  icon: Icon(
                    Icons.map,
                    size: 18,
                    color: primaryColor,
                  ),
                  label: Text(
                    'View on Map',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    elevation: 8,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBestTimeInfo(bool isDark, Color primaryColor, Color textMain, Color textSub) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152628) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: isDark
            ? null
            : Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best time to visit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Early morning around 7:00 AM to avoid crowds.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}