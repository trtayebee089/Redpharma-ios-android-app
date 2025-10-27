import 'package:flutter/material.dart';
import 'package:redpharmabd_app/screens/product_detail.dart'; 
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ProductGridItem extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onAddToCart;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const ProductGridItem({
    Key? key,
    required this.product,
    this.onAddToCart,
    this.onTap,
    this.width = 160,
    this.height = 270,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productImage = product['image']?.trim() ?? '';
    final categoryImage = product['category']?['image']?.trim() ?? '';
    final brand = (product['brand'] != null && product['brand'] is Map)
        ? product['brand']['title'] ?? 'No Brand'
        : product['brand']?.toString() ?? 'No Brand';
    final name = product['name'] ?? 'Unknown';
    final price = product['price']?.toString() ?? 'N/A';
    final slug = product['slug'] ?? '';

    // Determine which image to use
    String imageUrl;
    String imageType;

    if (productImage.isNotEmpty &&
        !productImage.contains("https://placehold.co") &&
        !productImage.contains("no-image.png")) {
      imageUrl = productImage;
      imageType = 'product';
    } else if (categoryImage.isNotEmpty &&
        !categoryImage.contains("https://placehold.co") &&
        !categoryImage.contains("no-image.png")) {
      imageUrl = categoryImage;
      imageType = 'category';
    } else {
      imageUrl = "https://placehold.co/1920x1080";
      imageType = 'placeholder';
    }

    return GestureDetector(
      onTap:
          onTap ??
          () {
            if (slug.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(productSlug: product['slug']),
                ),
              );
            }
          },
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                height: 130,
                color: imageType == 'category'
                    ? const Color(0xFFF1F1F1)
                    : Colors.transparent,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: imageType == 'category'
                        ? BoxFit.contain
                        : BoxFit.cover,
                    width: imageType == 'category' ? 100 : double.infinity,
                    height: imageType == 'category' ? 80 : double.infinity,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),

            // Product Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            // Brand
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                brand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            // Price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
              child: Text(
                '৳$price',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),

            // Add to Cart Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
              child: SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    Provider.of<CartProvider>(context, listen: false).addItem(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${product['name']} added to cart!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
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
