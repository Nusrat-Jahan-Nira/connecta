import 'package:connecta/presentation/view/users_screen.dart';
import 'package:flutter/material.dart';
import '../../util/auth_service.dart';
import '../../util/database_service.dart';
import 'chat_screen.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _authToken;

  initState() {
    super.initState();
    // Optionally, you can clear the controllers when the screen is initialized
    _emailController.text = 'nusrat@era.com';
    _passwordController.text = 'abc@123';
  }
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });


    try {
      final result = await _authService.signIn(
        _emailController.text,
        _passwordController.text,
      );

      if (result.containsKey('access_token')) {
        setState(() {
          _authToken = result['access_token'];
        });

        // Once logged in, fetch some data
       // _fetchData();

        // Navigate to chat screen after successful login
        // Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (context) => ChatScreen(
        //       userId: result['user']['id'],
        //       username: _emailController.text.split('@')[0], // Simple username from email
        //       authToken: _authToken,
        //     ),
        //   ),
        // );


        // In your LoginScreen.dart, change the navigation after successful login
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UsersScreen(
              currentUserId: result['user']['id'],
              username: _emailController.text.split('@')[0], // Simple username from email
              authToken: _authToken,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['error_description'] ?? 'Unknown error';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchData() async {
    if (_authToken == null) return;

    final dbService = DatabaseService(authToken: _authToken);
    final records = await dbService.getRecords('your_table_name');

    // Do something with the records
    print('Records: $records');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Supabase Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Sign In'),
            ),
            if (_authToken != null)
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: Text(
                  'Successfully signed in!',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}