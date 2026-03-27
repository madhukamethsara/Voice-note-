import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //logo
              Image.asset('lib/Assets/logo.png', width: 340, height: 340),

              //adding buttons
              SizedBox(height: 20),

              //first button
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/roleselect');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  //button text
                  child: Text("Get started"),
                ),
              ),

              SizedBox(height: 20),

              //second button
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  //Navigate to login page
                  onPressed: () {
                    context.go('/Login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text("Already have an account"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}