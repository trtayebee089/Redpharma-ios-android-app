import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import '../main_screen.dart';
import '../main.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Image.asset('assets/images/logo.png'),
      nextScreen: MainScreen(key: mainScreenKey),
      splashTransition: SplashTransition.fadeTransition,
      backgroundColor: Colors.white,
      duration: 2500,
    );
  }
}
