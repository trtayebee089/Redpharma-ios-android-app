class CheckoutResponse {
  final bool success;
  final Map<String, dynamic> sale;
  final Map<String, dynamic> tracking;
  final bool isNewCustomer;
  final String? temporaryPassword;

  CheckoutResponse({
    required this.success,
    required this.sale,
    required this.tracking,
    required this.isNewCustomer,
    this.temporaryPassword,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      success: json['success'],
      sale: json['sale'],
      tracking: json['tracking'],
      isNewCustomer: json['is_new_customer'],
      temporaryPassword: json['temporary_password'],
    );
  }
}
