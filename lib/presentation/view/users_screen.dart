// lib/presentation/view/users_screen.dart
import 'package:flutter/material.dart';
import '../../util/chat_service.dart';
import 'chat_screen.dart';

class UsersScreen extends StatefulWidget {
  final String currentUserId;
  final String username;
  final String? authToken;

  UsersScreen({required this.currentUserId, required this.username, this.authToken});

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  // @override
  // void initState() {
  //   super.initState();
  //   _chatService = ChatService(authToken: widget.authToken);
  //   _loadUsers();
  // }

  @override
  void initState() {
    super.initState();
    // Ensure auth token is available and properly passed
    print('Auth token: ${widget.authToken}');
    _chatService = ChatService(authToken: widget.authToken);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final users = await _chatService.getAllUsers();
      setState(() {
        // Filter out the current user
        _users = users.where((user) => user['id'] != widget.currentUserId).toList();
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading users: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
    }
  }
  // Future<void> _loadUsers() async {
  //   try {
  //     final users = await _chatService.getAllUsers();
  //     setState(() {
  //       // Filter out the current user
  //       _users = users.where((user) => user['id'] != widget.currentUserId).toList();
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error loading users: $e')),
  //     );
  //   }
  // }

  void _startChat(String userId, String username) async {
    try {
      final conversationId = await _chatService.getOrCreateConversation(
        widget.currentUserId,
        userId
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userId: widget.currentUserId,
            username: widget.username,
            authToken: widget.authToken,
            conversationId: conversationId,
            otherUsername: username,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting conversation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : _users.isEmpty
          ? Center(child: Text('No users found'))
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final username = user['username'] ?? user['email']?.split('@')[0] ?? 'User';

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(username[0].toUpperCase()),
                  ),
                  title: Text(username),
                  subtitle: Text(user['email'] ?? ''),
                  onTap: () => _startChat(user['id'], username),
                );
              },
            ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: Text('Contacts')),
  //     body: _isLoading
  //       ? Center(child: CircularProgressIndicator())
  //       : ListView.builder(
  //           itemCount: _users.length,
  //           itemBuilder: (context, index) {
  //             final user = _users[index];
  //             final username = user['username'] ?? user['email']?.split('@')[0] ?? 'User';
  //
  //             return ListTile(
  //               leading: CircleAvatar(
  //                 child: Text(username[0].toUpperCase()),
  //               ),
  //               title: Text(username),
  //               subtitle: Text(user['email'] ?? ''),
  //               onTap: () => _startChat(user['id'], username),
  //             );
  //           },
  //         ),
  //   );
  // }
}