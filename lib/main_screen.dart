import 'package:flutter/material.dart';
import 'widgets/home_appbar.dart';
import 'screens/home.dart';
import 'screens/categories_screen.dart';
import 'screens/settings.dart';
import 'screens/cart.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool isLoggedIn = false;
  String userName = "John Doe";
  String? profileImageUrl;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoryScreen(),
    const CartScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Public method to switch to Home tab
  void switchToHomeTab() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? HomeAppBar(
              onMenuTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              onNotificationsTap: () {
                // handle notification tap
              },
            )
          : null,
      body: _screens[_selectedIndex],
      bottomNavigationBar: (_selectedIndex == 2 /* Cart */ )
          ? null
          : BottomAppBar(
              color: Colors.white,
              elevation: 10,
              child: SafeArea(
                child: SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(Icons.home, 'Home', 0),
                      _buildNavItem(Icons.category, 'Categories', 1),
                      _buildNavItem(Icons.shopping_cart, 'Cart', 2),
                      _buildNavItem(Icons.settings, 'Settings', 3),
                    ],
                  ),
                ),
              ),
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
