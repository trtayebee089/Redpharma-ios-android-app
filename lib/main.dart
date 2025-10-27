import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash.dart';
import 'providers/cart_provider.dart';
import 'main_screen.dart';

final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const RedPharmaApp(),
    ),
  );
}


class RedPharmaApp extends StatelessWidget {
  const RedPharmaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RedPharma App',
      theme: ThemeData(primarySwatch: Colors.red),
      home: SplashScreen(), // SplashScreen will decide navigation
    );
  }
}
