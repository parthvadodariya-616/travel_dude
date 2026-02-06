// lib/screens/splash/splash_screen.dart

import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF13DAEC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.travel_explore,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'Travel Dude',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Plan your perfect adventure',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}