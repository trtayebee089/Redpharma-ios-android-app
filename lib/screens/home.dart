import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:redpharmabd_app/widgets/products_grid_item.dart';
import 'package:redpharmabd_app/widgets/upload_prescription_button.dart';
import 'package:redpharmabd_app/screens/categories_screen.dart';
import 'package:redpharmabd_app/screens/search_results.dart';
import 'package:redpharmabd_app/widgets/custom_snackbar.dart';
import 'package:redpharmabd_app/constants/default_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
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
  final TextEditingController _searchCtrl = TextEditingController();

  void _onSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchResultsScreen(initialQuery: q)),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
    fetchCategories();
    fetchFeaturedProducts();
    fetchBestSellingProducts();

    _searchCtrl.addListener(() {
      setState(() {});
    });

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

  void clearSearch() {
    _searchCtrl.clear();
  }

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

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;

      AppSnackbar.show(
        context,
        message: 'Could not open $url',
        icon: Icons.check_circle_outline,
        backgroundColor: DefaultTheme.red,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),

            _searchBar(),
            const SizedBox(height: 5),

            _bannerSlider(),
            const SizedBox(height: 15),

            _sectionTitle('Categories'),
            _buildCategorySlider(),

            _sectionTitle('Best Selling Products'),
            _buildProductSlider(bestSellingProducts),

            UploadPrescriptionButton(
              phoneNumber: '8801997202010',
              message: 'Hello, I want to upload my prescription.',
            ),

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
                        launchUrl(Uri.parse('tel:+8801997202010'));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickActionButton(
                      Icons.facebook_rounded,
                      'Live Chat',
                      Colors.blueAccent,
                      () => _launchURL("https://www.facebook.com/redpharmabd/"),
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
      ),
    );
  }

  Widget _bannerSlider() {
    final horizontalPadding = 16.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - (horizontalPadding * 2);

    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        itemCount: bannerImages.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;

              // ✅ Safe check to prevent null page error
              if (_pageController.hasClients &&
                  _pageController.position.haveDimensions) {
                final currentPage =
                    _pageController.page ??
                    _pageController.initialPage.toDouble();
                value = (1 - ((currentPage - index).abs() * 0.15)).clamp(
                  0.85,
                  1.0,
                );
              }

              return Center(
                child: SizedBox(
                  width: cardWidth,
                  height: Curves.easeOut.transform(value) * 160,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 0),
              child: Material(
                color: Colors.transparent,
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                shadowColor: Colors.black26,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.asset(
                        bannerImages[index],
                        fit: BoxFit.cover,
                        width: cardWidth,
                        height: double.infinity,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.02),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        onSubmitted: _onSearch,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search medicines, brands, categories...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
          suffixIcon: (_searchCtrl.text.isNotEmpty)
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => setState(() => _searchCtrl.clear()),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.redAccent, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCategorySlider() {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: categories.isEmpty
          ? ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey[300]!,
                                Colors.grey[200]!,
                                Colors.grey[300]!,
                              ],
                              stops: const [0.1, 0.5, 0.9],
                              begin: Alignment(-1.0, -0.3),
                              end: Alignment(1.0, 0.3),
                            ),
                          ),
                        ),
                      ),
                      // Optional: Animate shimmer using shimmer package or custom animation
                    ],
                  ),
                );
              },
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final category = categories[index];
                final imageUrl = category['image'] ?? '';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryScreen(
                          initialSlug: category['slug'],
                          initialName: category['name'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : const Icon(Icons.category, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProductSlider(List<dynamic> products) {
    if (products.isEmpty) {
      return SizedBox(
        height: 235,
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(2, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4, // reduced
                    vertical: 10,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
    }

    final pages = <List<dynamic>>[];
    for (var i = 0; i < products.length; i += 2) {
      pages.add(
        products.sublist(i, i + 2 > products.length ? products.length : i + 2),
      );
    }

    return SizedBox(
      height: 235,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.99), // tighter viewport
        itemCount: pages.length,
        itemBuilder: (context, pageIndex) {
          final pageItems = pages[pageIndex];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6), // edge padding
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // compact layout
              children: pageItems
                  .map(
                    (p) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                        ), // ✅ reduced inner gap
                        child: ProductGridItem(product: p),
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _quickActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      splashColor: color.withOpacity(0.2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, color.withOpacity(0.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.9),
              blurRadius: 6,
              offset: const Offset(-3, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.7), color.withOpacity(0.4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _howToOrderSection() {
    final steps = [
      {
        'icon': Icons.search,
        'title': 'Search Medicine',
        'desc': 'Quickly find the medicines or products you need.',
        'color': Colors.redAccent,
      },
      {
        'icon': Icons.shopping_cart_outlined,
        'title': 'Add to Cart',
        'desc': 'Add selected medicines to your shopping cart.',
        'color': Colors.orangeAccent,
      },
      {
        'icon': Icons.upload_file_outlined,
        'title': 'Upload Prescription',
        'desc': 'Easily upload your doctor’s prescription when required.',
        'color': Colors.green,
      },
      {
        'icon': Icons.check_circle_outline,
        'title': 'Checkout & Confirm',
        'desc': 'Review your order, make payment, and confirm instantly.',
        'color': Colors.blueAccent,
      },
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.red.shade50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("How to Order?"),
          const SizedBox(height: 20),

          SizedBox(
            height: 130,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.85),
              itemCount: steps.length,
              padEnds: false,
              itemBuilder: (context, index) {
                final step = steps[index];
                final baseColor = step['color'] as Color;

                return Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Material(
                      color: Colors.white,
                      elevation: 6, // shadow
                      shadowColor: baseColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    baseColor.withOpacity(0.9),
                                    baseColor.withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Icon(
                                step['icon'] as IconData,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    step['title'] as String,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    step['desc'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),
          Center(
            child: Container(
              height: 5,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
