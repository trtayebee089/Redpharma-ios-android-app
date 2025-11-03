import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/products_grid_item.dart';

class CategoryScreen extends StatefulWidget {
  final String? initialSlug;
  final String? initialName;
  final void Function(bool)? onToggleBottomNav;

  const CategoryScreen({
    Key? key,
    this.initialSlug,
    this.initialName,
    this.onToggleBottomNav,
  }) : super(key: key);

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<dynamic> categories = [];
  bool isLoadingCategories = true;
  String? categoriesError;

  String? selectedCategorySlug;
  String? selectedCategoryName;

  @override
  void initState() {
    super.initState();
    selectedCategorySlug = widget.initialSlug;
    selectedCategoryName = widget.initialName;

    _loadCachedCategories();
    fetchCategories();
  }

  Future<void> _loadCachedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_categories');

    if (cachedData != null) {
      final decoded = json.decode(cachedData);
      setState(() {
        categories = decoded;
        isLoadingCategories = false;
      });
    }
  }

  Future<void> fetchCategories() async {
    const apiUrl = 'https://redpharma-api.techrajshahi.com/api/categories';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newCategories = data['data'] ?? [];

        setState(() {
          categories = newCategories;
          isLoadingCategories = false;
        });

        // save to cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_categories', json.encode(newCategories));
      } else {
        if (categories.isEmpty) {
          setState(() {
            categoriesError = 'Failed to load categories';
            isLoadingCategories = false;
          });
        }
      }
    } catch (e) {
      if (categories.isEmpty) {
        setState(() {
          categoriesError = 'Error: $e';
          isLoadingCategories = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedCategorySlug == null
              ? 'Categories'
              : selectedCategoryName ?? '',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: selectedCategorySlug != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () {
                  widget.onToggleBottomNav?.call(true);
                  setState(() {
                    selectedCategorySlug = null;
                    selectedCategoryName = null;
                  });
                },
              )
            : null,
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: selectedCategorySlug == null
          ? buildCategoryGrid()
          : CategoryProductsWidget(slug: selectedCategorySlug!),
    );
  }

  Widget buildCategoryGrid() {
    if (isLoadingCategories && categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (categoriesError != null && categories.isEmpty) {
      return Center(child: Text(categoriesError!));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final slug = category['slug'] ?? '';
        final imageUrl =
            category['image'] ??
            'https://redpharma-api.techrajshahi.com/images/product/default-medicine-image.png';

        return GestureDetector(
          onTap: () {
            widget.onToggleBottomNav?.call(false);
            setState(() {
              selectedCategorySlug = slug;
              selectedCategoryName = category['name'];
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
                // Badge
                if (category['total_products'] != null)
                  Positioned(
                    top: 0,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF708993),
                        // borderRadius: BorderRadius.circular(12),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${category['total_products']} Items',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CategoryProductsWidget extends StatefulWidget {
  final String slug;

  const CategoryProductsWidget({required this.slug, Key? key})
    : super(key: key);

  @override
  _CategoryProductsWidgetState createState() => _CategoryProductsWidgetState();
}

class _CategoryProductsWidgetState extends State<CategoryProductsWidget> {
  List<dynamic> products = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchCategoryProducts();
  }

  Future<void> fetchCategoryProducts({bool loadMore = false}) async {
    if (loadMore) {
      setState(() {
        isLoadingMore = true;
      });
    } else {
      setState(() {
        isLoading = true;
        error = null;
      });
    }

    final apiUrl =
        'https://redpharma-api.techrajshahi.com/api/categories/${widget.slug}?page=$currentPage';
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newProducts = data['products']?['data'] ?? [];

        setState(() {
          if (loadMore) {
            products.addAll(newProducts);
          } else {
            products = newProducts;
          }

          // If less than 20, no more pages
          hasMore = newProducts.length >= 20;
          isLoading = false;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          error = 'Failed to load products';
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void loadMoreProducts() {
    if (!hasMore || isLoadingMore) return;
    currentPage++;
    fetchCategoryProducts(loadMore: true);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text(error!));

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 10,
              childAspectRatio: 210 / 225,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductGridItem(product: products[index]);
            },
          ),
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: InkWell(
                onTap: isLoadingMore ? null : loadMoreProducts,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLoadingMore
                          ? [Colors.grey.shade300, Colors.grey.shade200]
                          : [Colors.green.shade400, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isLoadingMore
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Processing...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Load More',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
