import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class DatabaseService {
  final String? authToken;

  DatabaseService({this.authToken});

  // Get data from a table
  Future<List<dynamic>> getRecords(String tableName) async {
    try {
      final response = await http.get(
        Uri.parse('${SupabaseConfig.supabaseUrl}/rest/v1/$tableName'),
        headers: {
          'apikey': SupabaseConfig.supabaseKey,
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.body}');
      }
    } catch (e) {
      print('Error getting records: $e');
      return [];
    }
  }

  // Insert data into a table
  Future<Map<String, dynamic>> insertRecord(String tableName, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${SupabaseConfig.supabaseUrl}/rest/v1/$tableName'),
        headers: {
          'apikey': SupabaseConfig.supabaseKey,
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body)[0];
      } else {
        throw Exception('Failed to insert data: ${response.body}');
      }
    } catch (e) {
      print('Error inserting record: $e');
      return {'error': e.toString()};
    }
  }
}