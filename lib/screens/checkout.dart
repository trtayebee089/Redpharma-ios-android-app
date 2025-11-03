import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:redpharmabd_app/providers/cart_provider.dart';
import 'package:redpharmabd_app/main_screen.dart';
import 'package:redpharmabd_app/constants/api_endpoints.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int currentStep = 1;
  final _formKey = GlobalKey<FormState>();

  String fullName = '';
  String phone = '';
  String address = '';
  String? division;
  String? district;
  String paymentMethod = 'cash_on_delivery';
  bool isLoading = false;

  List<dynamic> zones = [];
  List<String> divisions = [];
  List<Map<String, dynamic>> districts = [];
  double shippingRate = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchShippingZones();
  }

  Future<void> _fetchShippingZones() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.shippingZones));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List zonesData = data['data'];
          final Set<String> uniqueDivisions = zonesData
              .map((z) => z['division'] as String)
              .toSet();
          setState(() {
            zones = zonesData;
            divisions = uniqueDivisions.toList();
          });
        }
      } else {
        debugPrint("❌ Failed to load shipping zones");
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching zones: $e");
    }
  }

  void _onDivisionSelected(String selectedDivision) {
    final filteredDistricts = zones
        .where((z) => z['division'] == selectedDivision)
        .map(
          (z) => {
            'district': z['district'],
            'rate': double.tryParse(z['rate'].toString()) ?? 0.0,
          },
        )
        .toList();

    setState(() {
      division = selectedDivision;
      districts = filteredDistricts;
      district = null;
      shippingRate = 0.0;
    });
  }

  void _onDistrictSelected(String selectedDistrict) {
    final districtData = districts.firstWhere(
      (d) => d['district'] == selectedDistrict,
      orElse: () => {},
    );
    setState(() {
      district = selectedDistrict;
      shippingRate = districtData['rate'] ?? 0.0;
    });
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

  // STEP 1
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
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "Division",
              prefixIcon: const Icon(Icons.public_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            value: division,
            items: divisions
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (val) => _onDivisionSelected(val!),
            validator: (v) => v == null ? "Select division" : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "District",
              prefixIcon: const Icon(Icons.map_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            value: district,
            items: districts
                .map(
                  (d) => DropdownMenuItem<String>(
                    value: d['district'] as String,
                    child: Text(d['district'] as String),
                  ),
                )
                .toList(),
            onChanged: (val) => _onDistrictSelected(val!),
            validator: (v) => v == null ? "Select district" : null,
          ),
        ],
      ),
    );
  }

  // STEP 2
  Widget _buildStepTwo(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final double subtotal = cart.totalAmount;
    final double total = subtotal + shippingRate;

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
                "Shipping",
                "৳${shippingRate.toStringAsFixed(2)}",
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

  Widget _buildStepFour(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
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
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              cart.clearCart();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.home),
            label: const Text('Back To Home'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              foregroundColor: const Color.fromARGB(255, 34, 164, 34), // red text/icon
              backgroundColor: const Color.fromARGB(255, 204, 255, 180), // soft red bg
              side: const BorderSide(color: Color.fromARGB(255, 204, 255, 180)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitOrder(BuildContext context) async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      isLoading = false;
      currentStep = 4;
    });
  }

  Widget _buildCenteredStepBar() {
    final steps = ["Information", "Payment", "Review"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final stepNumber = index + 1;
        final isCompleted = currentStep > stepNumber;
        final isActive = currentStep == stepNumber;

        Color color;
        if (isCompleted) {
          color = Colors.green;
        } else if (isActive) {
          color = Colors.orange;
        } else {
          color = Colors.grey.shade400;
        }

        return Expanded(
          child: Column(
            children: [
              // Circle and line
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 0
                          ? Colors.transparent
                          : (isCompleted ? Colors.green : Colors.grey.shade300),
                    ),
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color,
                    child: Text(
                      '$stepNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == steps.length - 1
                          ? Colors.transparent
                          : (currentStep > stepNumber
                                ? Colors.green
                                : Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive || isCompleted ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepThree(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final double subtotal = cart.totalAmount;
    final double total = subtotal + shippingRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Review Your Order",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),

        // Medicines List
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
                "Items in your cart",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...cart.items.values.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${item.name} x${item.quantity}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        "৳${(item.price * item.quantity).toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Order Summary
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
              _buildSummaryRow("Subtotal", "৳${subtotal.toStringAsFixed(2)}"),
              _buildSummaryRow(
                "Shipping",
                "৳${shippingRate.toStringAsFixed(2)}",
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

  @override
  Widget build(BuildContext context) {
    Widget stepContent;
    if (currentStep == 1) {
      stepContent = _buildStepOne();
    } else if (currentStep == 2) {
      stepContent = _buildStepTwo(context);
    } else if (currentStep == 3) {
      stepContent = _buildStepThree(context); // New Review step
    } else if (currentStep == 4) {
      stepContent = _buildStepFour(context);
    } else {
      stepContent = const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
            _buildCenteredStepBar(),
            const SizedBox(height: 30),
            stepContent,
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
                        : currentStep == 2
                        ? 'Review Order'
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
