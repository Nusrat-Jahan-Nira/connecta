// lib/util/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'config.dart';

class ChatService {
  final String? authToken;
  final String supabaseUrl;
  final String supabaseKey;
  WebSocketChannel? _channel;
  final StreamController<List<Map<String, dynamic>>> _messagesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  List<Map<String, dynamic>> _messages = [];
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  String? _currentConversationId;

  ChatService({this.authToken})
      : supabaseUrl = SupabaseConfig.supabaseUrl,
        supabaseKey = SupabaseConfig.supabaseKey {
    _initWebSocket();
  }

  // // Get or create a conversation between two users
  // Future<String> getOrCreateConversation(String userIdA, String userIdB) async {
  //   try {
  //     // First check if a conversation already exists between these users
  //     final response = await http.get(
  //       Uri.parse('$supabaseUrl/rest/v1/conversation_participants?select=conversation_id&user_id=in.($userIdA,$userIdB)'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'apikey': supabaseKey,
  //         'Authorization': 'Bearer $authToken',
  //       },
  //     );
  //
  //     if (response.statusCode == 200) {
  //       List<dynamic> data = jsonDecode(response.body);
  //
  //       // Group by conversation_id and find one that has both users
  //       Map<String, int> counts = {};
  //       for (var item in data) {
  //         String convId = item['conversation_id'];
  //         counts[convId] = (counts[convId] ?? 0) + 1;
  //       }
  //
  //       for (var entry in counts.entries) {
  //         if (entry.value >= 2) {
  //           // Found a conversation with both users
  //           _currentConversationId = entry.key;
  //           return entry.key;
  //         }
  //       }
  //     }
  //
  //     // If no conversation exists, create a new one
  //     final createConvResponse = await http.post(
  //       Uri.parse('$supabaseUrl/rest/v1/conversations'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'apikey': supabaseKey,
  //         'Authorization': 'Bearer $authToken',
  //         'Prefer': 'return=representation',
  //       },
  //       body: jsonEncode({}),
  //     );
  //
  //     if (createConvResponse.statusCode == 201) {
  //       final conversationData = jsonDecode(createConvResponse.body)[0];
  //       String conversationId = conversationData['id'];
  //
  //       // Add both users to the conversation
  //       await http.post(
  //         Uri.parse('$supabaseUrl/rest/v1/conversation_participants'),
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'apikey': supabaseKey,
  //           'Authorization': 'Bearer $authToken',
  //         },
  //         body: jsonEncode([
  //           {'conversation_id': conversationId, 'user_id': userIdA},
  //           {'conversation_id': conversationId, 'user_id': userIdB}
  //         ]),
  //       );
  //
  //       _currentConversationId = conversationId;
  //       return conversationId;
  //     } else {
  //       throw Exception('Failed to create conversation: ${createConvResponse.body}');
  //     }
  //   } catch (e) {
  //     throw Exception('Error setting up conversation: $e');
  //   }
  // }

  // Future<String> getOrCreateConversation(String userIdA, String userIdB) async {
  //   try {
  //     // First check if a conversation already exists between these users
  //     final existingConversationResponse = await http.get(
  //       Uri.parse(
  //           '$supabaseUrl/rest/v1/conversation_participants?select=conversation_id,user_id&user_id=in.($userIdA,$userIdB)'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'apikey': supabaseKey,
  //         'Authorization': 'Bearer $authToken',
  //       },
  //     );
  //
  //     if (existingConversationResponse.statusCode == 200) {
  //       List<dynamic> data = jsonDecode(existingConversationResponse.body);
  //
  //       // Group by conversation_id to find conversations with both users
  //       Map<String, Set<String>> conversationsWithUsers = {};
  //
  //       for (var participant in data) {
  //         String convId = participant['conversation_id'];
  //         String userId = participant['user_id'];
  //
  //         if (!conversationsWithUsers.containsKey(convId)) {
  //           conversationsWithUsers[convId] = {};
  //         }
  //         conversationsWithUsers[convId]!.add(userId);
  //       }
  //
  //       // Find a conversation with exactly these two users
  //       for (var entry in conversationsWithUsers.entries) {
  //         if (entry.value.contains(userIdA) &&
  //             entry.value.contains(userIdB) &&
  //             entry.value.length == 2) {
  //           return entry.key;
  //         }
  //       }
  //     }
  //
  //     // Create a new conversation if none exists
  //     final createResponse = await http.post(
  //       Uri.parse('$supabaseUrl/rest/v1/conversations'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'apikey': supabaseKey,
  //         'Authorization': 'Bearer $authToken',
  //         'Prefer': 'return=representation'
  //       },
  //       body: jsonEncode({}),
  //     );
  //
  //     print(createResponse.statusCode.toString());
  //
  //     if (createResponse.statusCode != 201) {
  //       print('Failed to create conversation: ${createResponse.statusCode} - ${createResponse.body}');
  //       throw Exception('Failed to create conversation');
  //     }
  //
  //     // Extract the new conversation ID
  //     final conversationData = jsonDecode(createResponse.body);
  //     if (conversationData is List && conversationData.isNotEmpty) {
  //       final String conversationId = conversationData[0]['id'];
  //
  //       // Add both participants at once with a single request
  //       final participantsResponse = await http.post(
  //         Uri.parse('$supabaseUrl/rest/v1/conversation_participants'),
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'apikey': supabaseKey,
  //           'Authorization': 'Bearer $authToken',
  //           'Prefer': 'return=minimal',
  //         },
  //         body: jsonEncode([
  //           {
  //             'conversation_id': conversationId,
  //             'user_id': userIdA
  //           },
  //           {
  //             'conversation_id': conversationId,
  //             'user_id': userIdB
  //           }
  //         ]),
  //       );
  //
  //       if (participantsResponse.statusCode != 201) {
  //         print('Failed to add participants: ${participantsResponse.statusCode} - ${participantsResponse.body}');
  //         throw Exception('Failed to add participants to conversation');
  //       }
  //
  //       return conversationId;
  //     } else {
  //       throw Exception('Invalid response when creating conversation');
  //     }
  //   } catch (e) {
  //     print('Error in getOrCreateConversation: $e');
  //     throw Exception('Failed to create conversation: $e');
  //   }
  // }


  Future<String> getOrCreateConversation(String userIdA, String userIdB) async {
    try {
      // First check if a conversation already exists between these users
      final existingConversationResponse = await http.get(
        Uri.parse(
            '$supabaseUrl/rest/v1/conversation_participants?select=conversation_id,user_id&user_id=in.($userIdA,$userIdB)'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': 'Bearer $authToken',
        },
      );

      print('Existing conversation check status: ${existingConversationResponse.statusCode}');

      if (existingConversationResponse.statusCode == 200) {
        List<dynamic> data = jsonDecode(existingConversationResponse.body);
        print('Found ${data.length} participant records');

        // Group by conversation_id to find conversations with both users
        Map<String, Set<String>> conversationsWithUsers = {};

        for (var participant in data) {
          String convId = participant['conversation_id'];
          String userId = participant['user_id'];

          if (!conversationsWithUsers.containsKey(convId)) {
            conversationsWithUsers[convId] = {};
          }
          conversationsWithUsers[convId]!.add(userId);
        }

        // Find a conversation with exactly these two users
        for (var entry in conversationsWithUsers.entries) {
          if (entry.value.contains(userIdA) &&
              entry.value.contains(userIdB) &&
              entry.value.length == 2) {
            print('Found existing conversation: ${entry.key}');
            return entry.key;
          }
        }
      }

      print('Creating new conversation');

      // Use a stored function approach to avoid RLS recursion
      // Create a SQL function on Supabase to handle this operation
      final createConvWithParticipantsResponse = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/create_conversation_with_participants'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'user_id_a': userIdA,
          'user_id_b': userIdB
        }),
      );

      print('RPC response status: ${createConvWithParticipantsResponse.statusCode}');

      if (createConvWithParticipantsResponse.statusCode == 200) {
        final responseData = jsonDecode(createConvWithParticipantsResponse.body);
        print('Response from RPC: $responseData');
        return responseData['conversation_id'];
      } else {
        print('Failed to create conversation: ${createConvWithParticipantsResponse.statusCode} - ${createConvWithParticipantsResponse.body}');

        // Fallback approach: Create conversation with manual retry logic
        return await _createConversationWithRetry(userIdA, userIdB);
      }
    } catch (e) {
      print('Error in getOrCreateConversation: $e');
      throw Exception('Failed to create conversation: $e');
    }
  }

  Future<String> _createConversationWithRetry(String userIdA, String userIdB) async {
    // Create a new conversation
    final createResponse = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': 'Bearer $authToken',
        'Prefer': 'return=representation'
      },
      body: jsonEncode({}),
    );

    print('Create conversation response status: ${createResponse.statusCode}');

    if (createResponse.statusCode != 201) {
      print('Failed to create conversation: ${createResponse.statusCode} - ${createResponse.body}');
      throw Exception('Failed to create conversation');
    }

    // Extract the new conversation ID
    final conversationData = jsonDecode(createResponse.body);
    if (conversationData is List && conversationData.isNotEmpty) {
      final String conversationId = conversationData[0]['id'];
      print('Created conversation with ID: $conversationId');

      // Wait a moment before adding participants
      await Future.delayed(Duration(milliseconds: 1000));

      try {
        // Try a single request with both participants as a bulk insert
        final participantsResponse = await http.post(
          Uri.parse('$supabaseUrl/rest/v1/conversation_participants'),
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
            'Authorization': 'Bearer $authToken',
            'Prefer': 'resolution=ignore-duplicates',  // Try to ignore conflict errors
          },
          body: jsonEncode([
            {'conversation_id': conversationId, 'user_id': userIdA},
            {'conversation_id': conversationId, 'user_id': userIdB}
          ]),
        );

        print('Participants response: ${participantsResponse.statusCode}');

        // Even if there was an error, the inserts might have succeeded
        // Verify if participants were added
        final verifyResponse = await http.get(
          Uri.parse('$supabaseUrl/rest/v1/conversation_participants?conversation_id=eq.$conversationId&select=user_id'),
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
            'Authorization': 'Bearer $authToken',
          },
        );

        if (verifyResponse.statusCode == 200) {
          List<dynamic> data = jsonDecode(verifyResponse.body);
          if (data.length >= 2) {
            return conversationId;
          }
        }

        // If verification failed, add participants one by one as a fallback
        await _addParticipantsOneByOne(conversationId, userIdA, userIdB);
        return conversationId;
      } catch (e) {
        print('Error adding participants: $e');
        // Try adding participants one by one as a fallback
        await _addParticipantsOneByOne(conversationId, userIdA, userIdB);
        return conversationId;
      }
    } else {
      throw Exception('Invalid response when creating conversation');
    }
  }

  Future<void> _addParticipantsOneByOne(String conversationId, String userIdA, String userIdB) async {
    try {
      // Add first participant
      await http.post(
        Uri.parse('$supabaseUrl/rest/v1/conversation_participants'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': 'Bearer $authToken',
          'Prefer': 'resolution=ignore-duplicates',
        },
        body: jsonEncode({
          'conversation_id': conversationId,
          'user_id': userIdA
        }),
      );

      // Wait before adding second participant
      await Future.delayed(Duration(milliseconds: 500));

      // Add second participant
      await http.post(
        Uri.parse('$supabaseUrl/rest/v1/conversation_participants'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': 'Bearer $authToken',
          'Prefer': 'resolution=ignore-duplicates',
        },
        body: jsonEncode({
          'conversation_id': conversationId,
          'user_id': userIdB
        }),
      );
    } catch (e) {
      print('Error in _addParticipantsOneByOne: $e');
      // We'll still consider it potentially successful, as the client can retry if needed
    }
  }



  // Get user details
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$userId&select=*'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data[0];
        }
        return {'username': 'Unknown User'};
      } else {
        return {'username': 'Unknown User'};
      }
    } catch (e) {
      return {'username': 'Unknown User'};
    }
  }

  void _initWebSocket() {
    try {
      final wsUrl = supabaseUrl.replaceFirst('https://', '');
      final uri = Uri.parse('wss://$wsUrl/realtime/v1/websocket?apikey=$supabaseKey&vsn=1.0.0');

      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        _handleWebSocketMessage,
        onDone: _reconnect,
        onError: (_) => _reconnect()
      );

      Future.delayed(Duration(milliseconds: 500), () {
        _sendWebSocketMessage({
          "type": "phoenix",
          "event": "heartbeat",
          "payload": {},
          "ref": 1
        });
      });

      _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (_) {
        _sendWebSocketMessage({
          "type": "phoenix",
          "event": "heartbeat",
          "payload": {},
          "ref": 1
        });
      });

      _isConnected = true;
    } catch (e) {
      print('WebSocket connection error: $e');
      _reconnect();
    }
  }

  void subscribeToConversation(String? conversationId) {
    // If no conversation ID, just clear messages and return
    if (conversationId == null || conversationId.isEmpty) {
      _messages = [];
      _messagesController.add(_messages);
      return;
    }

    _currentConversationId = conversationId;

    _sendWebSocketMessage({
      "type": "postgres_changes",
      "event": "ACCESS_SUBSCRIBE",
      "payload": {
        "access_token": authToken,
        "callback": "",
        "config": {
          "event": "*",
          "schema": "public",
          "table": "messages",
          "filter": "conversation_id=eq.$conversationId"
        }
      },
      "ref": 2
    });

    // Load initial messages for this conversation
    getMessageHistory(conversationId).then((messages) {
      _messages = messages;
      _messagesController.add(_messages);
    });
  }

  // void subscribeToConversation(String conversationId) {
  //   _currentConversationId = conversationId;
  //
  //   _sendWebSocketMessage({
  //     "type": "postgres_changes",
  //     "event": "ACCESS_SUBSCRIBE",
  //     "payload": {
  //       "access_token": authToken,
  //       "callback": "",
  //       "config": {
  //         "event": "*",
  //         "schema": "public",
  //         "table": "messages",
  //         "filter": "conversation_id=eq.$conversationId"
  //       }
  //     },
  //     "ref": 2
  //   });
  //
  //   // Load initial messages for this conversation
  //   getMessageHistory(conversationId).then((messages) {
  //     _messages = messages;
  //     _messagesController.add(_messages);
  //   });
  // }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);

      if (data['event'] == 'postgres_changes' && data['payload'] != null) {
        if (_currentConversationId != null) {
          getMessageHistory(_currentConversationId!).then((messages) {
            _messages = messages;
            _messagesController.add(_messages);
          });
        }
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  void _sendWebSocketMessage(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        print('Error sending WebSocket message: $e');
      }
    }
  }

  void _reconnect() {
    _isConnected = false;
    _channel?.sink.close();
    _heartbeatTimer?.cancel();
    Future.delayed(Duration(seconds: 2), _initWebSocket);
  }


  Future<void> sendMessage(String userId, String username, String message, String conversationId) async {
    try {
      print('Attempting to send message via RPC function');

      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/insert_message'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseKey,
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'user_id_param': userId,
          'content_param': message,
          'username_param': username,
          'conversation_id_param': conversationId
        }),
      );

      print('Send message response: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Message send failed: ${response.body}');
        throw Exception('Failed to send message: ${response.body}');
      } else {
        print('Message sent successfully: ${response.body}');
      }
    } catch (e) {
      print('Exception in sendMessage: $e');
      rethrow;
    }
  }


  // // Send a message to a specific conversation
  // Future<void> sendMessage(String userId, String username, String message, String conversationId) async {
  //   final response = await http.post(
  //     Uri.parse('$supabaseUrl/rest/v1/messages'),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'apikey': supabaseKey,
  //       'Authorization': 'Bearer $authToken',
  //       'Prefer': 'return=minimal',
  //     },
  //     body: jsonEncode({
  //       'user_id': userId,
  //       'content': message,
  //       'created_at': DateTime.now().toIso8601String(),
  //       'username': username,
  //       'conversation_id': conversationId
  //     }),
  //   );
  //
  //   if (response.statusCode != 201) {
  //     throw Exception('Failed to send message: ${response.body}');
  //   }
  // }

  // Get messages for a specific conversation
  // Future<List<Map<String, dynamic>>> getMessageHistory(String conversationId) async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('$supabaseUrl/rest/v1/messages?conversation_id=eq.$conversationId&select=*&order=created_at.asc'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'apikey': supabaseKey,
  //         'Authorization': 'Bearer $authToken',
  //       },
  //     );
  //
  //     if (response.statusCode == 200) {
  //       List<dynamic> data = jsonDecode(response.body);
  //       return data.map((item) => Map<String, dynamic>.from(item)).toList();
  //     } else {
  //       print('Error response: ${response.body}');
  //       throw Exception('Failed to load message history: ${response.body}');
  //     }
  //   } catch (e) {
  //     print('Exception occurred: $e');
  //     throw Exception('Failed to load messages: $e');
  //   }
  // }

  // Future<List<Map<String, dynamic>>> getMessageHistory(String conversationId) async {
  //   try {
  //     // Direct SQL query to bypass RLS policies
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
  //       print('Error response from messages: ${response.statusCode} - ${response.body}');
  //       return []; // Return empty list instead of throwing
  //     }
  //   } catch (e) {
  //     print('Exception in getMessageHistory: $e');
  //     return []; // Return empty list instead of throwing
  //   }
  // }

  Future<List<Map<String, dynamic>>> getMessageHistory(String conversationId) async {
    try {
      // Check if conversationId is null or empty
      if (conversationId == null || conversationId.isEmpty) {
        print('No conversation ID provided');
        return []; // Return empty list for empty conversation
      }

      // Direct SQL query to bypass RLS policies
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
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        print('Error response from messages: ${response.statusCode} - ${response.body}');
        return []; // Return empty list instead of throwing
      }
    } catch (e) {
      print('Exception in getMessageHistory: $e');
      return []; // Return empty list instead of throwing
    }
  }

  // Get all users for contact list
  // Future<List<Map<String, dynamic>>> getAllUsers() async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('$supabaseUrl/rest/v1/profiles?select=id,username,email'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'apikey': supabaseKey,
  //         'Authorization': 'Bearer $authToken',
  //       },
  //     );
  //
  //     if (response.statusCode == 200) {
  //       List<dynamic> data = jsonDecode(response.body);
  //       return data.map((item) => Map<String, dynamic>.from(item)).toList();
  //     } else {
  //       throw Exception('Failed to load users: ${response.body}');
  //     }
  //   } catch (e) {
  //     throw Exception('Failed to load users: $e');
  //   }
  // }


  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/profiles?select=id,email,username'),
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
        throw Exception('Failed to load users: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load users: $e');
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




// // lib/util/chat_service.dart -- for one directional chatting
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'dart:async';
// import 'config.dart';
//
// class ChatService {
//   final String? authToken;
//   final String supabaseUrl;
//   final String supabaseKey;
//
//   ChatService({this.authToken})
//       : supabaseUrl = SupabaseConfig.supabaseUrl,
//         supabaseKey = SupabaseConfig.supabaseKey;
//
//   // Send a message to the chat
//   Future<void> sendMessage(String userId, String message) async {
//     final response = await http.post(
//       Uri.parse('$supabaseUrl/rest/v1/messages'),
//       headers: {
//         'Content-Type': 'application/json',
//         'apikey': supabaseKey,
//         'Authorization': 'Bearer $authToken',
//         'Prefer': 'return=minimal',
//       },
//       body: jsonEncode({
//         'user_id': userId,
//         'content': message,
//         'created_at': DateTime.now().toIso8601String(),
//       }),
//     );
//
//     if (response.statusCode != 201) {
//       throw Exception('Failed to send message: ${response.body}');
//     }
//   }
//
//   // Fetch message history
//   // Future<List<Map<String, dynamic>>> getMessageHistory() async {
//   //   final response = await http.get(
//   //     Uri.parse('$supabaseUrl/rest/v1/messages?select=*&order=created_at.asc'),
//   //     headers: {
//   //       'Content-Type': 'application/json',
//   //       'apikey': supabaseKey,
//   //       'Authorization': 'Bearer $authToken',
//   //     },
//   //   );
//   //
//   //   if (response.statusCode == 200) {
//   //     List<dynamic> data = jsonDecode(response.body);
//   //     return data.map((item) => Map<String, dynamic>.from(item)).toList();
//   //   } else {
//   //     throw Exception('Failed to load message history: ${response.body}');
//   //   }
//   // }
//   Future<List<Map<String, dynamic>>> getMessageHistory() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$supabaseUrl/rest/v1/messages?select=*&order=created_at.asc'),
//         headers: {
//           'Content-Type': 'application/json',
//           'apikey': supabaseKey,
//           'Authorization': 'Bearer $authToken',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         List<dynamic> data = jsonDecode(response.body);
//         return data.map((item) => Map<String, dynamic>.from(item)).toList();
//       } else {
//         print('Error response: ${response.body}');
//         throw Exception('Failed to load message history: ${response.body}');
//       }
//     } catch (e) {
//       print('Exception occurred: $e');
//       throw Exception('Failed to load messages: $e');
//     }
//   }
//
//   // For real-time updates, implement a polling mechanism
//   // This is a simplified approach without WebSockets
//   Stream<List<Map<String, dynamic>>> getMessagesStream() {
//     // Create a stream controller to emit message updates
//     StreamController<List<Map<String, dynamic>>> controller = StreamController<List<Map<String, dynamic>>>();
//
//     // Poll for messages every few seconds
//     Timer.periodic(Duration(seconds: 3), (timer) async {
//       try {
//         final messages = await getMessageHistory();
//         controller.add(messages);
//       } catch (e) {
//         controller.addError(e);
//       }
//     });
//
//     // Close the controller when the stream is no longer needed
//     controller.onCancel = () {
//       controller.close();
//     };
//
//     return controller.stream;
//   }
// }