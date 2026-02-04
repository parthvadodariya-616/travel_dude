// lib/screens/places/place_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
import 'package:url_launcher/url_launcher.dart';
import '../../models/place_model.dart';
import '../../models/weather_model.dart';
import '../../services/api/weather_service.dart';
import '../../utils/helpers.dart';
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
      Helpers.log("Error loading weather: $e", tag: 'WEATHER');
    }
  }

  // --- FIXED: Reliable Method to Open Google Maps ---
 Future<void> _openGoogleMaps() async {
  // Construct the search query using name and address/location
  final String query = Uri.encodeComponent("${widget.place.name}, ${widget.place.location}");
  
  // Use the Google Maps Search API URL
  final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$query";
  final Uri uri = Uri.parse(googleMapsUrl);

  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        Helpers.showSnackBar(context, 'Could not launch Google Maps', isError: true);
      }
    }
  } catch (e) {
    Helpers.log('Error launching maps: $e', tag: 'MAPS');
  }
}
  void _showMap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false, 
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
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
                  
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(widget.place.latitude, widget.place.longitude),
                              initialZoom: 15.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: _isSatelliteView
                                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.parth.io.task.smartTravelPlanner',
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
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.redAccent,
                                          size: 40,
                                        ),
                                        if (!_isSatelliteView)
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
                            ],
                          ),

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
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                        ),
                        onPressed: () => setState(() => isFavorite = !isFavorite),
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
                                child: const Icon(Icons.photo, size: 80, color: Color(0xFF13DAEC)),
                              ),
                              placeholder: (context, url) => Container(color: Colors.grey[300]),
                            )
                          : Container(
                              color: primaryColor.withOpacity(0.2),
                              child: const Icon(Icons.photo, size: 80, color: Color(0xFF13DAEC)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Color(0xFF13DAEC)),
                                  const SizedBox(width: 4),
                                  Text(
                                    (widget.place.country ?? 'Unknown').toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF13DAEC),
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
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.place.location,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
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
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Add to Itinerary', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget(bool isDark, Color primaryColor, Color textMain, Color textSub) {
    if (_isLoadingWeather) return const Center(child: CircularProgressIndicator());
    if (_weather == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CURRENT WEATHER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSub)),
                const SizedBox(height: 8),
                Text('${_weather!.temperatureCelsius}°C', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textMain)),
                Text(_weather!.formattedDescription, style: TextStyle(fontSize: 14, color: textSub)),
              ],
            ),
          ),
          Text(_weather!.weatherEmoji, style: const TextStyle(fontSize: 32)),
        ],
      ),
    );
  }

  Widget _buildTagChips(bool isDark, Color primaryColor, Color textMain, Color textSub) {
    return Wrap(
      spacing: 8,
      children: [
        Chip(label: Text(widget.place.category)),
        if (widget.place.priceRange != null) Chip(label: Text(widget.place.priceRange!)),
      ],
    );
  }

  Widget _buildDescription(bool isDark, Color primaryColor, Color textMain, Color textSub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMain)),
        const SizedBox(height: 8),
        Text(
          widget.place.description,
          maxLines: isExpanded ? null : 3,
          overflow: isExpanded ? null : TextOverflow.ellipsis,
          style: TextStyle(color: textSub),
        ),
        TextButton(
          onPressed: () => setState(() => isExpanded = !isExpanded),
          child: Text(isExpanded ? 'Read Less' : 'Read More'),
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
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(widget.place.latitude, widget.place.longitude),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.parth.io.task.smartTravelPlanner',
                    ),
                  ],
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map, color: Color(0xFF13DAEC)),
                      SizedBox(width: 8),
                      Text('View on Map', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
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
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF13DAEC)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Best time to visit: Early morning around 7:00 AM to avoid crowds.', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}