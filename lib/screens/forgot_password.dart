import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:redpharmabd_app/constants/default_theme.dart';
import 'package:redpharmabd_app/providers/auth_provider.dart';
import 'package:redpharmabd_app/widgets/custom_snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int currentStep = 1;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String mobile = '';
  String otp = '';
  String newPassword = '';
  String confirmPassword = '';

  bool isLoading = false;
  late Timer _timer;
  int _countdown = 60; // 60 seconds countdown
  bool _canResendOtp = false;

  @override
  void initState() {
    super.initState();
    _mobileController.text = mobile;
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _canResendOtp = false;
    _countdown = 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _canResendOtp = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    if (!_canResendOtp || mobile.isEmpty) return;

    setState(() => isLoading = true);

    try {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).requestPasswordReset(mobile);

      // Restart the timer
      _startTimer();

      AppSnackbar.show(
        context,
        message: "OTP has been resent to your mobile",
        icon: Icons.check_circle_outline,
        backgroundColor: DefaultTheme.green,
      );
    } catch (e, stack) {
      debugPrint("❌ resend OTP error: $e\n$stack");
      AppSnackbar.show(
        context,
        message: e.toString(),
        icon: Icons.error_outline,
        backgroundColor: DefaultTheme.red,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: Colors.green),
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6E9EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: DefaultTheme.green, width: 1.2),
      ),
    );
  }

  Widget _buildStepBar() {
    final steps = ["Mobile", "OTP & Password", "Success"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final stepNumber = index + 1;
        final isActive = currentStep == stepNumber;
        final isCompleted = currentStep > stepNumber;

        Color color;
        if (isCompleted)
          color = Colors.green;
        else if (isActive)
          color = Colors.orange;
        else
          color = Colors.grey.shade400;

        return Expanded(
          child: Column(
            children: [
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

  Future<void> _sendResetRequest() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    try {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).requestPasswordReset(mobile);

      if (!mounted) return;

      _mobileController.text = mobile;
      setState(() => currentStep = 2);

      _startTimer();

      AppSnackbar.show(
        context,
        message: "OTP has been sent to your email",
        icon: Icons.check_circle_outline,
        backgroundColor: DefaultTheme.green,
      );
    } catch (e, stack) {
      String errorMessage = "Something went wrong";

      try {
        final jsonStart = e.toString().indexOf('{');
        if (jsonStart != -1) {
          final jsonString = e.toString().substring(jsonStart);
          final Map<String, dynamic> data = jsonDecode(jsonString);
          if (data['message'] != null) {
            errorMessage = data['message'];
          }
        } else {
          errorMessage = e.toString();
        }
      } catch (_) {
        // fallback if parsing fails
        errorMessage = e.toString();
      }

      AppSnackbar.show(
        context,
        message: errorMessage,
        icon: Icons.error_outline,
        backgroundColor: DefaultTheme.red,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _verifyOtpAndResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (newPassword != confirmPassword) {
      AppSnackbar.show(
        context,
        message: "Passwords do not match",
        icon: Icons.error_outline,
        backgroundColor: DefaultTheme.red,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await Provider.of<AuthProvider>(context, listen: false).verifyOtpAndReset(
        mobile: mobile,
        otp: otp,
        password: _newPasswordController.text,
        password_confirmation: _confirmPasswordController.text,
      );
      if (!mounted) return;

      AppSnackbar.show(
        context,
        message: "Password reset successfully",
        icon: Icons.check_circle_outline,
        backgroundColor: DefaultTheme.green,
      );

      setState(() => currentStep = 3);
    } catch (e) {
      AppSnackbar.show(
        context,
        message: "Failed: ${e.toString()}",
        icon: Icons.error_outline,
        backgroundColor: DefaultTheme.red,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildStepContent() {
    if (currentStep == 1) {
      return Column(
        children: [
          TextFormField(
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              label: "Mobile Number",
              icon: Icons.phone_iphone,
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? "Enter mobile number" : null,
            onSaved: (v) => mobile = v!.trim(),
          ),
        ],
      );
    } else if (currentStep == 2) {
      return Column(
        children: [
          TextFormField(
            controller: _mobileController,
            decoration: _inputDecoration(
              label: "Mobile Number",
              icon: Icons.phone_iphone,
            ),
            readOnly: true,
          ),
          const SizedBox(height: 16),

          // OTP field
          TextFormField(
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(label: "OTP", icon: Icons.lock),
            validator: (v) => (v == null || v.isEmpty) ? "Enter OTP" : null,
            onSaved: (v) => otp = v!.trim(),
            autofillHints: const [
              AutofillHints.oneTimeCode,
            ], // prevents phone autofill
          ),
          const SizedBox(height: 16),

          // New password
          TextFormField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: _inputDecoration(
              label: "New Password",
              icon: Icons.key,
            ),
            validator: (v) => (v == null || v.length < 8)
                ? "Password must be at least 8 chars"
                : null,
            onSaved: (v) => newPassword = v!.trim(),
          ),
          const SizedBox(height: 16),

          // Confirm password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: _inputDecoration(
              label: "Confirm Password",
              icon: Icons.key,
            ),
            validator: (v) => (v != _newPasswordController.text)
                ? "Passwords do not match"
                : null,
            onSaved: (v) => confirmPassword = v!.trim(),
          ),
        ],
      );
    } else {
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
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Password Reset Successfully!",
            style: TextStyle(
              color: Colors.green,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Your password has been updated. You can now log in using your new credentials.",
            style: TextStyle(color: Colors.black54),
          ),
        ],
      );
    }
  }

  void _onBottomButtonPressed() {
    if (currentStep == 1) {
      _sendResetRequest();
    } else if (currentStep == 2) {
      _verifyOtpAndResetPassword();
    } else {
      Navigator.pop(context);
    }
  }

  String _getButtonText() {
    if (currentStep == 1) return "Send OTP";
    if (currentStep == 2) return "Reset Password";
    return "Back to Login";
  }

  String _formatCountdown() {
    final minutes = (_countdown ~/ 60).toString().padLeft(2, '0');
    final seconds = (_countdown % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildStepBar(),
                const SizedBox(height: 30),
                _buildStepContent(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Resend OTP button (only shown in step 2)
            if (currentStep == 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _canResendOtp ? _resendOtp : null,
                        icon: Icon(
                          Icons.refresh,
                          color: _canResendOtp
                              ? DefaultTheme.green
                              : Colors.grey,
                        ),
                        label: Text(
                          _canResendOtp
                              ? 'Resend OTP'
                              : 'Resend OTP in ${_formatCountdown()}',
                          style: TextStyle(
                            color: _canResendOtp
                                ? DefaultTheme.green
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: _canResendOtp
                                ? DefaultTheme.green
                                : Colors.grey.shade300,
                          ),
                          backgroundColor: _canResendOtp
                              ? DefaultTheme.green.withOpacity(0.1)
                              : Colors.grey.shade100,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Main action button
            ElevatedButton(
              onPressed: isLoading ? null : _onBottomButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: DefaultTheme.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                isLoading ? "Processing..." : _getButtonText(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
