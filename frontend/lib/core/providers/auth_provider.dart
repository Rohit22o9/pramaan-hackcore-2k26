import 'package:flutter/material.dart';

enum UserRoleType { farmer, fieldAgent, buyer }

class AuthProvider extends ChangeNotifier {
  UserRoleType _currentRole = UserRoleType.farmer;
  String _selectedLanguage = 'en'; // 'en', 'hi', 'mr', 'te', 'pa', 'gu'
  String _userName = 'Ramesh Patil';
  String _userVillage = 'Dindori, Nashik';
  bool _isDarkMode = false;

  UserRoleType get currentRole => _currentRole;
  String get selectedLanguage => _selectedLanguage;
  String get userName => _userName;
  String get userVillage => _userVillage;
  bool get isDarkMode => _isDarkMode;

  String get roleName {
    switch (_currentRole) {
      case UserRoleType.farmer:
        return 'Farmer';
      case UserRoleType.fieldAgent:
        return 'Field Agent / Agronomist';
      case UserRoleType.buyer:
        return 'Buyer / Input Partner';
    }
  }

  void switchRole(UserRoleType role) {
    _currentRole = role;
    if (role == UserRoleType.farmer) {
      _userName = 'Ramesh Patil';
      _userVillage = 'Dindori, Nashik';
    } else if (role == UserRoleType.fieldAgent) {
      _userName = 'Dr. Anita Deshmukh';
      _userVillage = 'Nashik Agronomy Center';
    } else {
      _userName = 'ITC Procurement Team';
      _userVillage = 'Mumbai Agri-Exchange';
    }
    notifyListeners();
  }

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
