// lib/services/firebase/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;

  // BASIC SIGN UP
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('🔵 [AUTH] Basic Signup Start: $email');
      
      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userId = credential.user!.uid;

        // Create the user profile in Firestore
        final userModel = UserModel(
          id: userId,
          email: email,
          displayName: displayName,
          photoURL: null,
          countriesVisited: 0,
          upcomingTrips: 0,
          points: 0,
          isVerifiedStudent: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestoreService.createUser(userModel);
        print('✅ [AUTH] Basic Signup Success');
        return userModel;
      }
      return null;
    } catch (e) {
      print('❌ [AUTH] Basic Signup Error: $e');
      throw e.toString();
    }
  }

  // BASIC SIGN IN
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 [AUTH] Basic Signin Start: $email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userId = credential.user!.uid;
        
        // Fetch from Firestore
        var userModel = await _firestoreService.getUser(userId);
        
        // If missing from DB (Zombie account), create it now
        if (userModel == null) {
          userModel = UserModel(
            id: userId,
            email: email,
            displayName: 'Traveler',
            photoURL: null,
            countriesVisited: 0,
            upcomingTrips: 0,
            points: 0,
            isVerifiedStudent: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _firestoreService.createUser(userModel);
        }
        
        print('✅ [AUTH] Basic Signin Success');
        return userModel;
      }
      return null;
    } catch (e) {
      print('❌ [AUTH] Basic Signin Error: $e');
      throw e.toString();
    }
  }

  Future<void> signOut() async => await _auth.signOut();
  
  Future<void> resetPassword(String email) async => await _auth.sendPasswordResetEmail(email: email);
}