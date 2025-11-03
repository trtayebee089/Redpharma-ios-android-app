import 'dart:convert';
import 'dart:io'; // <-- for File
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redpharmabd_app/constants/api_endpoints.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  List<dynamic>? _rewardTiers;
  Map<String, dynamic>? _membership;
  List<dynamic>? _orders;
  String? _token;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userData => _userData;
  List<dynamic>? get rewardTiers => _rewardTiers;
  Map<String, dynamic>? get membership => _membership;
  List<dynamic>? get orders => _orders;
  String? get token => _token;

  String get userName => _userData?['name'] ?? '';
  String get avatarUrl => _userData?['avator'] ?? '';
  String get membershipName => _membership?['name'] ?? '';
  String get membershipColor => _membership?['color_code'] ?? '';

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    notifyListeners();
  }

  Future<void> _persistToken(String? t) async {
    final prefs = await SharedPreferences.getInstance();
    if (t == null || t.isEmpty) {
      await prefs.remove('token');
    } else {
      await prefs.setString('token', t);
    }
  }

  void _applyAuthPayload(Map<String, dynamic> data, {String? overrideToken}) {
    _userData = data['user'];
    _rewardTiers = data['reward_tiers'] is List
        ? data['reward_tiers']
        : (data['reward_tiers']?['Illuminate\\Database\\Eloquent\\Collection'] ??
              []);
    _membership = data['membership'] is Map
        ? (data['membership']['App\\Models\\RewardPointTier'] ??
              data['membership'])
        : null;
    _orders = data['orders'] is List
        ? data['orders']
        : (data['orders']?['Illuminate\\Database\\Eloquent\\Collection'] ?? []);
    _token = overrideToken ?? data['token'];
    _isLoggedIn = true;
  }

  String _extractMessage(http.Response resp) {
    try {
      final body = jsonDecode(resp.body);
      if (body is Map) {
        if (body['message'] is String) return body['message'];
        if (body['error'] is String) return body['error'];
        if (body['errors'] is Map) {
          final first = (body['errors'] as Map).values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
      }
    } catch (_) {}
    return 'Something went wrong (${resp.statusCode}).';
  }

  Future<void> loginWithMobile(String mobile, String password) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.login),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'phone_number': mobile, 'password': password}),
    );
    print(jsonDecode(response.body));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _applyAuthPayload(data);
      await _persistToken(_token);
      notifyListeners();
    } else {
      throw Exception(_extractMessage(response));
    }
  }

  Future<void> register({
    required String fullName,
    required String mobile,
    required String address,
    required String password,
    required String gender,
    required String passwordConfirmation,
    File? imageFile,
  }) async {
    http.Response? regularResponse;

    if (imageFile != null) {
      final uri = Uri.parse(ApiEndpoints.register);
      final req = http.MultipartRequest('POST', uri);

      req.fields['name'] = fullName;
      req.fields['phone_number'] = mobile;
      req.fields['address'] = address;
      req.fields['gender'] = gender;
      req.fields['password'] = password;
      req.fields['password_confirmation'] = passwordConfirmation;

      final file = await http.MultipartFile.fromPath('image', imageFile.path);
      req.files.add(file);
      req.headers.addAll({'Accept': 'application/json'});

      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        _applyAuthPayload(data);
        await _persistToken(_token);
        notifyListeners();
      } else {
        throw Exception(_extractMessage(resp));
      }
    } else {
      regularResponse = await http.post(
        Uri.parse(ApiEndpoints.register),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': fullName,
          'phone_number': mobile,
          'gender': gender,
          'address': address,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (regularResponse.statusCode == 200 ||
          regularResponse.statusCode == 201) {
        final data = jsonDecode(regularResponse.body);
        _applyAuthPayload(data);
        await _persistToken(_token);
        notifyListeners();
      } else {
        throw Exception(_extractMessage(regularResponse));
      }
    }
  }

  Future<void> fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');

    if (savedToken == null) {
      _isLoggedIn = false;
      notifyListeners();
      return;
    }

    final response = await http.get(
      Uri.parse(ApiEndpoints.userProfile),
      headers: {
        'Authorization': 'Bearer $savedToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      _userData = null;
      if (data['user'] != null && data['user'] is Map<String, dynamic>) {
        _userData = data['user'];
      }

      _rewardTiers = [];
      if (data['reward_tiers'] != null && data['reward_tiers'] is List) {
        _rewardTiers = List<Map<String, dynamic>>.from(data['reward_tiers']);
      }

      _orders = [];
      if (data['orders'] != null && data['orders'] is List) {
        _orders = List<Map<String, dynamic>>.from(data['orders']);
      }

      _membership = null;
      if (data['membership'] != null &&
          data['membership'] is Map<String, dynamic>) {
        _membership = data['membership'];
      }

      _isLoggedIn = true;
      notifyListeners();
    } else {
      _isLoggedIn = false;
      _token = null;
      await _persistToken(null);
    }

    notifyListeners();
  }

  Future<bool> changePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      if (_token == null || _token!.isEmpty) {
        print("Token: $token");
        throw Exception("User not logged in");
      }

      final url = Uri.parse(ApiEndpoints.changePassword);
      print('ChangePassword URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'newPassword': newPassword,
          'newPassword_confirmation': confirmPassword,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Try to decode JSON safely
      final data = response.body.startsWith('{')
          ? jsonDecode(response.body)
          : null;

      if (response.statusCode == 200 &&
          data != null &&
          data['success'] == true) {
        return true;
      } else if (response.statusCode == 422 && data != null) {
        throw Exception(data['errors'].values.join(', '));
      } else if (data != null) {
        throw Exception(data['message'] ?? 'Password update failed');
      } else {
        throw Exception('Unexpected server response (HTML received)');
      }
    } catch (e) {
      debugPrint("Change password error: $e");
      rethrow;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phone_number,
    required String gender,
    required String address,
    File? imageFile,
  }) async {
    try {
      final userId = _userData?['id'];
      if (userId == null) throw Exception("User not logged in");

      final url = Uri.parse(ApiEndpoints.updateProfile);
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        })
        ..fields['id'] = userId.toString()
        ..fields['name'] = name
        ..fields['phone_number'] = phone_number
        ..fields['email'] = email
        ..fields['gender'] = gender.toLowerCase()
        ..fields['address'] = address;

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('avatar', imageFile.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _userData = data['data']; // Laravel returns `data`, not `user`
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("🔴 Update profile error: $e");
      return false;
    }
  }

  Future<void> fetchUserOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('token');

      if (savedToken == null) {
        _orders = [];
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.userOrders),
        headers: {
          'Authorization': 'Bearer $savedToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] is List) {
          _orders = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          // In case API directly returns a list
          _orders = List<Map<String, dynamic>>.from(data);
        } else {
          _orders = [];
        }

        notifyListeners();
      } else {
        debugPrint("🔴 Failed to fetch orders: ${response.statusCode}");
        _orders = [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint("🔴 Error fetching orders: $e");
      _orders = [];
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _persistToken(null);
    _isLoggedIn = false;
    _userData = null;
    _rewardTiers = null;
    _membership = null;
    _orders = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }
}
