import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/products_grid_item.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({Key? key}) : super(key: key);

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
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    const apiUrl = 'https://redpharma-api.techrajshahi.com/api/categories';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categories = data['data'] ?? [];
          isLoadingCategories = false;
        });
      } else {
        setState(() {
          categoriesError = 'Failed to load categories';
          isLoadingCategories = false;
        });
      }
    } catch (e) {
      setState(() {
        categoriesError = 'Error: $e';
        isLoadingCategories = false;
      });
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
    if (isLoadingCategories)
      return const Center(child: CircularProgressIndicator());
    if (categoriesError != null) return Center(child: Text(categoriesError!));

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.65,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final name = category['name'] ?? 'Unknown';
        final slug = category['slug'] ?? '';
        final imageUrl = category['image'] ?? 'https://placehold.co/1920x1080';

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedCategorySlug = slug;
              selectedCategoryName = name;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      width: 70,
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 36,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
  String? error;

  @override
  void initState() {
    super.initState();
    fetchCategoryProducts();
  }

  Future<void> fetchCategoryProducts() async {
    final apiUrl =
        'https://redpharma-api.techrajshahi.com/api/categories/${widget.slug}';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          products = data['products']?['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load products';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text(error!));

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 10,
        childAspectRatio: 210 / 270,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductGridItem(product: products[index]);
      },
    );
  }
}
