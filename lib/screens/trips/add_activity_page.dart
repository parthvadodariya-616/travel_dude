import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/trip_model.dart';
import '../../models/place_model.dart';
import '../../providers/place_provider.dart';

class AddActivityPage extends StatefulWidget {
  final int dayNumber;
  final int totalDays;

  const AddActivityPage({
    Key? key, 
    required this.dayNumber,
    this.totalDays = 7,
  }) : super(key: key);

  @override
  State<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  final _formKey = GlobalKey<FormState>();
  late String selectedDay;
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  PlaceModel? _selectedPlace;

  // --- TIME SELECTION STATE ---
  int selectedHour = 11;
  int selectedMinute = 15;
  String selectedPeriod = 'AM';
  String selectedCategory = 'Sightseeing';

  late List<Map<String, String>> days;

  final List<int> hours = List.generate(12, (index) => index + 1);
  final List<int> minutes = [00, 15, 30, 45];
  final List<String> periods = ['AM', 'PM'];

  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.museum, 'label': 'Sightseeing'},
    {'icon': Icons.restaurant, 'label': 'Dining'},
    {'icon': Icons.directions_bus, 'label': 'Transport'},
    {'icon': Icons.local_mall, 'label': 'Shopping'},
  ];

  @override
  void initState() {
    super.initState();
    selectedDay = widget.dayNumber.toString();
    days = List.generate(widget.totalDays, (index) {
      return {'value': '${index + 1}', 'label': 'Day ${index + 1}'};
    });
  }

  @override
  void dispose() {
    _activityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String get formattedTime {
    final hour = selectedHour.toString().padLeft(2, '0');
    final minute = selectedMinute.toString().padLeft(2, '0');
    return '$hour:$minute $selectedPeriod';
  }

  Future<void> _openLocationSearch() async {
    final PlaceModel? result = await showSearch<PlaceModel?>(
      context: context,
      delegate: LocationSearchDelegate(context),
    );

    if (result != null) {
      setState(() {
        _selectedPlace = result;
        _locationController.text = result.name;
        if (_activityController.text.isEmpty) {
          _activityController.text = "Visit ${result.name}";
        }
      });
    }
  }

  void _savePlan() {
    if (_activityController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter an activity name")));
       return;
    }

    final activity = ItineraryEvent(
      title: _activityController.text,
      subtitle: _locationController.text.isNotEmpty ? _locationController.text : selectedCategory,
      time: formattedTime,
      icon: _getCategoryIconKey(selectedCategory),
    );

    Navigator.pop(context, {
      'event': activity, 
      'day': int.parse(selectedDay),
      'place': _selectedPlace
    });
  }

  String _getCategoryIconKey(String category) {
    switch (category) {
      case 'Dining': return 'restaurant';
      case 'Transport': return 'commute';
      case 'Shopping': return 'shopping_bag';
      default: return 'place';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF13DAEC);
    final backgroundColor = isDark ? const Color(0xFF102022) : const Color(0xFFF6F8F8);
    final surfaceColor = isDark ? const Color(0xFF1A2C30) : Colors.white;
    final textMainColor = isDark ? Colors.white : const Color(0xFF0D1A1B);
    final textSubColor = isDark ? const Color(0xFF8FBABE) : const Color(0xFF4C939A);
    final borderColor = isDark ? const Color(0xFF1A2C30) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => Navigator.pop(context),
                    color: textMainColor,
                  ),
                  Expanded(
                    child: Text(
                      'Add Plan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textMainColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Select Day Section
                    _buildSectionTitle('Select Day', textMainColor),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDay,
                          isExpanded: true,
                          icon: Icon(Icons.expand_more, color: textSubColor),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textMainColor,
                          ),
                          dropdownColor: surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          items: days.map((day) {
                            return DropdownMenuItem<String>(
                              value: day['value'],
                              child: Text(day['label']!),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedDay = value);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Activity Name Section
                    _buildSectionTitle("What's the plan?", textMainColor),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _activityController,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textMainColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Visit Eiffel Tower',
                        hintStyle: TextStyle(color: textSubColor.withOpacity(0.5)),
                        filled: true,
                        fillColor: surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(15),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Location Search Field
                    GestureDetector(
                      onTap: _openLocationSearch,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _locationController,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textMainColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search Location...',
                            hintStyle: TextStyle(color: textSubColor.withOpacity(0.5)),
                            prefixIcon: Icon(Icons.search, color: textSubColor),
                            filled: true,
                            fillColor: surfaceColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            contentPadding: const EdgeInsets.all(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- TIME SELECTION BLOCK (THE REQUESTED UI) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('Time', textMainColor),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          // Hours
                          Expanded(
                            child: SizedBox(
                              height: 100,
                              child: ListWheelScrollView.useDelegate(
                                itemExtent: 40,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (index) => setState(() => selectedHour = hours[index]),
                                childDelegate: ListWheelChildLoopingListDelegate(
                                  children: hours.map((h) => Center(child: Text(h.toString(), style: TextStyle(fontSize: 16, color: textMainColor)))).toList(),
                                ),
                              ),
                            ),
                          ),
                          // Minutes
                          Expanded(
                            child: SizedBox(
                              height: 100,
                              child: ListWheelScrollView.useDelegate(
                                itemExtent: 40,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (index) => setState(() => selectedMinute = minutes[index]),
                                childDelegate: ListWheelChildLoopingListDelegate(
                                  children: minutes.map((m) => Center(child: Text(m.toString().padLeft(2,'0'), style: TextStyle(fontSize: 16, color: textMainColor)))).toList(),
                                ),
                              ),
                            ),
                          ),
                          // Period (AM/PM)
                          Expanded(
                            child: SizedBox(
                              height: 100,
                              child: ListWheelScrollView.useDelegate(
                                itemExtent: 40,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (index) => setState(() => selectedPeriod = periods[index]),
                                childDelegate: ListWheelChildLoopingListDelegate(
                                  children: periods.map((p) => Center(child: Text(p, style: TextStyle(fontSize: 16, color: textMainColor)))).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // --- END TIME SELECTION BLOCK ---

                    const SizedBox(height: 32),

                    // Category Selector
                    _buildSectionTitle('Category', textMainColor),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedCategory == category['label'];
                        return GestureDetector(
                          onTap: () => setState(() => selectedCategory = category['label']),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor.withOpacity(0.1) : surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? primaryColor : borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  category['icon'],
                                  color: isSelected ? primaryColor : textSubColor,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  category['label'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? textMainColor : textSubColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Location Preview
                    if (_selectedPlace != null && _selectedPlace!.imageUrl != null) ...[
                      _buildSectionTitle('Location Preview', textMainColor),
                      const SizedBox(height: 12),
                      Container(
                        height: 128,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: _selectedPlace!.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_,__) => Container(color: Colors.grey[300]),
                            errorWidget: (_,__,___) => Container(color: Colors.grey[300], child: Icon(Icons.image, color: textSubColor)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _savePlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Add Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
  
  // REQUIRED for Time Selection UI to work
  Widget _buildScrollPicker(List<String> items, String selectedItem, Function(String) onChanged, Color textMain, Color textSub, Color primary) {
    return SizedBox(
      height: 100,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) => onChanged(items[index]),
        childDelegate: ListWheelChildLoopingListDelegate(
          children: items.map((item) => Center(child: Text(item, style: TextStyle(fontSize: item == selectedItem ? 18 : 14, fontWeight: item == selectedItem ? FontWeight.w700 : FontWeight.w500, color: item == selectedItem ? primary : textSub.withOpacity(0.5))))).toList(),
        ),
      ),
    );
  }
}

// Search Delegate Logic (Essential for location search)
class LocationSearchDelegate extends SearchDelegate<PlaceModel?> {
  final BuildContext parentContext;
  LocationSearchDelegate(this.parentContext);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF102022) : const Color(0xFFF6F8F8),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        titleTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.length > 2) {
       Provider.of<PlaceProvider>(context, listen: false).searchPlaces(query);
    }

    return Consumer<PlaceProvider>(
      builder: (context, placeProvider, child) {
        if (placeProvider.isLoading) return const Center(child: CircularProgressIndicator());
        
        final results = placeProvider.popularPlaces;
        
        if (results.isEmpty) {
           return const Center(child: Text("Start typing to search..."));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final place = results[index];
            return ListTile(
              title: Text(place.name),
              subtitle: Text(place.location), 
              leading: place.imageUrl != null 
                  ? CircleAvatar(backgroundImage: NetworkImage(place.imageUrl!))
                  : const Icon(Icons.place),
              onTap: () => close(context, place),
            );
          },
        );
      },
    );
  }
}