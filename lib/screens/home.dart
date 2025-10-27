import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/products_grid_item.dart';
import '../widgets/upload_prescription_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> categories = [];
  List<dynamic> featuredProducts = [];
  List<dynamic> bestSellingProducts = [];

  final List<String> bannerImages = [
    'assets/images/banners/slide-1.jpg',
    'assets/images/banners/slide-2.jpg',
    'assets/images/banners/slide-3.jpg',
  ];

  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
    fetchCategories();
    fetchFeaturedProducts();
    fetchBestSellingProducts();

    // Auto-slide banners
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < bannerImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // 🔹 Fetch Featured Products
  Future<void> fetchFeaturedProducts() async {
    final url = Uri.parse(
      'http://redpharma-api.techrajshahi.com/api/products/featured',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data is List) {
            featuredProducts = data;
          } else if (data is Map && data.containsKey('data')) {
            featuredProducts = data['data'];
          }
        });
        debugPrint(
          'Failed to load featured products: ${response.reasonPhrase}',
        );
      } else {
        debugPrint('Failed to load featured products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching featured products: $e');
    }
  }

  // 🔹 Fetch Best Selling Products
  Future<void> fetchBestSellingProducts() async {
    final url = Uri.parse(
      'http://redpharma-api.techrajshahi.com/api/products/best-selling',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data is List) {
            bestSellingProducts = data;
          } else if (data is Map && data.containsKey('data')) {
            bestSellingProducts = data['data'];
          }
        });
      } else {
        debugPrint(
          'Failed to load best-selling products: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching best-selling products: $e');
    }
  }

  // 🔹 Fetch Categories
  Future<void> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('http://redpharma-api.techrajshahi.com/api/categories'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData['data'] ?? [];
        setState(() {
          categories = data;
        });
      } else {
        debugPrint('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // 🔹 Banner Slider
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _pageController,
              itemCount: bannerImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      bannerImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),

          // 🔹 Categories
          _sectionTitle('Categories'),
          _buildCategorySlider(),

          // 🔹 Best Selling Products
          _sectionTitle('Best Selling Products'),
          _buildProductSlider(bestSellingProducts),

          // 🔹 Upload Prescription
          UploadPrescriptionButton(
            phoneNumber: '8801234567890',
            message: 'Hello, I want to upload my prescription.',
          ),

          // 🔹 Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _quickActionButton(
                    Icons.call,
                    'Call To Order',
                    Colors.green,
                    () {
                      // Example: open dialer
                      launchUrl(Uri.parse('tel:+8801997202010'));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickActionButton(
                    Icons.chat_bubble,
                    'Live Chat',
                    Colors.blue,
                    () {
                      // Example: open chat
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 🔹 Featured Products
          _sectionTitle('Featured Products'),
          _buildProductSlider(featuredProducts),

          // 🔹 How to Order
          _howToOrderSection(),
        ],
      ),
    );
  }

  // 🧱 Section Title Widget
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 🧱 Category Slider
  Widget _buildCategorySlider() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                final category = categories[index];
                final imageUrl = category['image'] ?? '';
                final name = category['name'] ?? '';
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 80,
                  child: Column(
                    children: [
                      Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: imageUrl.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                )
                              : const Icon(
                                  Icons.category,
                                  color: Colors.redAccent,
                                ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // 🧱 Product Slider
  Widget _buildProductSlider(List<dynamic> products) {
    if (products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      height: 270, // increased height for button
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        itemBuilder: (context, index) {
          return ProductGridItem(product: products[index]);
        },
      ),
    );
  }

  // 🧱 Quick Action Buttons
  Widget _quickActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧱 How To Order Section
  Widget _howToOrderSection() {
    final steps = [
      {
        'icon': Icons.search,
        'title': 'Search Medicine',
        'desc': 'Find your required medicine quickly.',
      },
      {
        'icon': Icons.shopping_cart_outlined,
        'title': 'Add to Cart',
        'desc': 'Add selected items to your cart.',
      },
      {
        'icon': Icons.upload_file_outlined,
        'title': 'Upload Prescription',
        'desc': 'If needed, upload your doctor’s prescription.',
      },
      {
        'icon': Icons.check_circle_outline,
        'title': 'Checkout & Confirm',
        'desc': 'Proceed to payment and confirm your order.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to Order',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...steps.map(
            (step) => Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(
                    step['icon'] as IconData,
                    color: Colors.blue,
                    size: 22,
                  ),
                ),
                title: Text(
                  step['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(step['desc'] as String),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
