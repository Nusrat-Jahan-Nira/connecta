import 'dart:convert';
import 'package:http/http.dart' as http;

import 'config.dart';


class AuthService {
  // Sign Up endpoint
  Future<Map<String, dynamic>> signUp(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${SupabaseConfig.supabaseUrl}/auth/v1/signup'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': SupabaseConfig.supabaseKey,
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Sign In endpoint
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${SupabaseConfig.supabaseUrl}/auth/v1/token?grant_type=password'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': SupabaseConfig.supabaseKey,
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${SupabaseConfig.supabaseUrl}/auth/v1/user'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': SupabaseConfig.supabaseKey,
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}