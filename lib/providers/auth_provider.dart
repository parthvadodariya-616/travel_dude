// lib/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firebase/auth_service.dart';
import '../services/local/local_storage_service.dart';
import '../services/firebase/firestore_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        final userData = await _firestoreService.getUser(firebaseUser.uid);
        if (userData != null) {
          _user = userData;
          await _syncLocal();
        }
      }
    } catch (e) {
      print('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithEmail(email: email, password: password);
      if (_user != null) {
        await _syncLocal();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({required String email, required String password, required String displayName}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signUpWithEmail(email: email, password: password, displayName: displayName);
      if (_user != null) {
        await _syncLocal();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncLocal() async {
    if (_user != null) {
      await LocalStorageService.setBool('is_logged_in', true);
      await LocalStorageService.setString('user_id', _user!.id);
      await LocalStorageService.setString('user_email', _user!.email);
      await LocalStorageService.setString('user_name', _user!.displayName);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await LocalStorageService.clearUserData();
    _user = null;
    notifyListeners();
  }
}