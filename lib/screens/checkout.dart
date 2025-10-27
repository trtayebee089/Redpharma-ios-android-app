import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/cart_provider.dart';
import 'package:redpharmabd_app/main_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int currentStep = 1;
  final _formKey = GlobalKey<FormState>();

  String fullName = '';
  String phone = '';
  String address = '';
  String district = '';
  String division = '';
  String paymentMethod = 'cash_on_delivery';
  bool isLoading = false;

  // 🔹 Step Indicator
  Widget _buildStepIndicator(int step, String title) {
    bool isCompleted = step < currentStep;
    bool isCurrent = step == currentStep;

    Color backgroundColor = isCompleted
        ? Colors.green
        : isCurrent
        ? Colors.orange.shade700
        : Colors.grey.shade300;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            step.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isCurrent ? Colors.orange.shade700 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int step) {
    bool isPrevCompleted = step < currentStep;
    bool isNextDivider = step == currentStep;

    if (isPrevCompleted) {
      return Expanded(child: Container(height: 4, color: Colors.green));
    } else if (isNextDivider) {
      return Expanded(
        child: Row(
          children: [
            Expanded(
              child: Container(height: 4, color: Colors.orange.shade700),
            ),
            Expanded(child: Container(height: 4, color: Colors.grey.shade300)),
          ],
        ),
      );
    } else {
      return Expanded(child: Container(height: 4, color: Colors.grey.shade300));
    }
  }

  // 🔹 Step 1 — Shipping Info
  Widget _buildStepOne() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Shipping Information",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            label: "Full Name",
            icon: Icons.person_outline,
            onSaved: (v) => fullName = v!,
            validator: (v) => v!.isEmpty ? "Enter your name" : null,
          ),
          _buildInputField(
            label: "Phone Number",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            onSaved: (v) => phone = v!,
            validator: (v) => v!.isEmpty ? "Enter phone number" : null,
          ),
          _buildInputField(
            label: "Address",
            icon: Icons.location_on_outlined,
            onSaved: (v) => address = v!,
            validator: (v) => v!.isEmpty ? "Enter address" : null,
          ),
          _buildInputField(
            label: "Division",
            icon: Icons.public_outlined,
            onSaved: (v) => division = v!,
            validator: (v) => v!.isEmpty ? "Enter division" : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
        onSaved: onSaved,
        keyboardType: keyboardType,
      ),
    );
  }

  // 🔹 Step 2 — Payment
  Widget _buildStepTwo(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final double subtotal = cart.totalAmount;
    const double shipping = 50.0;
    final double total = subtotal + shipping;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Payment Method",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => paymentMethod = 'cash_on_delivery'),
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: paymentMethod == 'cash_on_delivery'
                  ? Colors.green.withOpacity(0.08)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: paymentMethod == 'cash_on_delivery'
                    ? Colors.green
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.delivery_dining, color: Colors.green),
                SizedBox(width: 10),
                Text(
                  "Cash On Delivery",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Order Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow("Subtotal", "৳${subtotal.toStringAsFixed(2)}"),
              _buildSummaryRow(
                "Delivery Charge",
                "৳${shipping.toStringAsFixed(2)}",
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  Text(
                    "৳${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // 🔹 Step 3 — Review Order
  Widget _buildStepThree(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Order',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12), // Shipping & Payment Info Card
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shipping Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                '$fullName\n$address, $district, $division\nPhone: $phone',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const Divider(height: 20, thickness: 1),
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.delivery_dining,
                    color: Colors.green,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    paymentMethod == 'cash_on_delivery'
                        ? 'Cash On Delivery'
                        : 'Unknown',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ), // Items List
        ...cart.items.values.map((item) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                // Product Image / Placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    image: item.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: item.imageUrl.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 24,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12), // Name & Qty
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qty: ${item.quantity}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '৳${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const Divider(height: 30, thickness: 1), // Subtotal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Subtotal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '৳${cart.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12), // Shipping
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Shipping',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            Text('৳50.00', style: TextStyle(fontSize: 15, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 12), // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              '৳${(cart.totalAmount + 50).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 🔹 Step 4 — Order Success
  Widget _buildStepFour(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 50),
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.1),
          ),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 100),
        ),
        const SizedBox(height: 20),
        const Text(
          "Order Successfully Placed!",
          style: TextStyle(
            color: Colors.green,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "We’ll process your order shortly.",
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
            );
          },
          icon: const Icon(Icons.home_outlined),
          label: const Text("Back to Home"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  // 🔹 Submit Order (moves to Step 4 on success)
  Future<void> _submitOrder(BuildContext context) async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // simulate request
    setState(() {
      isLoading = false;
      currentStep = 4; // ✅ go to success step
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget stepContent;
    if (currentStep == 1) {
      stepContent = _buildStepOne();
    } else if (currentStep == 2) {
      stepContent = _buildStepTwo(context);
    } else if (currentStep == 3) {
      stepContent = _buildStepThree(context);
    } else {
      stepContent = _buildStepFour(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (currentStep < 4)
              Row(
                children: [
                  _buildStepIndicator(1, 'Address'),
                  _buildStepDivider(1),
                  _buildStepIndicator(2, 'Payment'),
                  _buildStepDivider(2),
                  _buildStepIndicator(3, 'Review'),
                ],
              ),
            const SizedBox(height: 20),
            stepContent,
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: currentStep == 4
          ? null
          : Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (currentStep == 1) {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              setState(() => currentStep = 2);
                            }
                          } else if (currentStep == 2) {
                            setState(() => currentStep = 3);
                          } else if (currentStep == 3) {
                            _submitOrder(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isLoading
                        ? 'Processing...'
                        : currentStep == 3
                        ? 'Confirm Order'
                        : 'Continue',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
