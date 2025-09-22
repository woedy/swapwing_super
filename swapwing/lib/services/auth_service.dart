import 'package:shared_preferences/shared_preferences.dart';
import 'package:swapwing/models/user.dart';
import 'package:swapwing/services/sample_data.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';

  static SwapWingUser? _currentUser;

  static SwapWingUser? get currentUser => _currentUser;

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  static Future<void> login(String email, String password) async {
    // Simulate login - in real app, this would authenticate with backend
    await Future.delayed(Duration(seconds: 1));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userIdKey, SampleData.currentUser.id);
    
    _currentUser = SampleData.currentUser;
  }

  static Future<void> loginWithGoogle() async {
    await Future.delayed(Duration(seconds: 1));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userIdKey, SampleData.currentUser.id);
    
    _currentUser = SampleData.currentUser;
  }

  static Future<void> signUp(String email, String password, String username) async {
    await Future.delayed(Duration(seconds: 1));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userIdKey, SampleData.currentUser.id);
    
    _currentUser = SampleData.currentUser;
  }

  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, true);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _currentUser = null;
  }

  static Future<void> initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    if (userId != null) {
      _currentUser = SampleData.currentUser;
    }
  }
}