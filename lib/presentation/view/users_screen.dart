import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
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

class _UsersScreenState extends State<UsersScreen> with SingleTickerProviderStateMixin {
  ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    print('Auth token: ${widget.authToken}');
    _chatService = ChatService(authToken: widget.authToken);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    // Load users after a short delay to ensure screen is built
    Future.delayed(Duration(milliseconds: 300), _loadUsers);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final users = await _chatService.getAllUsers();

      setState(() {
        _users = users.where((user) => user['id'] != widget.currentUserId).toList();
        _filteredUsers = List.from(_users);
        _isLoading = false;
      });

      _animationController.reset();
      _animationController.forward();
    } catch (e, stackTrace) {
      print('Error loading users: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _startChat(String userId, String username) async {
    try {
      final conversationId = await _chatService.getOrCreateConversation(widget.currentUserId, userId);

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

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users.where((user) => (user['username'] ?? '').toString().toLowerCase().contains(query.toLowerCase()) || (user['email'] ?? '').toString().toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return false;
        } else {
          // Show confirmation dialog
          bool? exit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Exit App',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'Do you want to close the app?',
                style: TextStyle(color: Colors.white70),
              ),
              backgroundColor: Color(0xFF203A43),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF7E5F),
                  ),
                  child: Text('Exit'),
                ),
              ],
            ),
          );

          return exit ?? false;
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: Text(
            'Messages',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadUsers,
              splashRadius: 24,
            ),
          ],
        ),
        body: Stack(
          children: [
            // Background gradient remains the same
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F2027),
                    Color(0xFF203A43),
                    Color(0xFF2C5364),
                  ],
                ),
              ),
            ),

            // Wrap with LayoutBuilder to respond to available space
            LayoutBuilder(builder: (context, constraints) {
              return RefreshIndicator(
                onRefresh: _loadUsers,
                color: Color(0xFFFF7E5F),
                child: SafeArea(
                  // Make bottom safe area false if needed
                  bottom: false,
                  child: Column(
                    children: [
                      // User profile and story section - make height responsive
                      Container(
                        height: constraints.maxHeight * 0.15, // Percentage of available height
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            // Story items remain the same
                            Padding(
                              padding: EdgeInsets.only(right: 16),
                              child: Column(
                                children: [
                                  Container(
                                    width: 50, // Slightly smaller
                                    height: 50, // Slightly smaller
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFFF7E5F),
                                          Color(0xFFFEB47B),
                                        ],
                                      ),
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        widget.username[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 20, // Slightly smaller
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'You',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Active users
                            for (int i = 0; i < min(5, _filteredUsers.length); i++) _buildStoryItem(_filteredUsers[i]),
                          ],
                        ),
                      ),

                      // Divider with less padding
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(color: Colors.white.withOpacity(0.2), height: 1),
                      ),

                      // Search bar with less padding
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: Colors.white.withOpacity(0.08),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _filterUsers,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search messages',
                              hintStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.search, color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12), // Smaller padding
                            ),
                          ),
                        ),
                      ),

                      // User list - rest of the space
                      Expanded(
                        child: _isLoading
                            ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7E5F))))
                            : _filteredUsers.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    padding: EdgeInsets.only(top: 4, bottom: 4), // Reduced padding
                                    itemCount: _filteredUsers.length,
                                    itemBuilder: (context, index) {
                                      // List item build logic remains the same
                                      final user = _filteredUsers[index];
                                      final username = user['username'] ?? user['email']?.split('@')[0] ?? 'User';

                                      return AnimatedBuilder(
                                        animation: _animationController,
                                        builder: (context, child) {
                                          final delay = index * 0.1;
                                          final value = _animationController.value > delay ? (_animationController.value - delay) / (1 - delay) : 0.0;
                                          return Transform.translate(
                                            offset: Offset(0, 20 * (1 - value)),
                                            child: Opacity(opacity: value, child: child),
                                          );
                                        },
                                        child: _buildModifiedChatListItem(user, username),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Modified chat list item with reduced padding
  Widget _buildModifiedChatListItem(Map<String, dynamic> user, String username) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 2), // Reduced vertical margin
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.08),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        // Reduced padding
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 20, // Smaller radius
              backgroundColor: Color(0xFFFF7E5F),
              child: Text(
                username[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // Smaller font
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12, // Smaller indicator
                height: 12, // Smaller indicator
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                username,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15, // Smaller font
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${_getRandomTime()}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11, // Smaller font
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Tap to start a conversation',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13, // Smaller font
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => _startChat(user['id'], username),
      ),
    );
  }

  // Helper method for empty state to keep code clean
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60, // Smaller size
            color: Colors.white.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadUsers,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF7E5F),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Reduced padding
            ),
          ),
        ],
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return WillPopScope(
  //     onWillPop: () async {
  //       if (Navigator.of(context).canPop()) {
  //         Navigator.of(context).pop();
  //       } else {
  //         Navigator.of(context, rootNavigator: true).pop();
  //       }
  //       return true;
  //     },
  //     child: Scaffold(
  //       extendBodyBehindAppBar: true,
  //       appBar: AppBar(
  //         elevation: 0,
  //         backgroundColor: Colors.transparent,
  //         flexibleSpace: ClipRect(
  //           child: BackdropFilter(
  //             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  //             child: Container(
  //               color: Colors.white.withOpacity(0.1),
  //             ),
  //           ),
  //         ),
  //         systemOverlayStyle: SystemUiOverlayStyle.light,
  //         title: Text(
  //           'Messages',
  //           style: TextStyle(
  //             fontWeight: FontWeight.bold,
  //             fontSize: 22,
  //           ),
  //         ),
  //         actions: [
  //           IconButton(
  //             icon: Icon(Icons.refresh, color: Colors.white),
  //             onPressed: _loadUsers,
  //             splashRadius: 24,
  //           ),
  //         ],
  //       ),
  //       body: Stack(
  //         children: [
  //           // Background gradient
  //           Container(
  //             decoration: BoxDecoration(
  //               gradient: LinearGradient(
  //                 begin: Alignment.topLeft,
  //                 end: Alignment.bottomRight,
  //                 colors: [
  //                   Color(0xFF0F2027), // Dark teal
  //                   Color(0xFF203A43), // Mid navy
  //                   Color(0xFF2C5364), // Deep ocean blue
  //                 ],
  //               ),
  //             ),
  //           ),
  //
  //           RefreshIndicator(
  //             onRefresh: _loadUsers,
  //             color: Color(0xFFFF7E5F),
  //             child: SafeArea(
  //               child: Column(
  //                 children: [
  //                   // User profile and story section
  //                   Container(
  //                     height: 100,
  //                     padding: EdgeInsets.symmetric(vertical: 12),
  //                     child: ListView(
  //                       scrollDirection: Axis.horizontal,
  //                       padding: EdgeInsets.symmetric(horizontal: 16),
  //                       children: [
  //                         // Your story
  //                         Padding(
  //                           padding: EdgeInsets.only(right: 16),
  //                           child: Column(
  //                             children: [
  //                               Container(
  //                                 width: 60,
  //                                 height: 60,
  //                                 decoration: BoxDecoration(
  //                                   shape: BoxShape.circle,
  //                                   gradient: LinearGradient(
  //                                     colors: [
  //                                       Color(0xFFFF7E5F), // Warm coral
  //                                       Color(0xFFFEB47B), // Soft orange
  //                                     ],
  //                                   ),
  //                                   border: Border.all(color: Colors.white, width: 2),
  //                                 ),
  //                                 child: Center(
  //                                   child: Text(
  //                                     widget.username[0].toUpperCase(),
  //                                     style: TextStyle(
  //                                       fontSize: 24,
  //                                       fontWeight: FontWeight.bold,
  //                                       color: Colors.white,
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ),
  //                               SizedBox(height: 4),
  //                               Text(
  //                                 'You',
  //                                 style: TextStyle(
  //                                   color: Colors.white,
  //                                   fontSize: 12,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //
  //                         // Active users
  //                         for (int i = 0; i < min(5, _filteredUsers.length); i++)
  //                           _buildStoryItem(_filteredUsers[i]),
  //                       ],
  //                     ),
  //                   ),
  //
  //                   // Divider
  //                   Padding(
  //                     padding: EdgeInsets.symmetric(horizontal: 16),
  //                     child: Divider(color: Colors.white.withOpacity(0.2)),
  //                   ),
  //
  //                   // Search bar
  //                   Padding(
  //                     padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
  //                     child: Container(
  //                       decoration: BoxDecoration(
  //                         borderRadius: BorderRadius.circular(25),
  //                         color: Colors.white.withOpacity(0.08),
  //                         border: Border.all(color: Colors.white.withOpacity(0.1)),
  //                       ),
  //                       child: TextField(
  //                         controller: _searchController,
  //                         onChanged: _filterUsers,
  //                         style: TextStyle(color: Colors.white),
  //                         decoration: InputDecoration(
  //                           hintText: 'Search messages',
  //                           hintStyle: TextStyle(color: Colors.white70),
  //                           prefixIcon: Icon(Icons.search, color: Colors.white70),
  //                           border: InputBorder.none,
  //                           contentPadding: EdgeInsets.symmetric(vertical: 14),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //
  //                   // User list
  //                   Expanded(
  //                     child: _isLoading
  //                       ? Center(
  //                           child: Column(
  //                             mainAxisAlignment: MainAxisAlignment.center,
  //                             children: [
  //                               CircularProgressIndicator(
  //                                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7E5F)),
  //                               ),
  //                               SizedBox(height: 16),
  //                               Text(
  //                                 'Loading messages...',
  //                                 style: TextStyle(color: Colors.white70),
  //                               )
  //                             ],
  //                           ),
  //                         )
  //                       : _filteredUsers.isEmpty
  //                         ? Center(
  //                             child: Column(
  //                               mainAxisAlignment: MainAxisAlignment.center,
  //                               children: [
  //                                 Icon(
  //                                   Icons.chat_bubble_outline,
  //                                   size: 64,
  //                                   color: Colors.white.withOpacity(0.5),
  //                                 ),
  //                                 SizedBox(height: 16),
  //                                 Text(
  //                                   'No conversations yet',
  //                                   style: TextStyle(
  //                                     color: Colors.white.withOpacity(0.7),
  //                                     fontSize: 18,
  //                                   ),
  //                                 ),
  //                                 SizedBox(height: 16),
  //                                 ElevatedButton.icon(
  //                                   onPressed: _loadUsers,
  //                                   icon: Icon(Icons.refresh),
  //                                   label: Text('Refresh'),
  //                                   style: ElevatedButton.styleFrom(
  //                                     backgroundColor: Color(0xFFFF7E5F),
  //                                     foregroundColor: Colors.white,
  //                                     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  //                                     shape: RoundedRectangleBorder(
  //                                       borderRadius: BorderRadius.circular(25),
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           )
  //                         : ListView.builder(
  //                             padding: EdgeInsets.symmetric(vertical: 8),
  //                             itemCount: _filteredUsers.length,
  //                             itemBuilder: (context, index) {
  //                               final user = _filteredUsers[index];
  //                               final username = user['username'] ?? user['email']?.split('@')[0] ?? 'User';
  //
  //                               return AnimatedBuilder(
  //                                 animation: _animationController,
  //                                 builder: (context, child) {
  //                                   final delay = index * 0.1;
  //                                   final value = _animationController.value > delay
  //                                       ? (_animationController.value - delay) / (1 - delay)
  //                                       : 0.0;
  //                                   return Transform.translate(
  //                                     offset: Offset(0, 20 * (1 - value)),
  //                                     child: Opacity(opacity: value, child: child),
  //                                   );
  //                                 },
  //                                 child: _buildChatListItem(user, username),
  //                               );
  //                             },
  //                           ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildStoryItem(Map<String, dynamic> user) {
    final username = user['username'] ?? user['email']?.split('@')[0] ?? 'User';
    final isActive = true; // You can implement logic for active status

    return Padding(
      padding: EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade800],
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    username[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (isActive)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            username.length > 8 ? '${username.substring(0, 8)}...' : username,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListItem(Map<String, dynamic> user, String username) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.08),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFFF7E5F),
              child: Text(
                username[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Text(
              username,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Spacer(),
            Text(
              '${_getRandomTime()}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tap to start a conversation',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        onTap: () => _startChat(user['id'], username),
      ),
    );
  }

  String _getRandomTime() {
    final hour = (DateTime.now().hour % 12 == 0) ? 12 : DateTime.now().hour % 12;
    final min = DateTime.now().minute;
    return '$hour:${min.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? "PM" : "AM"}';
  }

  int min(int a, int b) => a < b ? a : b;
}

//2
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'dart:ui';
// import '../../util/chat_service.dart';
// import 'chat_screen.dart';
//
// class UsersScreen extends StatefulWidget {
//   final String currentUserId;
//   final String username;
//   final String? authToken;
//
//   UsersScreen({required this.currentUserId, required this.username, this.authToken});
//
//   @override
//   _UsersScreenState createState() => _UsersScreenState();
// }
//
// class _UsersScreenState extends State<UsersScreen> with SingleTickerProviderStateMixin {
//   ChatService _chatService = ChatService();
//   List<Map<String, dynamic>> _users = [];
//   bool _isLoading = true;
//   late AnimationController _animationController;
//   final _searchController = TextEditingController();
//   List<Map<String, dynamic>> _filteredUsers = [];
//
//   @override
//   void initState() {
//     super.initState();
//     print('Auth token: ${widget.authToken}');
//     _chatService = ChatService(authToken: widget.authToken);
//
//     _animationController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 800),
//     );
//
//     // Load users after a short delay to ensure screen is built
//     Future.delayed(Duration(milliseconds: 300), _loadUsers);
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadUsers() async {
//     try {
//       setState(() {
//         _isLoading = true;
//       });
//
//       // Debug print
//       print('Loading users...');
//
//       final users = await _chatService.getAllUsers();
//
//       // Debug print
//       print('Users loaded: ${users.length}');
//
//       setState(() {
//         // Filter out the current user
//         _users = users.where((user) => user['id'] != widget.currentUserId).toList();
//         _filteredUsers = List.from(_users);
//         _isLoading = false;
//       });
//
//       // Debug print
//       print('Filtered users: ${_filteredUsers.length}');
//
//       _animationController.reset();
//       _animationController.forward();
//     } catch (e, stackTrace) {
//       print('Error loading users: $e');
//       print('Stack trace: $stackTrace');
//       setState(() {
//         _isLoading = false;
//       });
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading users: $e')),
//         );
//       }
//     }
//   }
//
//   void _startChat(String userId, String username) async {
//     try {
//       final conversationId = await _chatService.getOrCreateConversation(
//         widget.currentUserId,
//         userId
//       );
//
//       Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (context) => ChatScreen(
//             userId: widget.currentUserId,
//             username: widget.username,
//             authToken: widget.authToken,
//             conversationId: conversationId,
//             otherUsername: username,
//           ),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error starting conversation: $e')),
//       );
//     }
//   }
//
//   void _filterUsers(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         _filteredUsers = List.from(_users);
//       } else {
//         _filteredUsers = _users
//             .where((user) =>
//                 (user['username'] ?? '')
//                     .toString()
//                     .toLowerCase()
//                     .contains(query.toLowerCase()) ||
//                 (user['email'] ?? '')
//                     .toString()
//                     .toLowerCase()
//                     .contains(query.toLowerCase()))
//             .toList();
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         if (Navigator.of(context).canPop()) {
//           Navigator.of(context).pop();
//         } else {
//           // Force pop using rootNavigator which works better on iOS
//           Navigator.of(context, rootNavigator: true).pop();
//         }
//         return true;
//       },
//       child: Scaffold(
//         extendBodyBehindAppBar: true,
//         appBar: AppBar(
//           elevation: 0,
//           backgroundColor: Colors.transparent,
//           flexibleSpace: ClipRect(
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//               child: Container(
//                 color: Colors.white.withOpacity(0.1),
//               ),
//             ),
//           ),
//           systemOverlayStyle: SystemUiOverlayStyle.light,
//           title: Text(
//             'Contacts',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 22,
//             ),
//           ),
//           actions: [
//             IconButton(
//               icon: Icon(Icons.refresh, color: Colors.white),
//               onPressed: _loadUsers,
//               splashRadius: 24,
//             ),
//           ],
//         ),
//         body: Stack(
//           children: [
//             // Background gradient
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     Color(0xFF0F2027), // Dark teal
//                     Color(0xFF203A43), // Mid navy
//                     Color(0xFF2C5364), // Deep ocean blue
//                   ],
//                 ),
//               ),
//             ),
//
//             // Content
//             SafeArea(
//               child: Column(
//                 children: [
//                   // Search bar
//                   Padding(
//                     padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(16),
//                         color: Colors.white.withOpacity(0.08),
//                         border: Border.all(color: Colors.white.withOpacity(0.1)),
//                       ),
//                       child: TextField(
//                         controller: _searchController,
//                         onChanged: _filterUsers,
//                         style: TextStyle(color: Colors.white),
//                         decoration: InputDecoration(
//                           hintText: 'Search contacts',
//                           hintStyle: TextStyle(color: Colors.white70),
//                           prefixIcon: Icon(Icons.search, color: Colors.white70),
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(vertical: 16),
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   // Debug info for development
//                   if (_users.isEmpty && !_isLoading)
//                     Padding(
//                       padding: EdgeInsets.all(8),
//                       child: Text(
//                         'Debug: No users in data',
//                         style: TextStyle(color: Colors.yellow),
//                       ),
//                     ),
//
//                   // User list
//                   Expanded(
//                     child: _isLoading
//                       ? Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               CircularProgressIndicator(
//                                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7E5F)),
//                               ),
//                               SizedBox(height: 16),
//                               Text(
//                                 'Loading contacts...',
//                                 style: TextStyle(color: Colors.white70),
//                               )
//                             ],
//                           ),
//                         )
//                       : _filteredUsers.isEmpty
//                         ? Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(
//                                   Icons.person_off,
//                                   size: 64,
//                                   color: Colors.white.withOpacity(0.5),
//                                 ),
//                                 SizedBox(height: 16),
//                                 Text(
//                                   'No contacts found',
//                                   style: TextStyle(
//                                     color: Colors.white.withOpacity(0.7),
//                                     fontSize: 18,
//                                   ),
//                                 ),
//                                 SizedBox(height: 16),
//                                 ElevatedButton.icon(
//                                   onPressed: _loadUsers,
//                                   icon: Icon(Icons.refresh),
//                                   label: Text('Refresh'),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Color(0xFFFF7E5F),
//                                     foregroundColor: Colors.white,
//                                     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           )
//                         : ClipRRect(
//                             borderRadius: BorderRadius.circular(20),
//                             child: BackdropFilter(
//                               filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//                               child: Container(
//                                 margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white.withOpacity(0.05),
//                                   borderRadius: BorderRadius.circular(20),
//                                   border: Border.all(
//                                     color: Colors.white.withOpacity(0.1),
//                                   ),
//                                 ),
//                                 child: ListView.builder(
//                                   padding: EdgeInsets.symmetric(vertical: 8),
//                                   itemCount: _filteredUsers.length,
//                                   itemBuilder: (context, index) {
//                                     final user = _filteredUsers[index];
//                                     final username = user['username'] ?? user['email']?.split('@')[0] ?? 'User';
//
//                                     return AnimatedBuilder(
//                                       animation: _animationController,
//                                       builder: (context, child) {
//                                         final delay = index * 0.1;
//                                         final value = _animationController.value > delay
//                                             ? (_animationController.value - delay) / (1 - delay)
//                                             : 0.0;
//                                         return Transform.translate(
//                                           offset: Offset(0, 20 * (1 - value)),
//                                           child: Opacity(opacity: value, child: child),
//                                         );
//                                       },
//                                       child: Container(
//                                         margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//                                         decoration: BoxDecoration(
//                                           borderRadius: BorderRadius.circular(16),
//                                           color: Colors.white.withOpacity(0.08),
//                                         ),
//                                         child: ListTile(
//                                           contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                                           leading: CircleAvatar(
//                                             backgroundColor: Color(0xFFFF7E5F),
//                                             child: Text(
//                                               username[0].toUpperCase(),
//                                               style: TextStyle(
//                                                 color: Colors.white,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                           ),
//                                           title: Text(
//                                             username,
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontWeight: FontWeight.w600,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                           subtitle: Text(
//                                             user['email'] ?? '',
//                                             style: TextStyle(
//                                               color: Colors.white.withOpacity(0.7),
//                                               fontSize: 14,
//                                             ),
//                                           ),
//                                           trailing: Container(
//                                             width: 40,
//                                             height: 40,
//                                             decoration: BoxDecoration(
//                                               shape: BoxShape.circle,
//                                               gradient: LinearGradient(
//                                                 colors: [
//                                                   Color(0xFFFF7E5F), // Warm coral
//                                                   Color(0xFFFEB47B), // Soft orange
//                                                 ],
//                                               ),
//                                             ),
//                                             child: IconButton(
//                                               icon: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
//                                               onPressed: () => _startChat(user['id'], username),
//                                               splashRadius: 24,
//                                             ),
//                                           ),
//                                           onTap: () => _startChat(user['id'], username),
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//1
// // lib/presentation/view/users_screen.dart
// import 'package:flutter/material.dart';
// import '../../util/chat_service.dart';
// import 'chat_screen.dart';
//
// class UsersScreen extends StatefulWidget {
//   final String currentUserId;
//   final String username;
//   final String? authToken;
//
//   UsersScreen({required this.currentUserId, required this.username, this.authToken});
//
//   @override
//   _UsersScreenState createState() => _UsersScreenState();
// }
//
// class _UsersScreenState extends State<UsersScreen> {
//   ChatService _chatService = ChatService();
//   List<Map<String, dynamic>> _users = [];
//   bool _isLoading = true;
//
//   // @override
//   // void initState() {
//   //   super.initState();
//   //   _chatService = ChatService(authToken: widget.authToken);
//   //   _loadUsers();
//   // }
//
//   @override
//   void initState() {
//     super.initState();
//     // Ensure auth token is available and properly passed
//     print('Auth token: ${widget.authToken}');
//     _chatService = ChatService(authToken: widget.authToken);
//     _loadUsers();
//   }
//
//   Future<void> _loadUsers() async {
//     try {
//       setState(() {
//         _isLoading = true;
//       });
//
//       final users = await _chatService.getAllUsers();
//       setState(() {
//         // Filter out the current user
//         _users = users.where((user) => user['id'] != widget.currentUserId).toList();
//         _isLoading = false;
//       });
//     } catch (e, stackTrace) {
//       print('Error loading users: $e');
//       print('Stack trace: $stackTrace');
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading users: $e')),
//       );
//     }
//   }
//   // Future<void> _loadUsers() async {
//   //   try {
//   //     final users = await _chatService.getAllUsers();
//   //     setState(() {
//   //       // Filter out the current user
//   //       _users = users.where((user) => user['id'] != widget.currentUserId).toList();
//   //       _isLoading = false;
//   //     });
//   //   } catch (e) {
//   //     setState(() {
//   //       _isLoading = false;
//   //     });
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Error loading users: $e')),
//   //     );
//   //   }
//   // }
//
//   void _startChat(String userId, String username) async {
//     try {
//       final conversationId = await _chatService.getOrCreateConversation(
//         widget.currentUserId,
//         userId
//       );
//
//       Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (context) => ChatScreen(
//             userId: widget.currentUserId,
//             username: widget.username,
//             authToken: widget.authToken,
//             conversationId: conversationId,
//             otherUsername: username,
//           ),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error starting conversation: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Contacts'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _loadUsers,
//           ),
//         ],
//       ),
//       body: _isLoading
//         ? Center(child: CircularProgressIndicator())
//         : _users.isEmpty
//           ? Center(child: Text('No users found'))
//           : ListView.builder(
//               itemCount: _users.length,
//               itemBuilder: (context, index) {
//                 final user = _users[index];
//                 final username = user['username'] ?? user['email']?.split('@')[0] ?? 'User';
//
//                 return ListTile(
//                   leading: CircleAvatar(
//                     child: Text(username[0].toUpperCase()),
//                   ),
//                   title: Text(username),
//                   subtitle: Text(user['email'] ?? ''),
//                   onTap: () => _startChat(user['id'], username),
//                 );
//               },
//             ),
//     );
//   }
//
//   // @override
//   // Widget build(BuildContext context) {
//   //   return Scaffold(
//   //     appBar: AppBar(title: Text('Contacts')),
//   //     body: _isLoading
//   //       ? Center(child: CircularProgressIndicator())
//   //       : ListView.builder(
//   //           itemCount: _users.length,
//   //           itemBuilder: (context, index) {
//   //             final user = _users[index];
//   //             final username = user['username'] ?? user['email']?.split('@')[0] ?? 'User';
//   //
//   //             return ListTile(
//   //               leading: CircleAvatar(
//   //                 child: Text(username[0].toUpperCase()),
//   //               ),
//   //               title: Text(username),
//   //               subtitle: Text(user['email'] ?? ''),
//   //               onTap: () => _startChat(user['id'], username),
//   //             );
//   //           },
//   //         ),
//   //   );
//   // }
// }
