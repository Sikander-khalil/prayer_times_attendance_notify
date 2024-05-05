import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prayer_times/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController nameController = TextEditingController();

  TextEditingController emailController = TextEditingController();

  TextEditingController passController = TextEditingController();

  TextEditingController phoneController = TextEditingController();

  bool _obscured = false;
  final textFieldFocusNode = FocusNode();

  void _toggleObscured() {
    setState(() {
      _obscured = !_obscured;
      if (textFieldFocusNode.hasPrimaryFocus)
        return; // If focus is on text field, dont unfocus
      textFieldFocusNode.canRequestFocus =
          false; // Prevents focus if tap on eye
    });
  }

  final _formKey = GlobalKey<FormState>();

  String? _nameErrorText;

  String? _emailErrorText;

  String? _passErrorText;

  String? _phoneErrorText;

  void _validateName(String value) {
    if (value.isEmpty) {
      setState(() {
        _nameErrorText = 'Name is required';
      });
    } else {
      setState(() {
        _nameErrorText = '';
      });
    }
  }

  void _validateEmail(String value) {
    if (value.isEmpty) {
      setState(() {
        _emailErrorText = 'Email is required';
      });
    } else if (!isEmailValid(value)) {
      setState(() {
        _emailErrorText = 'Enter a valid email address';
      });
    } else {
      setState(() {
        _emailErrorText = '';
      });
    }
  }

  void _validatePassword(String value) {
    if (value.isEmpty) {
      setState(() {
        _passErrorText = 'Password is required';
      });
    } else if (value.length > 10) {
      setState(() {
        _passErrorText = "Password length is 10, Not Above.";
      });
    } else {
      setState(() {
        _passErrorText = '';
      });
    }
  }

  void _validatePhone(String value) {
    if (value.isEmpty) {
      setState(() {
        _phoneErrorText = 'Phone is required';
      });
    } else if (value.length > 11) {
      setState(() {
        _phoneErrorText = "Phone length is 11, Not Above.";
      });
    } else {
      setState(() {
        _phoneErrorText = '';
      });
    }
  }

  bool isEmailValid(String email) {
    // Basic email validation using regex
    // You can implement more complex validation if needed
    return RegExp(r'^[\w-\.]+@[a-zA-Z]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: emailController.text, password: passController.text);

        if (userCredential.user != null) {
          DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
          //
          // // Query Firebase database to check if email already exists
          // DatabaseEvent snapshot = await databaseReference.child("Users").orderByChild("Email").equalTo(emailController.text).once();
          //
          // // If snapshot exists, that means email already exists
          // if (snapshot.snapshot.value != null) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //       SnackBar(content: Text("Email is already registered. Please try another email.")));
          //   return; // Stop further execution
          // }

          // Proceed with storing user data in Firebase
          String id = DateTime.now().millisecondsSinceEpoch.toString();
          await databaseReference.child("Users").child(id).set({
            'Name': nameController.text,
            'Email': emailController.text,
            'Phone': phoneController.text,
          });

          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Registration is successful")));

          Future.delayed(Duration(seconds: 2), () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => LoginScreen()));
          });
        }
      } catch (e) {
        // Specify the type of exception as FirebaseAuthException
        if (e is FirebaseAuthException) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message ?? "An error occurred")));

          // Handle specific errors based on error code
          switch (e.code) {
            case "email-already-in-use":
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Email is already in use")));
              break;
            // Handle other error cases as needed
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("An unexpected error occurred")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Column(
              children: [
                Image.asset(
                  "assets/images/mosque.png",
                  width: 200,
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  height: 80,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: CupertinoTextField(
                      style: TextStyle(color: Colors.black),
                      controller: nameController,
                      placeholder: "Enter Name",
                      placeholderStyle: TextStyle(color: Colors.black),
                      prefix: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.account_circle_rounded,
                          color: Colors.black,
                        ),
                      ),
                      onChanged: _validateName,
                      decoration: BoxDecoration(
                        // Use BoxDecoration for border styling

                        border:
                            Border.all(color: Colors.black), // Set border color
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  height: 80,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: CupertinoTextField(
                      style: TextStyle(color: Colors.black),
                      controller: emailController,
                      placeholder: "Enter Email",
                      placeholderStyle: TextStyle(color: Colors.black),
                      prefix: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.email,
                          color: Colors.black,
                        ),
                      ),
                      onChanged: _validateEmail,
                      decoration: BoxDecoration(
                        // Use BoxDecoration for border styling

                        border:
                            Border.all(color: Colors.black), // Set border color
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  height: 80,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: CupertinoTextField(
                      style: TextStyle(color: Colors.black),
                      controller: passController,
                      placeholder: "Enter Password",
                      placeholderStyle: TextStyle(color: Colors.black),
                      prefix: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.lock,
                          color: Colors.black,
                        ),
                      ),
                      onChanged: _validatePassword,
                      decoration: BoxDecoration(
                        // Use BoxDecoration for border styling

                        border:
                            Border.all(color: Colors.black), // Set border color
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  height: 80,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: CupertinoTextField(
                      style: TextStyle(color: Colors.black),
                      controller: phoneController,
                      placeholder: "Enter Phone",
                      placeholderStyle: TextStyle(color: Colors.black),
                      prefix: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.phone,
                          color: Colors.black,
                        ),
                      ),
                      onChanged: _validatePhone,
                      decoration: BoxDecoration(
                        // Use BoxDecoration for border styling

                        border:
                            Border.all(color: Colors.black), // Set border color
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                MaterialButton(
                  color: Colors.black,
                  shape: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onPressed: _submitForm,
                  child: Text(
                    "Register",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
