import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'dart:ui';
import '../Common/widgets/Appbar.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove the default appBar and use a custom floating one
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Image.asset('assets/Back light.png'),
          ),
          // Your main content goes here
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Latest integration badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.grey, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/new.png'),
                      SizedBox(width: 6),
                      Text(
                        'Latest integration just arrived',
                        style: TextStyle(
                          color: Color(0xFF9855FF),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Main heading
                Text(
                  'Know What Happens.',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                GradientText(
                  'When It Happens.',
                  style: TextStyle(fontSize: 78, fontWeight: FontWeight.bold),
                  colors: [Colors.white, Color(0xffB372CF)],
                  gradientDirection: GradientDirection.ttb,
                ),
                SizedBox(height: 24),

                // Subtitle
                Text(
                  'Temporal Action for every frame.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 8),

                Container(
                  width: 400,
                  child: Text(
                    'Our deep learning engine localizes and classifies actions in real time, so you can turn video data into actionable insight.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 32),

                // CTA Button
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.transparent, // Purple background
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey, width: 0.5), // Border effect
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white, // Button background color
                        elevation: 2, // Shadow elevation
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Rounded corners
                        ),
                        minimumSize: Size(150, 50), // Button size
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: Text(
                        'Start for Free',
                        style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Floating AppBar
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: FloatingAppBar(
              title: widget.title,
              selectedIndex: selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
