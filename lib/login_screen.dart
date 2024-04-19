import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prayer_times/prayer_screens.dart';
import 'package:prayer_times/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();

  String? _emailErrorText;
  String? _passErrorText;

  bool _obscured = true; // Initially hide the password
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
        _emailErrorText = null; // Remove error style
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
        _passErrorText = null;
      });
    }
  }
  bool isEmailValid(String email) {

    return RegExp(r'^[\w-\.]+@[a-zA-Z]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<void> _loginForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text,
          password: passController.text,
        );

        // User is logged in successfully, navigate to the next screen
        Navigator.push(context, MaterialPageRoute(builder: (context) => PrayerScreen()));
      } catch (e) {
        if (e is FirebaseAuthException) {
          String errorMessage;
          switch (e.code) {
            case 'user-not-found':
              errorMessage = 'User not found. Please register.';
              break;
            case 'wrong-password':
              errorMessage = 'Incorrect password. Please try again.';
              break;
            default:
              errorMessage = 'User not found. Please register';
              break;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        } else {
          // Unexpected error occurred
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User not found. Please register.')),
          );
          print('Unhandled login error: $e');
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
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/mosque.png",
                    fit: BoxFit.cover,
                    width: 200,
                    height: 200,
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: "Enter Your Email",
                    border: OutlineInputBorder(),
                    errorText: _emailErrorText,

                  ),
                  onChanged: _validateEmail,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextFormField(
                  controller: passController,
                  obscureText: _obscured, // This will hide/show password based on _obscured value
                  decoration: InputDecoration(
                    suffixIcon: Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 4, 0),
                      child: GestureDetector(
                        onTap: _toggleObscured,
                        child: Icon(
                          _obscured
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    hintText: "Enter Password",
                    errorText: _passErrorText,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _validatePassword,
                ),
              ),

              SizedBox(
                height: 10,
              ),
              MaterialButton(
                  color: Colors.black,
                  onPressed: _loginForm,
                  child: Text(
                    "Login",
                    style: TextStyle(color: Colors.white),
                  )),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RegisterScreen()));
                    },
                    child: Text(
                      "Not Login!.Please Register",
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
