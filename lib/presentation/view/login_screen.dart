
import 'package:connecta/presentation/view/users_screen.dart';
import 'package:flutter/material.dart';
import '../../util/auth_service.dart';
import '../../util/database_service.dart';
import 'chat_screen.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _authToken;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'nusrat@era.com';
    _passwordController.text = 'abc@123';

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuint),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => UsersScreen(
              currentUserId: result['user']['id'],
              username: _emailController.text.split('@')[0],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Modern gradient background
          Container(
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
          ),

          // Abstract pattern overlay
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

          // Content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 60),

                      // Animated logo container
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: 800),
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          height: 100,
                          width: 100,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF7E5F).withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.chat_bubble_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 25),
                      Text(
                        'Connecta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),

                      SizedBox(height: 8),
                      Text(
                        'Stay connected with friends',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),

                      SizedBox(height: 50),

                      // Login Form with refined glassmorphism
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),

                                SizedBox(height: 8),
                                Text(
                                  'Sign in to continue',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),

                                SizedBox(height: 32),

                                // Email Field
                                _buildInputField(
                                  controller: _emailController,
                                  label: 'Email',
                                  icon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                ),

                                SizedBox(height: 20),

                                // Password Field
                                _buildInputField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_rounded,
                                  isPassword: true,
                                ),

                                SizedBox(height: 8),

                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      foregroundColor: Color(0xFFFF7E5F),
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 10),

                                // Error Message
                                if (_errorMessage != null)
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    margin: EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.red.withOpacity(0.25)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.white),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Sign In Button with modern gradient
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFF7E5F), // Warm coral
                                        Color(0xFFFEB47B), // Soft orange
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFFFF7E5F).withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _signIn,
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                      minimumSize: Size(double.infinity, 50),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 30),

                      // Register Option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to sign up screen
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Color(0xFFFF7E5F),
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 16, color: Colors.white),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 18),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          hintText: label,
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      ),
    );
  }
}








//okk

// import 'package:connecta/presentation/view/users_screen.dart';
// import 'package:flutter/material.dart';
// import '../../util/auth_service.dart';
// import '../../util/database_service.dart';
// import 'chat_screen.dart';
//
//
// class LoginScreen extends StatefulWidget {
//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _authService = AuthService();
//   bool _isLoading = false;
//   String? _errorMessage;
//   String? _authToken;
//
//   initState() {
//     super.initState();
//     // Optionally, you can clear the controllers when the screen is initialized
//     _emailController.text = 'nusrat@era.com';
//     _passwordController.text = 'abc@123';
//   }
//   Future<void> _signIn() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//
//     try {
//       final result = await _authService.signIn(
//         _emailController.text,
//         _passwordController.text,
//       );
//
//       if (result.containsKey('access_token')) {
//         setState(() {
//           _authToken = result['access_token'];
//         });
//
//         // Once logged in, fetch some data
//        // _fetchData();
//
//         // Navigate to chat screen after successful login
//         // Navigator.of(context).push(
//         //   MaterialPageRoute(
//         //     builder: (context) => ChatScreen(
//         //       userId: result['user']['id'],
//         //       username: _emailController.text.split('@')[0], // Simple username from email
//         //       authToken: _authToken,
//         //     ),
//         //   ),
//         // );
//
//
//         // In your LoginScreen.dart, change the navigation after successful login
//         Navigator.of(context).push(
//           MaterialPageRoute(
//             builder: (context) => UsersScreen(
//               currentUserId: result['user']['id'],
//               username: _emailController.text.split('@')[0], // Simple username from email
//               authToken: _authToken,
//             ),
//           ),
//         );
//       } else {
//         setState(() {
//           _errorMessage = result['error_description'] ?? 'Unknown error';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = e.toString();
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _fetchData() async {
//     if (_authToken == null) return;
//
//     final dbService = DatabaseService(authToken: _authToken);
//     final records = await dbService.getRecords('your_table_name');
//
//     // Do something with the records
//     print('Records: $records');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Connecta')),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             TextField(
//               controller: _emailController,
//               decoration: InputDecoration(labelText: 'Email'),
//               keyboardType: TextInputType.emailAddress,
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _passwordController,
//               decoration: InputDecoration(labelText: 'Password'),
//               obscureText: true,
//             ),
//             SizedBox(height: 24),
//             if (_errorMessage != null)
//               Text(
//                 _errorMessage!,
//                 style: TextStyle(color: Colors.red),
//               ),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _isLoading ? null : _signIn,
//               child: _isLoading
//                   ? CircularProgressIndicator(color: Colors.white)
//                   : Text('Sign In'),
//             ),
//             if (_authToken != null)
//               Padding(
//                 padding: EdgeInsets.only(top: 24),
//                 child: Text(
//                   'Successfully signed in!',
//                   style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }