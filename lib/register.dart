import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for storing user details

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _academicYearController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions();
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance

  final _formKey = GlobalKey<FormState>(); // Form key for validation

  Future<void> _signUp() async {
    User? user = await _firebaseFunctions.signUpWithEmailAndPassword(
      _emailController.text,
      _passwordController.text,
    );

    if (user != null) {
      // Ensure the user is authenticated
      try {
        // Store additional user details in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': _nameController.text,
          'academicYear': _academicYearController.text,
          'userId': _userIdController.text,
          'mobile': _mobileController.text,
          'email': _emailController.text,
        });

        // Navigate to login page after successful registration
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error storing user data: ${e.toString()}"),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to sign up. Try again."),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 85, 99, 167),
          title: Text('Create an Account')),
      backgroundColor: const Color.fromARGB(255, 250, 220, 176),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Form for validation
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _academicYearController,
                decoration: InputDecoration(labelText: 'Academic Year'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your academic year';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _userIdController,
                decoration: InputDecoration(labelText: 'User ID'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your user ID';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(labelText: 'Mobile Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your mobile number';
                  }
                  if (value.length != 10) {
                    return 'Mobile number should be 10 digits';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signUp,
                child: Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _academicYearController.dispose();
    _userIdController.dispose();
    _mobileController.dispose();
    super.dispose();
  }
}
