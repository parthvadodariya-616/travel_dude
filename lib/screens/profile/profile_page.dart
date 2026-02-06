// lib/screens/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_dude/widgets/bottom_nav.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase/firestore_service.dart';
import '../../utils/helpers.dart';

import '../settings/settings_page.dart';
import '../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final user = await _firestoreService.getUser(userId);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final displayUser = _user ?? authUser;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = isDark ? const Color(0xFF1A2C30) : Colors.white;
    final textMainColor = isDark ? Colors.white : const Color(0xFF0D1A1B);
    final textSubColor = isDark ? const Color(0xFF8FBABE) : const Color(0xFF4C939A);

    if (displayUser == null && !_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
            child: const Text('Login'),
          ),
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 3),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Top App Bar
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: backgroundColor.withOpacity(0.9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text('Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textMainColor)),
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
                    icon: Icon(Icons.settings_outlined, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Profile Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                          child: Column(
                            children: [
                              Container(
                                width: 112, height: 112,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[300],
                                  border: Border.all(color: isDark ? const Color(0xFF1A2C2E) : Colors.white, width: 4),
                                ),
                                child: Center(child: Text(Helpers.getInitials(displayUser!.displayName), style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.grey[600]))),
                              ),
                              const SizedBox(height: 16),
                              Text(displayUser.displayName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textMainColor)),
                              Text(displayUser.email, style: TextStyle(fontSize: 14, color: textSubColor)),
                              const SizedBox(height: 12),
                              if (displayUser.isVerifiedStudent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified, size: 16, color: primaryColor),
                                      const SizedBox(width: 6),
                                      Text('VERIFIED STUDENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primaryColor)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Stats
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(child: _buildStatCard('${displayUser.countriesVisited}', 'COUNTRIES', isDark, surfaceColor, textMainColor)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard('${displayUser.upcomingTrips}', 'UPCOMING', isDark, surfaceColor, textMainColor)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard('${displayUser.points}', 'POINTS', isDark, surfaceColor, textMainColor)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Account Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 12),
                                child: Text('ACCOUNT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[600], letterSpacing: 1.2)),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                                ),
                                child: Column(
                                  children: [
                                    _buildMenuItem(Icons.person_outline, Colors.blue, 'Personal Information', isDark, textMainColor),
                                    Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                                    _buildMenuItem(Icons.school_outlined, Colors.teal, 'Student ID', isDark, textMainColor),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Logout
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton(
                              onPressed: () async {
                                await Provider.of<AuthProvider>(context, listen: false).signOut();
                                if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.red.withOpacity(0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      // Use Global Bottom Nav Bar
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildStatCard(String val, String label, bool isDark, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
      child: Column(children: [
        Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: text)),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildMenuItem(IconData icon, Color color, String title, bool isDark, Color text) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: text)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}