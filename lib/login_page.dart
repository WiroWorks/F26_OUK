import 'package:flutter/material.dart';
import 'package:project_f26/components/my_button.dart';
import 'package:project_f26/components/my_textfield.dart';
import 'package:project_f26/components/square_tile.dart';

import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // text editing controllers
  final usernameController = TextEditingController();

  final passwordController = TextEditingController();

  // sign user in method
  Future signUserIn() async{
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: usernameController.text.trim(), password: passwordController.text.trim());
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    usernameController.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
                SizedBox(height: 30,),
              // logo
              Image.asset("assets/ouklogo.png", width: 170,),


              // welcome back, you've been missed!
              Text(
                'Hoşgeldiniz',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 25),

              // username textfield
              MyTextField(
                controller: usernameController,
                hintText: 'E-mail',
                obscureText: false,
              ),

              const SizedBox(height: 10),

              // password textfield
              MyTextField(
                controller: passwordController,
                hintText: 'Parola',
                obscureText: true,
              ),

              const SizedBox(height: 10),


              const SizedBox(height: 25),

              // sign in button
              MyButton(
                onTap: signUserIn,
              ),

              const SizedBox(height: 50),


            ],
          ),
        ),
      ),
    );
  }
}