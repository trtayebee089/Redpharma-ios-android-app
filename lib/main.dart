import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'main_screen.dart';
import 'screens/home.dart';

final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();
final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  await authProvider.loadToken();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
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
      home: SplashScreen(),
    );
  }
}
