// lib/widgets/bottom_nav_bar.dart

import 'package:flutter/material.dart';
import '../screens/home/home_page.dart';
import '../screens/trips/saved_trips_page.dart';
import '../screens/places/place_list_page.dart';
import '../screens/profile/profile_page.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({Key? key, required this.currentIndex}) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const SavedTripsPage();
        break;
      case 2:
        page = const PlaceListPage();
        break;
      case 3:
        page = const ProfilePage();
        break;
      default:
        page = const HomePage();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => page,
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = isDark ? const Color(0xFF1A2C30) : Colors.white;
    final unselectedColor = isDark ? const Color(0xFF8FBABE) : const Color(0xFF4C939A);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_filled, // Use filled icon for home
                label: 'Home',
                index: 0,
                isSelected: currentIndex == 0,
                primaryColor: primaryColor,
                unselectedColor: unselectedColor,
              ),
              _buildNavItem(
                context,
                icon: currentIndex == 1 ? Icons.favorite : Icons.favorite_outline,
                label: 'Saved',
                index: 1,
                isSelected: currentIndex == 1,
                primaryColor: primaryColor,
                unselectedColor: unselectedColor,
              ),
              _buildNavItem(
                context,
                icon: currentIndex == 2 ? Icons.explore : Icons.explore_outlined,
                label: 'Explore',
                index: 2,
                isSelected: currentIndex == 2,
                primaryColor: primaryColor,
                unselectedColor: unselectedColor,
              ),
              _buildNavItem(
                context,
                icon: currentIndex == 3 ? Icons.person : Icons.person_outline,
                label: 'Profile',
                index: 3,
                isSelected: currentIndex == 3,
                primaryColor: primaryColor,
                unselectedColor: unselectedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    required Color primaryColor,
    required Color unselectedColor,
  }) {
    return InkWell(
      onTap: () => _onItemTapped(context, index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : unselectedColor,
              size: 26, // Slightly larger icons
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primaryColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}