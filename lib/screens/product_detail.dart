import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:redpharmabd_app/providers/cart_provider.dart';
import 'package:redpharmabd_app/widgets/products_grid_item.dart';
import 'package:redpharmabd_app/screens/checkout.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productSlug;

  const ProductDetailScreen({Key? key, required this.productSlug})
    : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  int soldQty = 0;
  Map<String, dynamic>? product;
  List<dynamic> relatedProducts = [];
  bool isLoading = true;
  bool isLoadingRelated = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  Future<void> fetchProduct() async {
    final apiUrl = 'https://redpharma-api.techrajshahi.com/api/products/${widget.productSlug}';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            product = data['data'];
            soldQty = data!['saleCount'] ?? 0;
            isLoading = false;
          });

          fetchRelatedProducts();
        } else {
          setState(() {
            error = 'Product not found';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Failed to load product';
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

  Future<void> fetchRelatedProducts() async {
    if (product == null) return;

    final categorySlug = product!['category']?['slug'] ?? '';
    if (categorySlug.isEmpty) {
      setState(() {
        isLoadingRelated = false;
      });
      return;
    }

    final apiUrl =
        'https://redpharma-api.techrajshahi.com/api/categories/$categorySlug';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          relatedProducts = data['products']?['data'] ?? [];
          relatedProducts.removeWhere((p) => p['id'] == product!['id']);
          isLoadingRelated = false;
        });
      } else {
        setState(() {
          relatedProducts = [];
          isLoadingRelated = false;
        });
      }
    } catch (e) {
      setState(() {
        relatedProducts = [];
        isLoadingRelated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (product == null || error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Product Details',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(child: Text(error ?? 'Product not found')),
      );
    }

    final String productImage = product!['image'] ?? '';
    final String categoryImage = product!['category']?['image'] ?? '';
    final String categoryName = product!['category']?['name'] ?? '';
    final String name = product!['name'] ?? '';
    final String description = product!['description'] ?? '';
    final double price = product!['price']?.toDouble() ?? 0.0;
    final String unit = product!['unit'] ?? 'pcs';
    final double totalPrice = price * quantity;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(
                      productImage.isNotEmpty ? productImage : categoryImage,
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: (productImage.isEmpty && categoryImage.isEmpty)
                    ? const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 60,
                          color: Colors.grey,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            if (categoryName.isNotEmpty)
              Text(
                categoryName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 4),

            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            Text(
              '৳${price.toStringAsFixed(2)} / $unit',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              '$soldQty Units Sold',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Description
            if (description.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(description),
                  const SizedBox(height: 12),
                ],
              ),

            // Quantity Selector (Full Width)
            const Text(
              'Quantity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Minus button
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (quantity > 1) setState(() => quantity--);
                    },
                  ),

                  // Quantity text centered
                  Expanded(
                    child: Center(
                      child: Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Plus button aligned to right
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() => quantity++);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Related Products Slider
            if (isLoadingRelated)
              const Center(child: CircularProgressIndicator())
            else if (relatedProducts.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Related Products',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 245,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: relatedProducts.length,
                      itemBuilder: (context, index) {
                        final relatedProduct = relatedProducts[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ProductGridItem(
                            product: relatedProduct,
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(
                                    productSlug: relatedProduct['slug'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 80), // space for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.white,
        child: Row(
          children: [
            // Small Cart Button
            GestureDetector(
              onTap: () {
                cart.addItem({
                  'id': product!['id'],
                  'name': name,
                  'price': price,
                  'image': productImage,
                  'unit': 'unit',
                });
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Added to Cart')));
              },
              child: Container(
                width: 60,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shopping_cart, color: Colors.black),
              ),
            ),
            const SizedBox(width: 12),

            // Buy Now Button with total amount
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  cart.addItem({
                    'id': product!['id'],
                    'name': name,
                    'price': price,
                    'image': productImage,
                    'unit': 'unit',
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CheckoutScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'BUY NOW (৳${totalPrice.toStringAsFixed(2)})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
