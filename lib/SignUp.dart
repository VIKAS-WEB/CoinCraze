import 'package:coincraze/HomeScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController ConfirmPasswordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize AnimationController
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    // Define SlideTransition animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(2, 0.4), // Slide from slightly below
      end: Offset.zero, // End at original position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.ease,
    ));
    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email'),
          backgroundColor: const Color(0xFFD1493B),
        ),
      );
      return;
    }

    if (password.isEmpty || password.length < 6) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: const Color(0xFFD1493B),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (context) => Homescreen()),
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 41, 53, 60), Colors.white], // Dark grey to white gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 60.0),
              child: Column(
                children: [
                  SlideTransition(
                    position: _slideAnimation,
                    child: Image.asset('assets/images/whiteLogo.png', width: 300),
                  ),
                  const SizedBox(height: 0),
                  SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Divider(color: const Color.fromARGB(153, 190, 192, 192), thickness: 1),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SlideTransition(
                    position: _slideAnimation,
                    child: Text(
                      "SIGN UP",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 27.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SlideTransition(
                    position: _slideAnimation,
                    child: Text(
                      "Let's fill up this form and fill it correctly",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50.0),
                  SlideTransition(
                    position: _slideAnimation,
                    child: TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email, color: Colors.grey),
                        hintText: 'Email',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                   const SizedBox(height: 16.0),
                  SlideTransition(
                    position: _slideAnimation,
                    child: TextField(
                      controller: phoneNumberController,
                     // obscureText: ,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                        // suffixIcon: IconButton(
                        //   icon: Icon(
                        //     _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        //     color: Colors.grey,
                        //   ),
                        //   onPressed: _togglePasswordVisibility,
                        // ),
                        hintText: 'Phone Number',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SlideTransition(
                    position: _slideAnimation,
                    child: TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                        hintText: 'Password',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                   const SizedBox(height: 16.0),
                  SlideTransition(
                    position: _slideAnimation,
                    child: TextField(
                      controller: ConfirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                        hintText: 'Confirm Password',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                 
                  SlideTransition(
                    position: _slideAnimation,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Forgot Password feature not implemented'),
                              backgroundColor: const Color(0xFFD1493B),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.poppins(
                            fontSize: 14.0,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD1493B)),
                          )
                        : ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: Text(
                              'Login',
                              style: GoogleFonts.poppins(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 40.0),
                  SlideTransition(
                    position: _slideAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.poppins(
                            fontSize: 14.0,
                            color: Colors.grey[600],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                          Navigator.pop(context);
                          },
                          child: Text(
                            'Sign In',
                            style: GoogleFonts.poppins(
                              fontSize: 14.0,
                              color: const Color.fromARGB(255, 11, 11, 11),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}