// // lib/presentation/view/chat_screen.dart
import 'package:flutter/material.dart';
import '../../util/chat_service.dart';
import 'dart:async';
// lib/presentation/view/chat_screen.dart
import 'package:flutter/material.dart';
import '../../util/chat_service.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../../util/chat_service.dart';
import 'dart:async';
import 'dart:ui';


class ChatScreen extends StatefulWidget {
  final String userId;
  final String username;
  final String? authToken;
  final String conversationId;
  final String otherUsername;

  ChatScreen({
    required this.userId,
    required this.username,
    required this.conversationId,
    required this.otherUsername,
    this.authToken,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatService _chatService;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(authToken: widget.authToken);
    _loadMessages();

    _refreshTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.getMessageHistory(widget.conversationId);

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    try {
      await _chatService.sendMessage(
        widget.conversationId,
        widget.userId,
        message,
      );
      _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027), // Dark teal
              Color(0xFF203A43), // Mid navy
              Color(0xFF2C5364), // Deep ocean blue
            ],
          ),
        ),
        child: Column(
          children: [
            // App bar
            SafeArea(
              bottom: false,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CircleAvatar(
                      backgroundColor: Color(0xFFFF7E5F),
                      child: Text(
                        widget.otherUsername[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.otherUsername,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Online',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.call, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // Messages area
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7E5F)),
                    ))
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 80,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Say hello to start the conversation',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            // Background pattern overlay
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.05,
                                child: ShaderMask(
                                  shaderCallback: (rect) {
                                    return LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.black, Colors.transparent],
                                    ).createShader(rect);
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: Image.network(
                                    'https://i.imgur.com/NvFpJJh.png', // Abstract pattern
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),

                            // Messages
                            ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final isMe = message['sender_id'] == widget.userId;
                                final showAvatar = !isMe && (index == 0 ||
                                    _messages[index - 1]['sender_id'] != message['sender_id']);

                                return Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!isMe && showAvatar) ...[
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Color(0xFFFF7E5F),
                                          child: Text(
                                            widget.otherUsername[0].toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                      ] else if (!isMe) ...[
                                        SizedBox(width: 40),
                                      ],

                                      Flexible(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            gradient: isMe
                                              ? LinearGradient(
                                                  colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : null,
                                            color: isMe ? null : Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(18),
                                            border: !isMe ? Border.all(
                                              color: Colors.white.withOpacity(0.1),
                                              width: 0.5,
                                            ) : null,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                message['content'],
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                _formatTime(message['created_at']),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white.withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      if (isMe) SizedBox(width: 40),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
            ),

            // Message input area
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.add_circle_outline, color: Colors.white.withOpacity(0.7)),
                          onPressed: () {},
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              style: TextStyle(color: Colors.white),
                              maxLines: null,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF7E5F).withOpacity(0.4),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.send, color: Colors.white, size: 20),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeString = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (messageDate == today) {
      return timeString;
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday, $timeString';
    } else {
      return '${dateTime.day}/${dateTime.month}, $timeString';
    }
  }
}












//2
// // lib/presentation/view/chat_screen.dart
// import 'package:flutter/material.dart';
// import '../../util/chat_service.dart';
// import 'dart:async';
// // lib/presentation/view/chat_screen.dart
// import 'package:flutter/material.dart';
// import '../../util/chat_service.dart';
// import 'dart:async';
//
// class ChatScreen extends StatefulWidget {
//   final String userId;
//   final String username;
//   final String? authToken;
//   final String conversationId;
//   final String otherUsername;
//
//   ChatScreen({
//     required this.userId,
//     required this.username,
//     required this.conversationId,
//     required this.otherUsername,
//     this.authToken,
//   });
//
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   late ChatService _chatService;
//   List<Map<String, dynamic>> _messages = [];
//   bool _isLoading = true;
//   Timer? _refreshTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _chatService = ChatService(authToken: widget.authToken);
//     _loadMessages();
//
//     // Refresh messages every few seconds
//     _refreshTimer = Timer.periodic(Duration(seconds: 3), (timer) {
//       _loadMessages();
//     });
//   }
//
//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     _refreshTimer?.cancel();
//     super.dispose();
//   }
//
//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }
//
//   Future<void> _loadMessages() async {
//     try {
//       final messages = await _chatService.getMessageHistory(widget.conversationId);
//
//       setState(() {
//         _messages = messages;
//         _isLoading = false;
//       });
//
//       // Scroll to bottom after layout is complete
//       WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading messages: $e')),
//       );
//     }
//   }
//
//   Future<void> _sendMessage() async {
//     final message = _messageController.text.trim();
//     if (message.isEmpty) return;
//
//     _messageController.clear();
//
//     try {
//       await _chatService.sendMessage(
//         widget.conversationId,
//         widget.userId,
//         message,
//       );
//
//       // Reload messages immediately after sending
//       _loadMessages();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error sending message: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.otherUsername),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: _isLoading
//                 ? Center(child: CircularProgressIndicator())
//                 : _messages.isEmpty
//                     ? Center(child: Text('No messages yet'))
//                     : ListView.builder(
//                         controller: _scrollController,
//                         itemCount: _messages.length,
//                         itemBuilder: (context, index) {
//                           final message = _messages[index];
//                           final isMe = message['sender_id'] == widget.userId;
//
//                           return Align(
//                             alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                             child: Container(
//                               margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                               padding: EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: isMe ? Colors.blue[100] : Colors.grey[200],
//                                 borderRadius: BorderRadius.circular(15),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     message['content'],
//                                     style: TextStyle(fontSize: 16),
//                                   ),
//                                   SizedBox(height: 5),
//                                   Text(
//                                     DateTime.parse(message['created_at']).toString().substring(0, 16),
//                                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: 'Type a message...',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(25),
//                       ),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 IconButton(
//                   icon: Icon(Icons.send),
//                   onPressed: _sendMessage,
//                   color: Theme.of(context).primaryColor,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }








// -- previous
// class ChatScreen extends StatefulWidget {
//   final String userId;
//   final String username;
//   final String? authToken;
//   final String conversationId;
//   final String otherUsername;
//
//   ChatScreen({
//     required this.userId,
//     required this.username,
//     required this.conversationId,
//     required this.otherUsername,
//     this.authToken,
//   });
//
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   late ChatService _chatService;
//   List<Map<String, dynamic>> _messages = [];
//   bool _isLoading = true;
//   Timer? _refreshTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _chatService = ChatService(authToken: widget.authToken);
//     _loadMessages();
//
//     // Refresh messages every few seconds
//     _refreshTimer = Timer.periodic(Duration(seconds: 3), (timer) {
//       _loadMessages();
//     });
//   }
//
//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     _refreshTimer?.cancel();
//     super.dispose();
//   }
//
//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }
//
//   Future<void> _loadMessages() async {
//     try {
//       final messages = await _chatService.getMessageHistory(widget.conversationId);
//
//       setState(() {
//         _messages = messages;
//         _isLoading = false;
//       });
//
//       // Scroll to bottom after layout is complete
//       WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading messages: $e')),
//       );
//     }
//   }
//
//   Future<void> _sendMessage() async {
//     final message = _messageController.text.trim();
//     if (message.isEmpty) return;
//
//     _messageController.clear();
//
//     try {
//       await _chatService.sendMessage(
//         widget.conversationId,
//         widget.userId,
//         message,
//       );
//
//       // Reload messages immediately after sending
//       _loadMessages();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error sending message: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.otherUsername),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: _isLoading
//                 ? Center(child: CircularProgressIndicator())
//                 : _messages.isEmpty
//                     ? Center(child: Text('No messages yet'))
//                     : ListView.builder(
//                         controller: _scrollController,
//                         itemCount: _messages.length,
//                         itemBuilder: (context, index) {
//                           final message = _messages[index];
//                           final isMe = message['sender_id'] == widget.userId;
//
//                           return Align(
//                             alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                             child: Container(
//                               margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                               padding: EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: isMe ? Colors.blue[100] : Colors.grey[200],
//                                 borderRadius: BorderRadius.circular(15),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     message['content'],
//                                     style: TextStyle(fontSize: 16),
//                                   ),
//                                   SizedBox(height: 5),
//                                   Text(
//                                     DateTime.parse(message['created_at']).toString().substring(0, 16),
//                                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: 'Type a message...',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(25),
//                       ),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 IconButton(
//                   icon: Icon(Icons.send),
//                   onPressed: _sendMessage,
//                   color: Theme.of(context).primaryColor,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }





// // lib/presentation/view/chat_screen.dart
// import 'package:flutter/material.dart';
// import '../../util/chat_service.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String userId;
//   final String username;
//   final String? authToken;
//   final String conversationId;
//   final String otherUsername;
//
//   ChatScreen({
//     required this.userId,
//     required this.username,
//     this.authToken,
//     required this.conversationId,
//     required this.otherUsername,
//   });
//
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   late final ChatService _chatService;
//   List<Map<String, dynamic>> _messages = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _chatService = ChatService(authToken: widget.authToken);
//     _loadInitialMessages();
//     _subscribeToConversationMessages();
//   }
//
//   void _loadInitialMessages() async {
//     try {
//       setState(() {
//         _isLoading = true;
//       });
//
//       final messages = await _chatService.getMessageHistory(widget.conversationId);
//
//       if (mounted) {
//         setState(() {
//           _messages = messages;
//           _isLoading = false;
//         });
//         _scrollToBottom();
//       }
//     } catch (e) {
//       print('Error loading initial messages: $e');
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading messages: $e')),
//         );
//       }
//     }
//   }
//
//   void _subscribeToConversationMessages() {
//     _chatService.getConversationMessagesStream(widget.conversationId).listen((messages) {
//       if (mounted) {
//         setState(() {
//           _messages = messages;
//         });
//         _scrollToBottom();
//       }
//     }, onError: (error) {
//       print('Error in message stream: $error');
//     });
//   }


  // @override
  // void initState() {
  //   super.initState();
  //   _chatService = ChatService(authToken: widget.authToken);
  //   _loadInitialMessages();
  //   _chatService.subscribeToConversation(widget.conversationId);
  //   _subscribeToMessages();
  // }

  // // Modified _loadInitialMessages() with better error handling
  // void _loadInitialMessages() async {
  //   try {
  //     print('Loading initial messages for conversation: ${widget.conversationId}');
  //     final messages = await _chatService.getMessageHistory(widget.conversationId);
  //     print('Loaded ${messages.length} messages');
  //     print('Message data: $messages'); // Add this to debug message format
  //
  //     if (mounted) {
  //       setState(() {
  //         _messages = messages;
  //         _isLoading = false;
  //       });
  //       _scrollToBottom();
  //     }
  //   } catch (e, stackTrace) {
  //     print('Error loading initial messages: $e');
  //     print('Stack trace: $stackTrace'); // Add stack trace for debugging
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }
  // }

  // void _loadInitialMessages() async {
  //   try {
  //     print('Loading initial messages for conversation: ${widget.conversationId}');
  //     final messages = await _chatService.getMessageHistory(widget.conversationId);
  //     print('Loaded ${messages.length} messages');
  //
  //     if (mounted) {
  //       setState(() {
  //         _messages = messages;
  //         _isLoading = false;
  //       });
  //       _scrollToBottom();
  //     }
  //   } catch (e) {
  //     print('Error loading initial messages: $e');
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }
  // }

  // void _subscribeToMessages() {
  //   _chatService.getMessagesStream().listen((messages) {
  //     if (mounted) {
  //       setState(() {
  //         _messages = messages.where((msg) =>
  //           msg['conversation_id'] == widget.conversationId).toList();
  //
  //         print("_messages"+_messages.toString());
  //       });
  //       _scrollToBottom();
  //     }
  //   });
  // }

  // // Modified _subscribeToMessages with better debugging
  // void _subscribeToMessages() {
  //   _chatService.getMessagesStream().listen((messages) {
  //     if (mounted) {
  //       final filteredMessages = messages.where((msg) =>
  //       msg['conversation_id'] == widget.conversationId).toList();
  //
  //       print("All messages: $messages");
  //       print("Conversation ID: ${widget.conversationId}");
  //       print("Filtered messages: $filteredMessages");
  //
  //       setState(() {
  //         _messages = filteredMessages;
  //       });
  //       _scrollToBottom();
  //     }
  //   });
  // }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       Future.delayed(Duration(milliseconds: 100), () {
//         if (_scrollController.hasClients) {
//           _scrollController.animateTo(
//             _scrollController.position.maxScrollExtent,
//             duration: Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//           );
//         }
//       });
//     }
//   }
//
//   void _sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;
//
//     final message = _messageController.text;
//     _messageController.clear();
//
//     try {
//       await _chatService.sendMessage(
//         widget.userId,
//         widget.username,
//         message,
//         widget.conversationId
//       );
//       // Optionally manually refresh messages if WebSocket isn't working
//       _loadInitialMessages();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     _chatService.dispose();
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.otherUsername)),
//       body: Column(
//         children: [
//           Expanded(
//             child: _isLoading
//               ? Center(child: CircularProgressIndicator())
//               : _messages.isEmpty
//                 ? Center(child: Text('No messages yet. Start chatting!'))
//                 : ListView.builder(
//                     controller: _scrollController,
//                     itemCount: _messages.length,
//                     padding: EdgeInsets.all(8.0),
//                     itemBuilder: (context, index) {
//                       final message = _messages[index];
//                       final isMe = message['user_id'] == widget.userId;
//
//                       return Align(
//                         alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                         child: Container(
//                           margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                           padding: EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: isMe ? Colors.blue[100] : Colors.grey[300],
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               if (!isMe) Text(
//                                 message['username'] ?? 'Unknown',
//                                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//                               ),
//                               Text(message['content']),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//           ),
//           Container(
//             padding: EdgeInsets.all(16.0),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: 'Type a message...',
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     ),
//                     minLines: 1,
//                     maxLines: 5,
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 CircleAvatar(
//                   radius: 24,
//                   backgroundColor: Theme.of(context).primaryColor,
//                   child: IconButton(
//                     icon: Icon(Icons.send, color: Colors.white),
//                     onPressed: _sendMessage,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




// // lib/presentation/view/chat_screen.dart
// import 'package:flutter/material.dart';
// import '../../util/chat_service.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String userId;
//   final String username;
//   final String? authToken;
//   final String conversationId;
//   final String otherUsername;
//
//   ChatScreen({
//     required this.userId,
//     required this.username,
//     this.authToken,
//     required this.conversationId,
//     required this.otherUsername,
//   });
//
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   late final ChatService _chatService;
//   List<Map<String, dynamic>> _messages = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _chatService = ChatService(authToken: widget.authToken);
//     _chatService.subscribeToConversation(widget.conversationId);
//     _subscribeToMessages();
//   }
//
//   void _subscribeToMessages() {
//     _chatService.getMessagesStream().listen((messages) {
//       setState(() {
//         _messages = messages;
//         _isLoading = false;
//       });
//       _scrollToBottom();
//     });
//   }
//
//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       Future.delayed(Duration(milliseconds: 100), () {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       });
//     }
//   }
//
//   void _sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;
//
//     final message = _messageController.text;
//     _messageController.clear();
//
//     try {
//       await _chatService.sendMessage(
//         widget.userId,
//         widget.username,
//         message,
//         widget.conversationId
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     _chatService.dispose();
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.otherUsername)),
//       body: Column(
//         children: [
//           Expanded(
//             child: _isLoading
//               ? Center(child: CircularProgressIndicator())
//               : _messages.isEmpty
//                 ? Center(child: Text('No messages yet. Start chatting!'))
//                 : ListView.builder(
//                     controller: _scrollController,
//                     itemCount: _messages.length,
//                     padding: EdgeInsets.all(8.0),
//                     itemBuilder: (context, index) {
//                       final message = _messages[index];
//                       final isMe = message['user_id'] == widget.userId;
//
//                       return Align(
//                         alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                         child: Container(
//                           margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                           padding: EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: isMe ? Colors.blue[100] : Colors.grey[300],
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: Text(message['content']),
//                         ),
//                       );
//                     },
//                   ),
//           ),
//           Container(
//             padding: EdgeInsets.all(16.0),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: 'Type a message...',
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     ),
//                     minLines: 1,
//                     maxLines: 5,
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 CircleAvatar(
//                   radius: 24,
//                   backgroundColor: Theme.of(context).primaryColor,
//                   child: IconButton(
//                     icon: Icon(Icons.send, color: Colors.white),
//                     onPressed: _sendMessage,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }







// // lib/presentation/view/chat_screen.dart   //for one directional chatting
// import 'package:flutter/material.dart';
// import '../../util/chat_service.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String userId;
//   final String username;
//   final String? authToken;
//
//   ChatScreen({required this.userId, required this.username, this.authToken});
//
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   late final ChatService _chatService;
//   List<Map<String, dynamic>> _messages = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _chatService = ChatService(authToken: widget.authToken);
//     _loadMessages();
//     _subscribeToMessages();
//   }
//
//   void _loadMessages() async {
//     try {
//       final messages = await _chatService.getMessageHistory();
//       setState(() {
//         _messages = messages;
//         _isLoading = false;
//       });
//       _scrollToBottom();
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading messages: $e')),
//       );
//     }
//   }
//
//   void _subscribeToMessages() {
//     _chatService.getMessagesStream().listen((messages) {
//       setState(() {
//         _messages = messages;
//       });
//       _scrollToBottom();
//     });
//   }
//
//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       Future.delayed(Duration(milliseconds: 100), () {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       });
//     }
//   }
//
//   void _sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;
//
//     final message = _messageController.text;
//     _messageController.clear();
//
//     try {
//       await _chatService.sendMessage(widget.userId, message);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Chat Room')),
//       body: Column(
//         children: [
//           Expanded(
//             child: _isLoading
//               ? Center(child: CircularProgressIndicator())
//               : ListView.builder(
//                   controller: _scrollController,
//                   itemCount: _messages.length,
//                   padding: EdgeInsets.all(8.0),
//                   itemBuilder: (context, index) {
//                     final message = _messages[index];
//                     final isMe = message['user_id'] == widget.userId;
//
//                     return Align(
//                       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                       child: Container(
//                         margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                         padding: EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: isMe ? Colors.blue[100] : Colors.grey[300],
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             if (!isMe) Text(
//                               message['username'] ?? 'User',
//                               style: TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                             Text(message['content']),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//           ),
//           Container(
//             padding: EdgeInsets.all(16.0),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 8,
//                   offset: Offset(0, -2),
//                 )
//               ],
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: 'Type a message...',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(24),
//                       ),
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 8,
//                       ),
//                     ),
//                     minLines: 1,
//                     maxLines: 5,
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 CircleAvatar(
//                   radius: 24,
//                   backgroundColor: Theme.of(context).primaryColor,
//                   child: IconButton(
//                     icon: Icon(Icons.send, color: Colors.white),
//                     onPressed: _sendMessage,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }