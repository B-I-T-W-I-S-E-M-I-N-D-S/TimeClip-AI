import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:parallax_rain/parallax_rain.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'dart:ui';
import '../Common/widgets/Appbar.dart';
import '../home/home.dart';

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
    // Get screen size and text scale factor
    final size = MediaQuery.of(context).size;
    final textScaler = MediaQuery.textScalerOf(context);
    // Determine if the device is mobile (width < 600)
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: ParallaxRain(
        dropColors: [Colors.white],
        dropHeight: 2,
        dropWidth: 0.5,
        dropFallSpeed: 0.5,
        child: Stack(
          children: [
            // Background gradient
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Image.asset(
                'assets/Back light.png',
                width: size.width - 40, // Responsive width
                fit: BoxFit.cover,
              ),
            ),
            // Main content
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(top: isMobile ? 80.0 : 100.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Latest integration badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 12,
                          vertical: isMobile ? 8 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.grey, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/new.png',
                              width: isMobile ? 20 : 24,
                            ),
                            SizedBox(width: isMobile ? 4 : 6),
                            Text(
                              'Latest integration just arrived',
                              style: TextStyle(
                                color: Color(0xFF9855FF),
                                fontSize: textScaler.scale(isMobile ? 14 : 18),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 24 : 32),
                      // Main heading
                      Text(
                        'Know What Happens.',
                        style: TextStyle(
                          fontSize: textScaler.scale(isMobile ? 36 : 56),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      GradientText(
                        'When It Happens.',
                        style: TextStyle(
                          fontSize: textScaler.scale(isMobile ? 48 : 78),
                          fontWeight: FontWeight.bold,
                        ),
                        colors: [Colors.white, Color(0xffB372CF)],
                        gradientDirection: GradientDirection.ttb,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      // Subtitle
                      Text(
                        'Temporal Action for every frame.',
                        style: TextStyle(
                          fontSize: textScaler.scale(isMobile ? 14 : 18),
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      // Description
                      Container(
                        width: isMobile ? size.width * 0.85 : 400,
                        child: Text(
                          'Our deep learning engine localizes and classifies actions in real time, so you can turn video data into actionable insight.',
                          style: TextStyle(
                            fontSize: textScaler.scale(isMobile ? 14 : 16),
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: isMobile ? 24 : 32),
                      // CTA Button
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: isMobile ? 120 : 160,
                            height: isMobile ? 50 : 60,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey, width: 0.5),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: Duration(milliseconds: 500),
                                  pageBuilder: (_, __, ___) => Home(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: Size(isMobile ? 110 : 150, isMobile ? 40 : 50),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 16 : 20,
                                vertical: isMobile ? 8 : 10,
                              ),
                            ),
                            child: Text(
                              'Start for Free',
                              style: TextStyle(
                                fontSize: textScaler.scale(isMobile ? 14 : 16),
                                fontWeight: FontWeight.w500,
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
                isLandingPage: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}