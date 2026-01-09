// lib/screens/places/place_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final weather = await _weatherService.getWeatherByCoordinates(
        latitude: widget.place.latitude,
        longitude: widget.place.longitude,
      );
      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingWeather = false);
    }
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
      body: CustomScrollView(
        slivers: [
          // Hero Image
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.45,
            pinned: false,
            backgroundColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.place.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.place.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_,__) => Container(color: Colors.grey[800]),
                        )
                      : Container(color: Colors.grey[800]),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black12, Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 32, left: 24, right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            widget.place.category.toUpperCase(),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.place.name,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.place.location,
                                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -16, 0),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weather Widget
                    if (_weather != null)
                      _buildWeatherWidget(isDark, primaryColor, textMainColor, textSubColor),
                    
                    const SizedBox(height: 24),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTripPage(initialPlace: widget.place)));
                        },
                        icon: const Icon(Icons.calendar_month, color: Colors.white),
                        label: const Text('Add to Itinerary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMainColor)),
                    const SizedBox(height: 8),
                    Text(
                      widget.place.description.isNotEmpty ? widget.place.description : 'No description available.',
                      style: TextStyle(fontSize: 14, height: 1.5, color: textSubColor),
                      maxLines: _isExpanded ? null : 4,
                      overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    ),
                    InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Text(_isExpanded ? 'Read less' : 'Read more', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
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

  Widget _buildWeatherWidget(bool isDark, Color primaryColor, Color textMain, Color textSub) {
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
                Row(
                  children: [
                    Text('${_weather!.temperatureCelsius}°C', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textMain)),
                    const SizedBox(width: 8),
                    Text(_weather!.formattedDescription, style: TextStyle(fontSize: 14, color: textSub)),
                  ],
                ),
              ],
            ),
          ),
          Image.network(_weather!.iconUrl, width: 50, height: 50, errorBuilder: (_,__,___) => Icon(Icons.wb_sunny, color: primaryColor)),
        ],
      ),
    );
  }
}