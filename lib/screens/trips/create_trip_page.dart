import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/trip_model.dart';
import '../../models/place_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';

class CreateTripPage extends StatefulWidget {
  final PlaceModel? initialPlace;

  const CreateTripPage({Key? key, this.initialPlace}) : super(key: key);

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPlace != null) {
      _destinationController.text = widget.initialPlace!.name;
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF13DAEC);

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark 
              ? ColorScheme.dark(
                  primary: primaryColor,
                  onPrimary: Colors.black,
                  surface: const Color(0xFF1A2C30),
                  onSurface: Colors.white,
                )
              : ColorScheme.light(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
            dialogBackgroundColor: isDark ? const Color(0xFF102022) : Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor, // OK/Cancel buttons
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_startDate == null || _endDate == null) {
      Helpers.showSnackBar(context, 'Please select dates', isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      Helpers.showSnackBar(context, 'You must be logged in to create a trip', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final daysCount = _endDate!.difference(_startDate!).inDays + 1;
      
      final List<ItineraryDay> itinerary = [];
      for (int i = 0; i < daysCount; i++) {
        final currentDate = _startDate!.add(Duration(days: i));
        final formatter = DateFormat('MMM dd, yyyy');
        
        itinerary.add(ItineraryDay(
          dayNumber: i + 1,
          date: formatter.format(currentDate),
          events: [],
        ));
      }

      if (widget.initialPlace != null && itinerary.isNotEmpty) {
        final firstEvent = ItineraryEvent(
          title: 'Visit ${widget.initialPlace!.name}',
          subtitle: widget.initialPlace!.location,
          time: '10:00',
          icon: 'place',
        );
        itinerary[0] = itinerary[0].copyWith(events: [firstEvent]);
      }

      final trip = TripModel(
        id: '',
        userId: user.id,
        destination: _destinationController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        budget: double.tryParse(_budgetController.text) ?? 0,
        spent: 0,
        itinerary: itinerary,
        imageUrl: widget.initialPlace?.imageUrl, 
        status: 'upcoming',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await Provider.of<TripProvider>(context, listen: false).createTrip(trip);
      
      if (success && mounted) {
        Helpers.showSnackBar(context, 'Trip created successfully!');
        Navigator.pop(context, true); 
      } else if (mounted) {
        final error = Provider.of<TripProvider>(context, listen: false).error;
        Helpers.showSnackBar(context, error ?? 'Failed to save trip', isError: true);
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF13DAEC);
    final backgroundColor = isDark ? const Color(0xFF102022) : const Color(0xFFF6F8F8);
    final surfaceColor = isDark ? const Color(0xFF1A2C30) : Colors.white;
    final textMainColor = isDark ? Colors.white : const Color(0xFF0D1A1B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textMainColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Create New Trip', style: TextStyle(color: textMainColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Where to?', textMainColor),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _destinationController,
                  hint: 'Destination (e.g. Paris)',
                  icon: Icons.place_outlined,
                  surfaceColor: surfaceColor,
                  textMainColor: textMainColor,
                  validator: (v) => Validators.validateRequired(v, 'Destination'),
                ),
                
                const SizedBox(height: 24),
                
                _buildLabel('When?', textMainColor),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _selectDateRange(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, color: Colors.grey[400]),
                        const SizedBox(width: 12),
                        Text(
                          _startDate == null 
                            ? 'Select Dates' 
                            : '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}',
                          style: TextStyle(
                            color: _startDate == null ? Colors.grey[400] : textMainColor, 
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                _buildLabel('Budget (Optional)', textMainColor),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _budgetController,
                  hint: 'Amount (e.g. 2000)',
                  icon: Icons.attach_money,
                  surfaceColor: surfaceColor,
                  textMainColor: textMainColor,
                  keyboardType: TextInputType.number,
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTrip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Trip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color surfaceColor,
    required Color textMainColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: textMainColor),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}