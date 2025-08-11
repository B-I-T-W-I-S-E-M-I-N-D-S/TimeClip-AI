import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../analytics/analytics.dart';
import '../../home/home.dart';


class FloatingAppBar extends StatefulWidget {
  final String title;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isLandingPage;
  final Function(String?)? onEndpointChanged;
  final String? videoPath; // Added to pass video path to Analytics

  const FloatingAppBar({
    Key? key,
    required this.title,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isLandingPage = false,
    this.onEndpointChanged,
    this.videoPath,
  }) : super(key: key);

  @override
  State<FloatingAppBar> createState() => _FloatingAppBarState();
}

class _FloatingAppBarState extends State<FloatingAppBar> {
  final TextEditingController _endpointController = TextEditingController();
  String? apiEndpoint;
  bool isEndpointValid = false;
  bool showEndpointInput = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEndpoint();
    _endpointController.addListener(_validateEndpoint);
  }

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

  // Load saved endpoint from SharedPreferences
  Future<void> _loadSavedEndpoint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEndpoint = prefs.getString('api_endpoint');
      if (savedEndpoint != null && savedEndpoint.isNotEmpty) {
        setState(() {
          apiEndpoint = savedEndpoint;
          _endpointController.text = savedEndpoint;
          isEndpointValid = true;
        });
        widget.onEndpointChanged?.call(savedEndpoint);
      }
    } catch (e) {
      print('Error loading saved endpoint: $e');
    }
  }

  // Save endpoint to SharedPreferences
  Future<void> _saveEndpoint(String endpoint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_endpoint', endpoint);
    } catch (e) {
      print('Error saving endpoint: $e');
    }
  }

  // Validate endpoint input
  void _validateEndpoint() {
    final input = _endpointController.text.trim();
    setState(() {
      isEndpointValid = input.isNotEmpty &&
          (input.startsWith('http://') || input.startsWith('https://'));
    });
  }

  // Submit endpoint
  void _submitEndpoint() {
    if (isEndpointValid) {
      final String endpoint = _endpointController.text.trim().replaceAll(RegExp(r'/*$'), '');
      setState(() {
        apiEndpoint = endpoint;
        showEndpointInput = false;
      });
      _saveEndpoint(endpoint);
      widget.onEndpointChanged?.call(endpoint);
    }
  }

  // Clear endpoint
  void _clearEndpoint() {
    setState(() {
      apiEndpoint = null;
      _endpointController.clear();
      isEndpointValid = false;
      showEndpointInput = false;
    });
    _saveEndpoint('');
    widget.onEndpointChanged?.call(null);
  }

  // Navigate to page based on index
  void _navigateToPage(int index) {
    widget.onItemSelected(index);
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (index == 0) {
      // Navigate to Home
      if (currentRoute != '/home') {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            settings: const RouteSettings(name: '/home'),
            pageBuilder: (_, __, ___) => const Home(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    } else if (index == 1) {
      // Navigate to Analytics
      if (currentRoute != '/analytics') {
        if (widget.videoPath == null && currentRoute != '/home') {
          // Show error if trying to navigate to Analytics without a video
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Please load a video on the Home page before navigating to Analytics.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }
        Navigator.push(
          context,
          PageRouteBuilder(
            settings: const RouteSettings(name: '/analytics'),
            pageBuilder: (_, __, ___) => Analytics(
              videoPath: widget.videoPath,
              apiEndpoint: apiEndpoint,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    }
    // Add additional navigation cases for 'Team' or other pages if needed
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive dimensions
    final containerHeight = screenWidth < 600 ? 60.0 : 80.0;
    final logoSize = screenWidth < 600 ? 16.0 : 20.0;
    final fontSizeTitle = screenWidth < 600 ? 14.0 : 16.0;
    final fontSizeNav = screenWidth < 600 ? 10.0 : 12.0;
    final horizontalMargin = screenWidth < 600 ? 2.0 : 4.0;
    final horizontalPadding = screenWidth < 600 ? 6.0 : 8.0;
    final navItemSpacing = screenWidth < 600 ? 6.0 : screenWidth < 900 ? 12.0 : 16.0;
    final buttonHeight = screenWidth < 600 ? 32.0 : 36.0;
    final buttonPadding = screenWidth < 600 ? 6.0 : 8.0;
    final endSpacing = screenWidth < 600 ? 6.0 : 8.0;
    final maxWidth = screenWidth < 600 ? screenWidth * 0.9 : screenWidth * 0.8;

    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff9855FF),
                    blurRadius: 3,
                    offset: const Offset(3, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    height: containerHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff9855FF),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Row(
                        children: [
                          // Logo section
                          Row(
                            children: [
                              Container(
                                width: logoSize,
                                height: logoSize,
                                child: Image.asset("assets/logo.png"),
                              ),
                              SizedBox(width: screenWidth < 600 ? 4.0 : 6.0),
                              Text(
                                'TimeClip AI',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: fontSizeTitle,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Navigation items
                          Row(
                            children: [
                              _buildNavItem('Home', 0, fontSizeNav, isSelected: widget.selectedIndex == 0),
                              SizedBox(width: navItemSpacing),
                              _buildNavItem('Analytics', 1, fontSizeNav, isSelected: widget.selectedIndex == 1),
                              SizedBox(width: navItemSpacing),
                              _buildNavItem('Team', 2, fontSizeNav, isSelected: widget.selectedIndex == 2),
                            ],
                          ),

                          SizedBox(width: endSpacing),

                          // API Endpoint button
                          _buildApiEndpointButton(buttonHeight, buttonPadding, screenWidth),

                          SizedBox(width: endSpacing),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Endpoint input section (shown when toggled)
        if (showEndpointInput)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF9855FF).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter API Endpoint',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _endpointController,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'https://example.com/api/predict',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: isEndpointValid ? Colors.green[400]! : Colors.grey[600]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: Colors.blue[400]!,
                              width: 2,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.link,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isEndpointValid ? _submitEndpoint : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEndpointValid ? const Color(0xFF8B5CF6) : Colors.grey[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildApiEndpointButton(double buttonHeight, double buttonPadding, double screenWidth) {
    return Container(
      height: buttonHeight,
      child: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'set') {
            setState(() {
              showEndpointInput = !showEndpointInput;
            });
          } else if (value == 'clear') {
            _clearEndpoint();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'set',
            child: Row(
              children: [
                Icon(Icons.settings, size: 16),
                SizedBox(width: 8),
                Text('Set Endpoint'),
              ],
            ),
          ),
          if (apiEndpoint != null)
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.clear, size: 16),
                  SizedBox(width: 8),
                  Text('Clear Endpoint'),
                ],
              ),
            ),
        ],
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: buttonPadding, vertical: 4),
          decoration: BoxDecoration(
            color: apiEndpoint != null ? Colors.green[100] : Colors.grey[100],
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: apiEndpoint != null ? Colors.green[400]! : Colors.grey[400]!,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                apiEndpoint != null ? Icons.check_circle : Icons.api,
                size: 16,
                color: apiEndpoint != null ? Colors.green[600] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                apiEndpoint != null ? 'API Set' : 'API',
                style: TextStyle(
                  fontSize: screenWidth < 600 ? 10.0 : 12.0,
                  fontWeight: FontWeight.w600,
                  color: apiEndpoint != null ? Colors.green[600] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String title, int index, double fontSize, {required bool isSelected}) {
    return GestureDetector(
      onTap: () => _navigateToPage(index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isSelected ? Colors.black.withOpacity(0.1) : Colors.transparent,
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.black.withOpacity(0.9),
              fontSize: fontSize,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}