import 'package:flutter/material.dart';
import 'widgets/home_appbar.dart';
import 'screens/home.dart';
import 'screens/categories_screen.dart';
import 'screens/settings.dart';
import 'screens/cart.dart';
import 'main.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:redpharmabd_app/widgets/custom_bottombar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isBottomNavVisible = true;
  bool isLoggedIn = false;
  String userName = "John Doe";
  String? profileImageUrl;

  late final List<Widget> _screens;

  Future<void> _checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showNoInternetDialog();
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.signal_wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Text('No Internet Connection'),
          ],
        ),
        content: const Text(
          'An active internet connection is required to use this app. '
          'Please connect to Wi-Fi or mobile data and try again.',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void switchToTab(int index) {
    setState(() {
      _selectedIndex = index;
      _isBottomNavVisible = !(index == 2 || index == 3);
    });
  }

  void switchToHomeTab() {
    setState(() {
      _selectedIndex = 0;
      _isBottomNavVisible = true;
    });

    homeScreenKey.currentState?.clearSearch();
  }

  void setBottomNavVisible(bool visible) {
    setState(() {
      _isBottomNavVisible = visible;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();

    _screens = [
      HomeScreen(key: homeScreenKey),
      CategoryScreen(onToggleBottomNav: setBottomNavVisible),
      const CartScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 ? HomeAppBar() : null,
      body: _screens[_selectedIndex],
      bottomNavigationBar:
          (!_isBottomNavVisible || _selectedIndex == 2 || _selectedIndex == 3)
          ? null
          : ModernBottomBar(
              currentIndex: _selectedIndex,
              onTabSelected: (index) {
                setState(() => _selectedIndex = index);
                mainScreenKey.currentState?.switchToTab(index);
              },
            ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isActive = _selectedIndex == index;
    final color = isActive ? Colors.redAccent : Colors.grey;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.redAccent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
