// lib/util/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'config.dart';

class ChatService {
  final String? authToken;
  final String supabaseUrl;
  final String supabaseKey;

  ChatService({this.authToken})
      : supabaseUrl = SupabaseConfig.supabaseUrl,
        supabaseKey = SupabaseConfig.supabaseKey;

  // Send a message to the chat
  Future<void> sendMessage(String userId, String message) async {
    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': 'Bearer $authToken',
        'Prefer': 'return=minimal',
      },
      body: jsonEncode({
        'user_id': userId,
        'content': message,
        'created_at': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  // Fetch message history
  // Future<List<Map<String, dynamic>>> getMessageHistory() async {
  //   final response = await http.get(
  //     Uri.parse('$supabaseUrl/rest/v1/messages?select=*&order=created_at.asc'),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'apikey': supabaseKey,
  //       'Authorization': 'Bearer $authToken',
  //     },
  //   );
  //
  //   if (response.statusCode == 200) {
  //     List<dynamic> data = jsonDecode(response.body);
  //     return data.map((item) => Map<String, dynamic>.from(item)).toList();
  //   } else {
  //     throw Exception('Failed to load message history: ${response.body}');
  //   }
  // }
  Future<List<Map<String, dynamic>>> getMessageHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/messages?select=*&order=created_at.asc'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to load message history: ${response.body}');
      }
    } catch (e) {
      print('Exception occurred: $e');
      throw Exception('Failed to load messages: $e');
    }
  }

  // For real-time updates, implement a polling mechanism
  // This is a simplified approach without WebSockets
  Stream<List<Map<String, dynamic>>> getMessagesStream() {
    // Create a stream controller to emit message updates
    StreamController<List<Map<String, dynamic>>> controller = StreamController<List<Map<String, dynamic>>>();

    // Poll for messages every few seconds
    Timer.periodic(Duration(seconds: 3), (timer) async {
      try {
        final messages = await getMessageHistory();
        controller.add(messages);
      } catch (e) {
        controller.addError(e);
      }
    });

    // Close the controller when the stream is no longer needed
    controller.onCancel = () {
      controller.close();
    };

    return controller.stream;
  }
}