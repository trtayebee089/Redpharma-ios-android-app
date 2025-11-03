import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:redpharmabd_app/main.dart';
import 'package:redpharmabd_app/providers/auth_provider.dart';
import 'package:redpharmabd_app/screens/registration.dart';
import 'package:redpharmabd_app/main_screen.dart';
import 'package:redpharmabd_app/widgets/custom_snackbar.dart';
import 'package:redpharmabd_app/constants/default_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String mobile = '';
  String password = '';
  bool isLoading = false;
  bool _obscure = true;
  final Color _lightBorder = const Color(0xFFE6E9EF);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);
    try {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).loginWithMobile(mobile, password);

      if (!mounted) return;
      Navigator.pop(context, true);
      
      AppSnackbar.show(
        context,
        message: "Logged in successfully",
        icon: Icons.check_circle_outline,
        backgroundColor: DefaultTheme.green,
      );
    } catch (e) {
      AppSnackbar.show(
        context,
        message: "Login failed: ${e.toString()}",
        icon: Icons.check_circle_outline,
        backgroundColor: DefaultTheme.red,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

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
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: DefaultTheme.green, width: 1.2),
      ),
    );
  }

  void _openRegistrationScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
    );

    if (result == true) {
      Provider.of<AuthProvider>(context, listen: false).fetchUserData();

      AppSnackbar.show(
        context,
        message: "Account created and logged in successfully",
        icon: Icons.check_circle_outline,
        backgroundColor: DefaultTheme.green,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

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
                  // <-- centers content vertically within available height
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity, // make inputs stretch full width
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo
                            const SizedBox(height: 24),
                            Center(
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 56,
                                fit: BoxFit.contain,
                              ),
                            ),

                            // EXTRA SPACE under the logo (tweak as you like)
                            const SizedBox(height: 36),

                            // Mobile / Email
                            TextFormField(
                              keyboardType: TextInputType.phone,
                              decoration:
                                  _inputDecoration(
                                    label: 'Mobile Number',
                                    icon: Icons.phone_iphone,
                                  ).copyWith(
                                    floatingLabelStyle: TextStyle(
                                      color: DefaultTheme.green,
                                    ),
                                  ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter your mobile number'
                                  : null,
                              onSaved: (v) => mobile = v!.trim(),
                            ),
                            const SizedBox(height: 12),

                            // Password
                            TextFormField(
                              obscureText: _obscure,
                              decoration:
                                  _inputDecoration(
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    suffix: IconButton(
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                    ),
                                  ).copyWith(
                                    floatingLabelStyle: TextStyle(
                                      color: DefaultTheme.green,
                                    ),
                                  ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Enter password'
                                  : null,
                              onSaved: (v) => password = v ?? '',
                            ),

                            const SizedBox(height: 18),

                            // Login
                            Row(
                              children: [
                                Expanded(
                                  child: isLoading
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : ElevatedButton(
                                          onPressed: _login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: DefaultTheme.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  // TODO: navigate to "forgot password"
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                ),
                                child: const Text(
                                  'Forgot your password?',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            const Text(
                              "You don't have an account?",
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _openRegistrationScreen,
                                icon: const Icon(Icons.add),
                                label: const Text('Create New Account'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEFFAF3),
                                  foregroundColor: DefaultTheme.green,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFD6F2E2),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

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
                                  foregroundColor: DefaultTheme.red,
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
              ),
            );
          },
        ),
      ),
    );
  }
}
