import 'package:flutter/material.dart';
import 'app_constants.dart';
import 'link_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.dark;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Link Generator',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: kBgLight,
        colorScheme: const ColorScheme.light(
          primary: kPrimaryLight,
          surface: kSurfaceLight,
          onSurface: kTextLight,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBgDark,
        colorScheme: const ColorScheme.dark(
          primary: kPrimaryDark,
          surface: kSurfaceDark,
          onSurface: kTextDark,
        ),
        useMaterial3: true,
      ),
      home: LinkGenerator(onToggleTheme: toggleTheme),
    );
  }
}
