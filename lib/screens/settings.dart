import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:redpharmabd_app/main.dart';
import 'package:redpharmabd_app/screens/auth/edit_profile.dart';
import 'package:redpharmabd_app/screens/auth/membership.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:redpharmabd_app/providers/auth_provider.dart';
import 'package:redpharmabd_app/screens/login_screen.dart';
import 'package:redpharmabd_app/screens/auth/password.dart';
import 'package:redpharmabd_app/screens/auth/orders.dart';
import 'package:redpharmabd_app/widgets/custom_snackbar.dart';
import 'package:redpharmabd_app/constants/default_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with RouteAware {
  String selectedLanguage = "English";
  bool _isRefreshing = false;
  double? totalSaved;

  Future<void> _refreshUser() async {
    if (!mounted || _isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      final auth = context.read<AuthProvider>();
      await auth.fetchUserData();
      await auth.fetchUserOrders();

      final orders = auth.orders ?? [];
      double saved = 0;
      for (var order in orders) {
        if (order['discount'] != null &&
            (order['discount']['amount'] ?? 0) > 0) {
          saved += order['discount']['amount'];
        }
      }
      if (mounted) {
        setState(() {
          totalSaved = saved > 0 ? saved : null;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshUser();
    });
  }

  @override
  void dispose() {
    _isRefreshing = false;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshUser());
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;

      AppSnackbar.show(
        context,
        message: 'Could not open $url',
        icon: Icons.check_circle_outline,
        backgroundColor: DefaultTheme.red,
      );
    }
  }

  void _openLoginScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    if (result == true && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.fetchUserData();
      if (!mounted) return;

      AppSnackbar.show(
        context,
        message: "Logged in successfully",
        icon: Icons.check_circle_outline,
        backgroundColor: DefaultTheme.green,
      );
    }
  }

  void _showLanguageDialog() {
    final languages = ["English", "Bangla"];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Language"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages
              .map(
                (lang) => RadioListTile<String>(
                  value: lang,
                  groupValue: selectedLanguage,
                  onChanged: (val) {
                    if (!mounted) return;
                    setState(() => selectedLanguage = val!);
                    Navigator.pop(context);
                  },
                  title: Text(lang),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.redAccent, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 22,
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isLoggedIn = auth.isLoggedIn;
        final userName = auth.userData?['name']?.isNotEmpty == true
            ? auth.userData!['name']
            : "Guest User";

        final membership = auth.membership?['name']?.isNotEmpty == true
            ? "${auth.membership!['name']} - ${auth.userData?['points']} Points"
            : "General Member";

        final avatarUrl = (auth.userData?['avator']?.isNotEmpty == true)
            ? auth.userData!['avator']
            : "https://redpharma-api.techrajshahi.com/images/guest-user.png";

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (mainScreenKey.currentState != null) {
                  mainScreenKey.currentState?.switchToHomeTab();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: const Text(
              'Settings',
              style: TextStyle(color: Colors.black87),
            ),
            backgroundColor: Colors.white,
            centerTitle: true,
            elevation: 0.5,
          ),
          bottomNavigationBar: null,
          body: RefreshIndicator(
            onRefresh: _refreshUser,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(avatarUrl),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isLoggedIn ? userName : "Welcome, $userName",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const SizedBox(height: 6),
                      if (isLoggedIn) ...[
                        Text(
                          membership,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (isLoggedIn && totalSaved != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade900,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.lightGreen.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              "Saved ৳ ${totalSaved!.toStringAsFixed(0)}", // now safe to use !
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: _openLoginScreen,
                            icon: const Icon(Icons.login),
                            label: const Text("Login"),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      if (isLoggedIn) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const EditProfileScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit Profile'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    foregroundColor: const Color(
                                      0xFF22A45D,
                                    ), // green text/icon
                                    backgroundColor: const Color(
                                      0xFFEFFAF3,
                                    ), // soft green bg
                                    side: const BorderSide(
                                      color: Color(0xFFD6F2E2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isLoggedIn) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await context.read<AuthProvider>().logout();
                                    if (!mounted) return;
                                    AppSnackbar.show(
                                      context,
                                      message: 'Logged Out',
                                      icon: Icons.check_circle_outline,
                                      backgroundColor: DefaultTheme.red,
                                    );
                                    await _refreshUser();
                                  },
                                  icon: const Icon(Icons.logout),
                                  label: const Text('Logout'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    foregroundColor: const Color(
                                      0xFFA42222,
                                    ), // red text/icon
                                    backgroundColor: const Color(
                                      0xFFFFD9D9,
                                    ), // soft red bg
                                    side: const BorderSide(
                                      color: Color(0xFFF2D6D6),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (isLoggedIn) ...[
                  _buildSectionTitle("Account"),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildOption(
                          icon: Icons.lock_outline,
                          title: "Change Password",
                          subtitle: "Update your account password",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          color: Colors.grey[100], // lighter color
                        ),
                        _buildOption(
                          icon: Icons.shopping_bag_outlined,
                          title: "My Orders",
                          subtitle: "Total orders: ${auth.orders!.length}",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyOrdersScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          color: Colors.grey[100], // lighter color
                        ),
                        _buildOption(
                          icon: Icons.verified_user_outlined,
                          title: "Membership",
                          subtitle: membership,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MembershipScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          color: Colors.grey[100], // lighter color
                        ),
                        _buildOption(
                          icon: Icons.privacy_tip_outlined,
                          title: "Delete Your Account",
                          onTap: () => _launchURL(
                            "https://redpharmabd.com/account-removal-request",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                _buildSectionTitle("Support"),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildOption(
                        icon: Icons.privacy_tip_outlined,
                        title: "Privacy Policy",
                        onTap: () => _launchURL(
                          "https://redpharmabd.com/privacy-and-policy",
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey[100]),
                      _buildOption(
                        icon: Icons.assignment_return_outlined,
                        title: "Refund & Returns",
                        onTap: () => _launchURL(
                          "https://redpharmabd.com/refund-and-returns",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
