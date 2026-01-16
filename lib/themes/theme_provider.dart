import 'package:flutter/material.dart';
import 'package:family/themes/light_mode.dart';
import 'dark_mode.dart';

class ThemeProvider extends ChangeNotifier{
  ThemeData _themeData = lightMode;

  ThemeData get themeData => _themeData; // Correction ici: getter renommé pour correspondre à l'usage
  bool get isDarkMode =>  _themeData == darkMode;
  set themeData (ThemeData themeData){
    _themeData = themeData;
    notifyListeners();
  }
  void toggleTheme(){
    if (_themeData == lightMode){
      themeData = darkMode;
    }else{
      themeData = lightMode;
    }
  }
}