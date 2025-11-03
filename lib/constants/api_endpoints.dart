class ApiEndpoints {
  static const String baseUrl = 'https://redpharma-api.techrajshahi.com/api';

  // public routes
  static const String rewardPointTiers = '$baseUrl/reward-point-tiers';
  static const String shippingZones = '$baseUrl/shipping-zones';
  static const String categories = '$baseUrl/categories';
  
  static const String featuredProducts = '$baseUrl/products/featured';
  static const String bestSellingProducts = '$baseUrl/products/best-selling';
  static const String searchProducts = '$baseUrl/search';
  static const String productDetails = '$baseUrl/products'; // append /{slug}

  static const String banners = '$baseUrl/banners';
  static const String privacyPolicy = '$baseUrl/pages/privacy-and-policy';
  static const String refundPolicy = '$baseUrl/pages/refund-and-returns';

  // sanctum routes
  static const String login = '$baseUrl/customer/login';
  static const String register = '$baseUrl/customer/register';
  static const String userProfile = '$baseUrl/customer/profile';
  static const String userOrders = '$baseUrl/customer/orders';
  static const String orderDetail = '$baseUrl/customer/orders'; // append /{order_id}
  static const String updateProfile = '$baseUrl/customer/profile/update';
  static const String changePassword = '$baseUrl/customer/profile/update-password';  
}
