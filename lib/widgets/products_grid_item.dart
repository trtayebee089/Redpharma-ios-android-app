import 'package:flutter/material.dart';
import 'package:redpharmabd_app/screens/product_detail.dart';
import 'package:provider/provider.dart';
import 'package:redpharmabd_app/providers/cart_provider.dart';
import 'package:redpharmabd_app/widgets/custom_snackbar.dart';
import 'package:redpharmabd_app/constants/default_theme.dart';

class ProductGridItem extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onAddToCart;
  final double width;
  final VoidCallback? onTap;

  const ProductGridItem({
    Key? key,
    required this.product,
    this.onAddToCart,
    this.onTap,
    this.width = 160,
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
                  builder: (_) =>
                      ProductDetailScreen(productSlug: product['slug']),
                ),
              );
            }
          },
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:
                MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: imageType == 'category'
                      ? const Color(0xFFF1F1F1)
                      : Colors.transparent,
                  child: Image.network(
                    imageUrl,
                    fit: imageType == 'category'
                        ? BoxFit.contain
                        : BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),

              Text(
                brand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),

              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '৳$price',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Provider.of<CartProvider>(
                        context,
                        listen: false,
                      ).addItem(product);
                      
                      AppSnackbar.show(
                        context,
                        message: '${product['name']} added to cart!',
                        icon: Icons.check_circle_outline,
                        backgroundColor: DefaultTheme.green,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_shopping_cart,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
