import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:redpharmabd_app/providers/auth_provider.dart';
import 'package:redpharmabd_app/main.dart';
import 'package:redpharmabd_app/main_screen.dart';
import 'package:redpharmabd_app/widgets/custom_snackbar.dart';
import 'package:redpharmabd_app/constants/default_theme.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  File? _imageFile;
  final Color _lightBorder = const Color(0xFFE6E9EF);

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14),
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: DefaultTheme.green, width: 1.5),
      ),
      floatingLabelStyle: TextStyle(color: DefaultTheme.green),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (result != null) {
      setState(() => _imageFile = File(result.path));
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).register(
        fullName: _nameCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        password: _passwordCtrl.text,
        gender: _selectedGender!.toLowerCase(),
        passwordConfirmation: _confirmCtrl.text,
        imageFile: _imageFile,
      );

      if (!mounted) return;
      Navigator.pop(context);
      AppSnackbar.show(
        context,
        message: 'Account created successfully',
        icon: Icons.check_circle_outline,
        backgroundColor: DefaultTheme.green,
      );
    } catch (e) {
      AppSnackbar.show(
        context,
        message: 'Registration failed: ${e.toString()}',
        icon: Icons.check_circle_outline,
        backgroundColor: DefaultTheme.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 55,
                                  backgroundColor: const Color(0xFFECECEC),
                                  backgroundImage: _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : const NetworkImage(
                                          'https://redpharma-api.techrajshahi.com/images/guest-user.png',
                                        ),
                                ),
                                InkWell(
                                  onTap: _pickImage,
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: DefaultTheme.green,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Full Name
                          TextFormField(
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              label: 'Full Name',
                              icon: Icons.person_outline,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter your full name'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Mobile Number
                          TextFormField(
                            controller: _mobileCtrl,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              label: 'Mobile Number',
                              icon: Icons.phone_iphone,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Enter your mobile number';
                              final digits = v.replaceAll(RegExp(r'\D'), '');
                              if (digits.length < 8)
                                return 'Enter a valid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Gender Dropdown
                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              labelStyle: const TextStyle(fontSize: 14),
                              prefixIcon: const Icon(Icons.wc_outlined),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 18,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _lightBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: DefaultTheme.green,
                                  width: 1.5,
                                ),
                              ),
                              floatingLabelStyle: TextStyle(color: DefaultTheme.green),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedGender,
                                isExpanded: true,
                                hint: const Text('Select Gender'),
                                icon: const Icon(Icons.arrow_drop_down),
                                items: _genders
                                    .map(
                                      (gender) => DropdownMenuItem(
                                        value: gender,
                                        child: Text(gender),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGender = value;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          // Address
                          TextFormField(
                            controller: _addressCtrl,
                            keyboardType: TextInputType.multiline,
                            maxLines: 3,
                            decoration: _inputDecoration(
                              label: 'Address',
                              icon: Icons.location_on_outlined,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter your address'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Password
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure1,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              label: 'Password',
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure1 = !_obscure1),
                                icon: Icon(
                                  _obscure1
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Enter password';
                              if (v.length < 6) return 'At least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Confirm Password
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscure2,
                            decoration: _inputDecoration(
                              label: 'Confirm Password',
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure2 = !_obscure2),
                                icon: Icon(
                                  _obscure2
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Confirm your password';
                              if (v != _passwordCtrl.text)
                                return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),

                          // Submit
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      16,
                                      194,
                                      45,
                                    ),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MainScreen(key: mainScreenKey),
                                  ),
                                  (route) => false,
                                );
                                mainScreenKey.currentState?.switchToHomeTab();
                              },
                              icon: const Icon(Icons.home),
                              label: const Text('Return To Home'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  255,
                                  217,
                                  217,
                                ),
                                foregroundColor: const Color.fromARGB(
                                  255,
                                  164,
                                  34,
                                  34,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(
                                  color: Color.fromARGB(255, 242, 214, 214),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
