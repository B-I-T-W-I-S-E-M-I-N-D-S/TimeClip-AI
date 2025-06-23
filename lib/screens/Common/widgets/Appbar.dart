import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FloatingAppBar extends StatelessWidget {
  final String title;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isLandingPage;

  const FloatingAppBar({
    Key? key,
    required this.title,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isLandingPage = false,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Color(0xff9855FF),
            blurRadius: 4,
            offset: Offset(4, 8), // Shadow position
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 100, // Slightly taller to match the image
            decoration: BoxDecoration(
              color: Colors.white, // More opaque white background
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.transparent,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xff9855FF),
                  //offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Logo section - diamond shape like in the image
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        child: Image.asset("assets/logo.png"),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'TimeClip AI', // Hardcoded to match the image
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  Spacer(),

                  // Navigation items
                  Row(
                    children: [
                      _buildNavItem('About', 0),
                      SizedBox(width: 40),
                      _buildNavItem('Technologies', 0),
                      SizedBox(width: 80),
                      _buildNavItem('Team', 4),
                    ],
                  ),

                  SizedBox(width: 40),

                  // Get Started button - matching the purple gradient
                  if (isLandingPage)
                    Container(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          print('Get Started pressed');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
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

  Widget _buildNavItem(String title, int index) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        onItemSelected(index);
        // Handle navigation here
        print('Navigating to: $title');
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Colors.black.withOpacity(0.1) : Colors.transparent,
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.black.withOpacity(0.9),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}