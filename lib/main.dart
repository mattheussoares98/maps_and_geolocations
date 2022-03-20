import 'package:flutter/material.dart';
import 'package:maps_and_geolocations/pages/home_page.dart';
import 'package:maps_and_geolocations/pages/map_page.dart';
import 'package:maps_and_geolocations/pages/splash_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      initialRoute: '/splashScreen',
      routes: {
        '/splashScreen': (context) => const SplashScreen(),
        '/mapPage': (context) => const MapPage(),
        '/homePage': (context) => const HomePage(),
      },
    ),
  );
}
