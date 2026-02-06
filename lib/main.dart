// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Firebase Options
import 'firebase_options.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/place_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/theme_provider.dart';

// Services
import 'services/local/local_storage_service.dart';
import 'utils/helpers.dart';

// Screens
import 'screens/auth/login_page.dart';
import 'screens/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Helpers.log('Firebase initialized', tag: 'MAIN');
  } catch (e) {
    Helpers.log('CRITICAL: Error initializing Firebase: $e', tag: 'MAIN');
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text("Firebase Init Error: $e")))));
    return;
  }

  try {
    await LocalStorageService.init();
    Helpers.log('Local storage initialized', tag: 'MAIN');
  } catch (e) {
    Helpers.log('Error initializing local storage: $e', tag: 'MAIN');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // ThemeProvider loads theme in constructor
        ChangeNotifierProvider(create: (_) => PlaceProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Travel Dude',
            debugShowCheckedModeBanner: false,
            // Use AppTheme if defined, otherwise fallback to manual ThemeData
            // Assuming AppTheme class exists in config/theme.dart based on imports
            theme: ThemeData(
              fontFamily: 'Plus Jakarta Sans',
              primaryColor: const Color(0xFF13DAEC),
              scaffoldBackgroundColor: const Color(0xFFF6F8F8),
              brightness: Brightness.light,
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF13DAEC),
                surface: Colors.white,
              ),
            ),
            darkTheme: ThemeData(
              fontFamily: 'Plus Jakarta Sans',
              primaryColor: const Color(0xFF13DAEC),
              scaffoldBackgroundColor: const Color(0xFF102022),
              brightness: Brightness.dark,
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF13DAEC),
                surface: Color(0xFF1A2C30),
              ),
            ),
            themeMode: themeProvider.themeMode,
            
            // NORMAL NAVIGATION (No Routes)
            home: const AuthCheckWrapper(),
          );
        },
      ),
    );
  }
}

class AuthCheckWrapper extends StatefulWidget {
  const AuthCheckWrapper({Key? key}) : super(key: key);

  @override
  State<AuthCheckWrapper> createState() => _AuthCheckWrapperState();
}

class _AuthCheckWrapperState extends State<AuthCheckWrapper> {
  @override
  void initState() {
    super.initState();
    _handleStartUp();
  }

  Future<void> _handleStartUp() async {
    // Artificial delay to show logo if desired, or remove for instant check
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Wait for auth provider to finish initializing (checking shared prefs/firebase)
    while (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simple Loading Screen (replaces external SplashScreen)
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon Placeholder
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF13DAEC).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flight_takeoff, size: 50, color: Color(0xFF13DAEC)),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Color(0xFF13DAEC)),
          ],
        ),
      ),
    );
  }
}