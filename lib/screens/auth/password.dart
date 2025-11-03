import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:redpharmabd_app/providers/auth_provider.dart';
import 'package:redpharmabd_app/widgets/custom_snackbar.dart';
import 'package:redpharmabd_app/constants/default_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Theme to match your login screen
  final Color _green = const Color(0xFF22A45D);
  final Color _lightBorder = const Color(0xFFE6E9EF);

  // Live checklist flags
  bool get _hasMinLen => _newPasswordController.text.trim().length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_newPasswordController.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_newPasswordController.text);
  bool get _hasDigit => RegExp(r'\d').hasMatch(_newPasswordController.text);

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14),
      floatingLabelStyle: TextStyle(color: _green),
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
        borderSide: BorderSide(color: _green, width: 1.2),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();

      await auth.changePassword(
        newPassword: _newPasswordController.text.trim(),
        confirmPassword: _confirmPasswordController.text.trim(),
      );

      if (!mounted) return;

      AppSnackbar.show(
        context,
        message: 'Password changed successfully!',
        icon: Icons.check_circle_outline,
        backgroundColor: DefaultTheme.green,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      AppSnackbar.show(
        context,
        message: e.toString(),
        icon: Icons.error_outline,
        backgroundColor: DefaultTheme.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _checkItem(bool ok, String text) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: ok ? _green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: ok ? Colors.black87 : Colors.black54,
              fontWeight: ok ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool match =
        _confirmPasswordController.text == _newPasswordController.text &&
        _confirmPasswordController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Change Password",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _lightBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Update your account password",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // New Password
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        decoration: _inputDecoration(
                          label: 'New Password',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _obscureNew = !_obscureNew),
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (v) {
                          final val = v?.trim() ?? '';
                          if (val.isEmpty) return "Enter new password";
                          if (!_hasMinLen ||
                              !_hasUpper ||
                              !_hasLower ||
                              !_hasDigit) {
                            return "Password doesn’t meet the requirements";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Checklist
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _checkItem(_hasMinLen, "At least 8 characters"),
                            const SizedBox(height: 6),
                            _checkItem(
                              _hasUpper,
                              "At least one uppercase letter",
                            ),
                            const SizedBox(height: 6),
                            _checkItem(
                              _hasLower,
                              "At least one lowercase letter",
                            ),
                            const SizedBox(height: 6),
                            _checkItem(_hasDigit, "At least one number"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: _inputDecoration(
                          label: 'Confirm Password',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if ((v ?? '').isEmpty) {
                            return "Re-enter your new password";
                          }
                          if (v != _newPasswordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),

                      // Inline mismatch hint
                      if (!match && _confirmPasswordController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.error_outline,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Confirm password does not match",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 22),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Change Password",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
