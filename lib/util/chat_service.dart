import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatService {
  final String? authToken;
  final String supabaseUrl;
  final String supabaseKey;
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  final _messagesController = StreamController<List<Map<String, dynamic>>>.broadcast();

  ChatService({this.authToken})
      : supabaseUrl = SupabaseConfig.supabaseUrl,
        supabaseKey = SupabaseConfig.supabaseKey;


  // Add this method to your ChatService class
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/profiles?select=id,username,email'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load users: ${response.body}');
      }
    } catch (e) {
      print('Exception in getAllUsers: $e');
      throw Exception('Failed to load users: $e');
    }
  }

  // Find or create a conversation between two users
  Future<String> getOrCreateConversation(String userId1, String userId2) async {
    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/find_or_create_conversation'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'user1_id': userId1,
          'user2_id': userId2
        }),
      );

      if (response.statusCode == 200) {
        return response.body.replaceAll('"', ''); // Returns just the UUID
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create conversation: ${response.body}');
      }
    } catch (e) {
      print('Exception in getOrCreateConversation: $e');
      throw Exception('Error creating conversation: $e');
    }
  }

  // Add this improved getMessageHistory method to your ChatService class
  Future<List<Map<String, dynamic>>> getMessageHistory(String conversationId) async {
    int retryCount = 0;
    const maxRetries = 3;
    const initialDelay = 1000; // ms

    while (retryCount < maxRetries) {
      try {
        if (conversationId.isEmpty) {
          return [];
        }

        final response = await http.post(
          Uri.parse('$supabaseUrl/rest/v1/rpc/get_messages_for_conversation'),
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({
            'conversation_id_param': conversationId
          }),
        ).timeout(const Duration(seconds: 15)); // Add timeout

        if (response.statusCode == 200) {
          List<dynamic> data = jsonDecode(response.body);
          return data.map((item) => Map<String, dynamic>.from(item)).toList();
        } else {
          print('Error response: ${response.statusCode} - ${response.body}');
          if (retryCount == maxRetries - 1) {
            return []; // Return empty list on final attempt instead of throwing
          }
        }
      } catch (e) {
        print('Exception in getMessageHistory: $e');
        if (retryCount == maxRetries - 1) {
          return []; // Return empty list on final attempt
        }
      }

      // Exponential backoff
      final delay = initialDelay * (1 << retryCount);
      await Future.delayed(Duration(milliseconds: delay));
      retryCount++;
    }

    return [];
  }

  // // Get messages for a specific conversation
  // Future<List<Map<String, dynamic>>> getMessageHistory(String conversationId) async {
  //   try {
  //     if (conversationId.isEmpty) {
  //       return [];
  //     }
  //
  //     final response = await http.post(
  //       Uri.parse('$supabaseUrl/rest/v1/rpc/get_messages_for_conversation'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'apikey': supabaseKey,
  //         'Authorization': 'Bearer $authToken',
  //       },
  //       body: jsonEncode({
  //         'conversation_id_param': conversationId
  //       }),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       List<dynamic> data = jsonDecode(response.body);
  //       return data.map((item) => Map<String, dynamic>.from(item)).toList();
  //     } else {
  //       print('Error response: ${response.statusCode} - ${response.body}');
  //       throw Exception('Failed to load messages: ${response.body}');
  //     }
  //   } catch (e) {
  //     print('Exception in getMessageHistory: $e');
  //     throw Exception('Failed to load messages: $e');
  //   }
  // }

  // Send a message in a specific conversation
  Future<void> sendMessage(String conversationId, String senderId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': 'Bearer $authToken',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'content': content
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream() {
    return _messagesController.stream;
  }

  void dispose() {
    _isConnected = false;
    _channel?.sink.close();
    _heartbeatTimer?.cancel();
    _messagesController.close();
  }
}

//
// // // lib/util/chat_service.dart -- for one directional chatting
// // import 'dart:convert';
// // import 'package:http/http.dart' as http;
// // import 'dart:async';
// // import 'config.dart';
// //
// // class ChatService {
// //   final String? authToken;
// //   final String supabaseUrl;
// //   final String supabaseKey;
// //
// //   ChatService({this.authToken})
// //       : supabaseUrl = SupabaseConfig.supabaseUrl,
// //         supabaseKey = SupabaseConfig.supabaseKey;
// //
// //   // Send a message to the chat
// //   Future<void> sendMessage(String userId, String message) async {
// //     final response = await http.post(
// //       Uri.parse('$supabaseUrl/rest/v1/messages'),
// //       headers: {
// //         'Content-Type': 'application/json',
// //         'apikey': supabaseKey,
// //         'Authorization': 'Bearer $authToken',
// //         'Prefer': 'return=minimal',
// //       },
// //       body: jsonEncode({
// //         'user_id': userId,
// //         'content': message,
// //         'created_at': DateTime.now().toIso8601String(),
// //       }),
// //     );
// //
// //     if (response.statusCode != 201) {
// //       throw Exception('Failed to send message: ${response.body}');
// //     }
// //   }
// //
// //   // Fetch message history
// //   // Future<List<Map<String, dynamic>>> getMessageHistory() async {
// //   //   final response = await http.get(
// //   //     Uri.parse('$supabaseUrl/rest/v1/messages?select=*&order=created_at.asc'),
// //   //     headers: {
// //   //       'Content-Type': 'application/json',
// //   //       'apikey': supabaseKey,
// //   //       'Authorization': 'Bearer $authToken',
// //   //     },
// //   //   );
// //   //
// //   //   if (response.statusCode == 200) {
// //   //     List<dynamic> data = jsonDecode(response.body);
// //   //     return data.map((item) => Map<String, dynamic>.from(item)).toList();
// //   //   } else {
// //   //     throw Exception('Failed to load message history: ${response.body}');
// //   //   }
// //   // }
// //   Future<List<Map<String, dynamic>>> getMessageHistory() async {
// //     try {
// //       final response = await http.get(
// //         Uri.parse('$supabaseUrl/rest/v1/messages?select=*&order=created_at.asc'),
// //         headers: {
// //           'Content-Type': 'application/json',
// //           'apikey': supabaseKey,
// //           'Authorization': 'Bearer $authToken',
// //         },
// //       );
// //
// //       if (response.statusCode == 200) {
// //         List<dynamic> data = jsonDecode(response.body);
// //         return data.map((item) => Map<String, dynamic>.from(item)).toList();
// //       } else {
// //         print('Error response: ${response.body}');
// //         throw Exception('Failed to load message history: ${response.body}');
// //       }
// //     } catch (e) {
// //       print('Exception occurred: $e');
// //       throw Exception('Failed to load messages: $e');
// //     }
// //   }
// //
// //   // For real-time updates, implement a polling mechanism
// //   // This is a simplified approach without WebSockets
// //   Stream<List<Map<String, dynamic>>> getMessagesStream() {
// //     // Create a stream controller to emit message updates
// //     StreamController<List<Map<String, dynamic>>> controller = StreamController<List<Map<String, dynamic>>>();
// //
// //     // Poll for messages every few seconds
// //     Timer.periodic(Duration(seconds: 3), (timer) async {
// //       try {
// //         final messages = await getMessageHistory();
// //         controller.add(messages);
// //       } catch (e) {
// //         controller.addError(e);
// //       }
// //     });
// //
// //     // Close the controller when the stream is no longer needed
// //     controller.onCancel = () {
// //       controller.close();
// //     };
// //
// //     return controller.stream;
// //   }
// // }