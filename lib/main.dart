import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'presentation/view/login_screen.dart'; // For date formatting

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get current UTC date/time in the specified format
    final now = DateTime.now().toUtc();
    final currentDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final currentUser = 'eraai51'; // Your user info

    return Scaffold(
      appBar: AppBar(title: Text('Supabase Demo')),
      body: Column(
        children: [
          // Display the user info and datetime at the top
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Date and Time (UTC): $currentDateTime',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Current User\'s Login: $currentUser',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Use Expanded to ensure LoginScreen gets the remaining space
          Expanded(
            child: LoginScreen(),
          ),
        ],
      ),
    );
  }
}