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
  final String? videoPath;

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

class _FloatingAppBarState extends State<FloatingAppBar> with TickerProviderStateMixin {
  final TextEditingController _endpointController = TextEditingController();
  String? apiEndpoint;
  bool isEndpointValid = false;
  bool showEndpointInput = false;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _navAnimationController;

  // Navigation items data
  final List<NavItem> _navItems = [
    NavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
    NavItem(icon: Icons.analytics_rounded, label: 'Analytics', index: 1),
    NavItem(icon: Icons.group_rounded, label: 'Team', index: 2),
    NavItem(icon: Icons.person_rounded, label: 'Profile', index: 3),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedEndpoint();
    _endpointController.addListener(_validateEndpoint);

    // Initialize animation controllers for enhanced effects
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _navAnimationController.dispose();
    super.dispose();
  }

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

  Future<void> _saveEndpoint(String endpoint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_endpoint', endpoint);
    } catch (e) {
      print('Error saving endpoint: $e');
    }
  }

  void _validateEndpoint() {
    final input = _endpointController.text.trim();
    setState(() {
      isEndpointValid = input.isNotEmpty &&
          (input.startsWith('http://') || input.startsWith('https://'));
    });
  }

  void _submitEndpoint() {
    if (isEndpointValid) {
      final String endpoint = _endpointController.text.trim().replaceAll(RegExp(r'/*$'), '');
      setState(() {
        apiEndpoint = endpoint;
        showEndpointInput = false;
      });
      _saveEndpoint(endpoint);
      widget.onEndpointChanged?.call(endpoint);

      // Show success feedback
      _showSuccessSnackBar('API endpoint configured successfully!');
    }
  }

  void _clearEndpoint() {
    setState(() {
      apiEndpoint = null;
      _endpointController.clear();
      isEndpointValid = false;
      showEndpointInput = false;
    });
    _saveEndpoint('');
    widget.onEndpointChanged?.call(null);

    // Show cleared feedback
    _showInfoSnackBar('API endpoint cleared');
  }

  // Enhanced feedback methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[400], size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[400], size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[400], size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400]),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: Colors.blue[400])),
          ),
        ],
      ),
    );
  }

  // Enhanced navigation validation
  bool get _canNavigateToAnalytics {
    return widget.videoPath != null &&
        widget.videoPath!.isNotEmpty &&
        apiEndpoint != null &&
        apiEndpoint!.isNotEmpty;
  }

  void _navigateToPage(int index) {
    widget.onItemSelected(index);
    _navAnimationController.forward().then((_) {
      _navAnimationController.reverse();
    });

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
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } else if (index == 1) {
      // Navigate to Analytics with enhanced validation
      if (currentRoute != '/analytics') {
        // Check if video is loaded
        if (widget.videoPath == null || widget.videoPath!.isEmpty) {
          _showValidationError('Please upload a video file on the Home page before accessing Analytics');
          return;
        }

        // Check if API endpoint is set
        if (apiEndpoint == null || apiEndpoint!.isEmpty) {
          _showValidationError('Please set an API endpoint before accessing Analytics');
          setState(() {
            showEndpointInput = true;
          });
          return;
        }

        // All validations passed - navigate to Analytics
        Navigator.push(
          context,
          PageRouteBuilder(
            settings: const RouteSettings(name: '/analytics'),
            pageBuilder: (_, __, ___) => Analytics(
              videoPath: widget.videoPath!,
              apiEndpoint: apiEndpoint,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } else if (index == 2) {
      // Team page - placeholder
      _showInfoSnackBar('Team page coming soon!');
    } else if (index == 3) {
      // Profile page - placeholder
      _showInfoSnackBar('Profile page coming soon!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerHeight = screenWidth < 600 ? 60.0 : 80.0;
    final logoSize = screenWidth < 600 ? 24.0 : 26.0;
    final fontSizeTitle = screenWidth < 600 ? 18.0 : 22.0;
    final horizontalMargin = screenWidth < 600 ? 2.0 : 4.0;
    final horizontalPadding = screenWidth < 600 ? 6.0 : 8.0;
    final buttonHeight = screenWidth < 600 ? 32.0 : 36.0;
    final buttonPadding = screenWidth < 600 ? 6.0 : 8.0;
    final endSpacing = screenWidth < 600 ? 6.0 : 8.0;
    final maxWidth = screenWidth < 600 ? screenWidth * 0.9 : screenWidth * 0.8;

    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    // Enhanced outer glow effect
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff9855FF).withOpacity(0.4 + _pulseController.value * 0.2),
                        blurRadius: 15 + _pulseController.value * 5,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xff9855FF).withOpacity(0.2),
                        blurRadius: 25,
                        spreadRadius: 5,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Stack(
                      children: [
                        // Enhanced backdrop filter with multiple layers
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Container(
                            height: containerHeight,
                            decoration: BoxDecoration(
                              // Ultra-transparent glassmorphism effect
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        // Animated shimmer overlay
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            return Container(
                              height: containerHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                gradient: LinearGradient(
                                  begin: Alignment(-1.0 + _shimmerController.value * 2, 0),
                                  end: Alignment(1.0 + _shimmerController.value * 2, 0),
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            );
                          },
                        ),

                        // Content layer
                        Container(
                          height: containerHeight,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            child: Row(
                              children: [
                                // Enhanced logo section with gradient text
                                Row(
                                  children: [
                                    Container(
                                      width: logoSize,
                                      height: logoSize,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(logoSize / 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xff9855FF).withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Image.asset("assets/logo.png"),
                                    ),
                                    SizedBox(width: screenWidth < 600 ? 4.0 : 6.0),
                                    ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFFFFFF), // White
                                          Color(0xFFF8FAFC), // Very light gray
                                          Color(0xFFE879F9), // Light purple
                                        ],
                                        stops: [0.0, 0.2, 1.0],
                                      ).createShader(bounds),
                                      child: Text(
                                        'TimeClipAI',
                                        style: TextStyle(
                                          color: Colors.white, // This will be overridden by the shader
                                          fontSize: fontSizeTitle,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.4,
                                          shadows: [
                                            Shadow(
                                              color: const Color(0xff9855FF).withOpacity(0.3),
                                              blurRadius: 4,
                                            ),
                                            Shadow(
                                              color: Colors.white.withOpacity(0.2),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const Spacer(),

                                // Modern Pill Navigation Section
                                _buildModernNavigation(screenWidth),

                                const Spacer(),

                                // Enhanced API Endpoint button
                                _buildApiEndpointButton(buttonHeight, buttonPadding, screenWidth),

                                SizedBox(width: endSpacing),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Enhanced endpoint input section with glassmorphism
        if (showEndpointInput)
          AnimatedOpacity(
            opacity: showEndpointInput ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff9855FF).withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF9855FF).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.api,
                              color: const Color(0xFF9855FF),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Configure API Endpoint',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xff9855FF).withOpacity(0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your API endpoint URL to enable video analysis',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _endpointController,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'https://api.example.com/predict',
                                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isEndpointValid
                                            ? Colors.green[400]!.withOpacity(0.6)
                                            : Colors.white.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: const Color(0xff9855FF).withOpacity(0.8),
                                        width: 2,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.link,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 18,
                                    ),
                                    suffixIcon: isEndpointValid
                                        ? Icon(
                                      Icons.check_circle,
                                      color: Colors.green[400],
                                      size: 18,
                                    )
                                        : null,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  keyboardType: TextInputType.url,
                                  onSubmitted: (_) => isEndpointValid ? _submitEndpoint() : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: isEndpointValid
                                    ? LinearGradient(
                                  colors: [
                                    const Color(0xFF8B5CF6),
                                    const Color(0xff9855FF),
                                  ],
                                )
                                    : null,
                                boxShadow: isEndpointValid ? [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ] : null,
                              ),
                              child: ElevatedButton(
                                onPressed: isEndpointValid ? _submitEndpoint : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isEndpointValid ? Colors.transparent : Colors.grey[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  shadowColor: Colors.transparent,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isEndpointValid ? Icons.save : Icons.save_outlined,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Save',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_endpointController.text.isNotEmpty && !isEndpointValid)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red[400],
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Please enter a valid URL (must start with http:// or https://)',
                                  style: TextStyle(
                                    color: Colors.red[400],
                                    fontSize: 12,
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
          ),
      ],
    );
  }

  Widget _buildModernNavigation(double screenWidth) {
    final navItemSize = screenWidth < 600 ? 40.0 : 48.0;
    final navPillWidth = (_navItems.length * navItemSize) + ((_navItems.length - 1) * 4.0) + 16.0;

    return Container(
      width: navPillWidth,
      height: navItemSize + 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Moving highlight background
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: 8 + (widget.selectedIndex * (navItemSize + 4)),
                  top: 4,
                  child: Container(
                    width: navItemSize,
                    height: navItemSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFF9855FF),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),

                // Navigation items
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _navItems.map((item) => _buildNavIconItem(
                        item,
                        navItemSize,
                        widget.selectedIndex == item.index,
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIconItem(NavItem item, double size, bool isSelected) {
    // Check if Analytics navigation should be disabled
    bool isAnalyticsDisabled = item.index == 1 && !_canNavigateToAnalytics;

    return GestureDetector(
      onTap: () => _navigateToPage(item.index),
      child: MouseRegion(
        cursor: isAnalyticsDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: AnimatedScale(
          scale: isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size / 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  item.icon,
                  size: size * 0.5,
                  color: isAnalyticsDisabled
                      ? Colors.white.withOpacity(0.3)
                      : isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.6),
                ),
                // Show lock icon for disabled Analytics
                if (isAnalyticsDisabled)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.lock,
                        size: size * 0.25,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApiEndpointButton(double buttonHeight, double buttonPadding, double screenWidth) {
    return Container(
      height: buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: apiEndpoint != null
                ? Colors.green.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'set') {
                setState(() {
                  showEndpointInput = true;
                });
              } else if (value == 'clear') {
                _clearEndpoint();
              }
            },
            offset: const Offset(0, 40),
            color: Colors.black.withOpacity(0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: buttonPadding,
                vertical: buttonPadding * 0.5,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    apiEndpoint != null
                        ? Colors.green.withOpacity(0.3)
                        : Colors.white.withOpacity(0.2),
                    apiEndpoint != null
                        ? Colors.green.withOpacity(0.1)
                        : Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    apiEndpoint != null ? Icons.cloud_done : Icons.cloud_queue,
                    color: apiEndpoint != null
                        ? Colors.green[400]
                        : Colors.white.withOpacity(0.7),
                    size: screenWidth < 600 ? 16 : 18,
                  ),
                  SizedBox(width: screenWidth < 600 ? 4 : 6),
                  Text(
                    apiEndpoint != null ? 'API Set' : 'Set API',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: screenWidth < 600 ? 12 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'set',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Colors.white.withOpacity(0.9),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Set API Endpoint',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (apiEndpoint != null)
                PopupMenuItem<String>(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(
                        Icons.clear,
                        color: Colors.red[400],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Clear API Endpoint',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;
  final int index;

  NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}