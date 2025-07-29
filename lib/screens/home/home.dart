import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:parallax_rain/parallax_rain.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:file_picker/file_picker.dart';
import 'package:time_clip/screens/analytics/analytics.dart';
import 'dart:ui';
import 'dart:io';
import '../Common/widgets/Appbar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0; // Default to Home
  late final Player player;
  late final VideoController controller;
  String? currentVideoPath;
  bool isVideoLoaded = false;
  String? apiEndpoint;

  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);

    player.stream.buffering.listen((buffering) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  // Pick and load video file
  Future<void> _pickAndLoadVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final videoPath = result.files.single.path!;
        await player.open(Media('file:///$videoPath'));

        setState(() {
          currentVideoPath = videoPath;
          isVideoLoaded = true;
          print('Video loaded: $currentVideoPath, isVideoLoaded: $isVideoLoaded');
        });
      }
    } catch (e) {
      print('Error picking video file: $e');
      if (mounted) {
        _showErrorDialog('Error loading video: $e');
      }
    }
  }

  // Load video from specific path
  Future<void> _loadVideoFromPath(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await player.open(Media('file:///$filePath'));
        setState(() {
          currentVideoPath = filePath;
          isVideoLoaded = true;
          print('Video loaded: $currentVideoPath, isVideoLoaded: $isVideoLoaded');
        });
      } else {
        _showErrorDialog('Video file not found at: $filePath');
      }
    } catch (e) {
      print('Error loading video: $e');
      _showErrorDialog('Error loading video: $e');
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Clear current video
  void _clearVideo() {
    player.stop();
    setState(() {
      currentVideoPath = null;
      isVideoLoaded = false;
      print('Video cleared, isVideoLoaded: $isVideoLoaded');
    });
  }

  // Handle endpoint change from navbar
  void _onEndpointChanged(String? endpoint) {
    setState(() {
      apiEndpoint = endpoint;
      print('Endpoint updated from navbar: $apiEndpoint');
    });
  }

  // Navigate to Analytics
  void _navigateToAnalytics() {
    print('Navigating - isVideoLoaded: $isVideoLoaded, currentVideoPath: $currentVideoPath, apiEndpoint: $apiEndpoint');
    if (isVideoLoaded && currentVideoPath != null && apiEndpoint != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          settings: const RouteSettings(name: '/analytics'),
          pageBuilder: (_, __, ___) => Analytics(
            videoPath: currentVideoPath!,
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
    } else if (!isVideoLoaded || currentVideoPath == null) {
      _showErrorDialog('Please load a video before continuing');
    } else if (apiEndpoint == null) {
      _showErrorDialog('Please set an API endpoint in the navbar before continuing');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textScaler = MediaQuery.textScalerOf(context);
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: ParallaxRain(
        dropColors: const [Colors.white],
        dropHeight: 2,
        dropWidth: 0.5,
        dropFallSpeed: 0.5,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/Back light.png',
                fit: BoxFit.cover,
                width: size.width,
              ),
            ),
            SizedBox(
              height: size.height,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: isMobile ? 80.0 : 150.0,
                    bottom: isMobile ? 30.0 : 50.0,
                  ),
                  child: isMobile
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildContentChildren(context, size, textScaler, isMobile),
                  )
                      : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildContentChildren(context, size, textScaler, isMobile),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: FloatingAppBar(
                title: 'TimeClip AI',
                selectedIndex: selectedIndex,
                onItemSelected: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                onEndpointChanged: _onEndpointChanged,
                videoPath: currentVideoPath,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build content children (used for both mobile and desktop layouts)
// Build content children (used for both mobile and desktop layouts)
  List<Widget> _buildContentChildren(
      BuildContext context, Size size, TextScaler textScaler, bool isMobile) {
    return [
      Expanded(
        flex: isMobile ? 0 : 1,
        child: Padding(
          padding: EdgeInsets.only(
            left: isMobile ? 20 : 40,
            right: isMobile ? 20 : 20,
            bottom: isMobile ? 20 : 0,
          ),
          child: Container(
            height: isMobile ? size.width * 0.6 : 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isVideoLoaded
                  ? Video(
                controller: controller,
                fill: Colors.black,
              )
                  : _buildVideoPlaceholder(textScaler, isMobile),
            ),
          ),
        ),
      ),
      Expanded(
        flex: isMobile ? 0 : 1,
        child: Padding(
          padding: EdgeInsets.only(
            left: isMobile ? 20 : 40,
            right: isMobile ? 20 : 20,
            bottom: isMobile ? 20 : 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.upload_file,
                          color: Colors.white,
                          size: textScaler.scale(isMobile ? 20 : 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Upload & Configure',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: textScaler.scale(isMobile ? 18 : 20),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Upload your video file and configure settings to get started with TimeClip AI analysis.',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: textScaler.scale(isMobile ? 12 : 14),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video File',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: textScaler.scale(isMobile ? 14 : 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (currentVideoPath != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[900]!.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[700]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[400],
                              size: textScaler.scale(isMobile ? 14 : 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentVideoPath!.split(Platform.pathSeparator).last,
                                style: TextStyle(
                                  color: Colors.green[400],
                                  fontSize: textScaler.scale(isMobile ? 11 : 12),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.video_file,
                            label: 'Load Video',
                            onPressed: _pickAndLoadVideo,
                            isPrimary: true,
                          ),
                        ),
                        if (isVideoLoaded) ...[
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.clear,
                            label: 'Clear',
                            onPressed: _clearVideo,
                            isPrimary: false,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              _buildStatusSection(textScaler, isMobile),
              SizedBox(height: isMobile ? 16 : 24),
              if (isVideoLoaded && apiEndpoint != null)
                _buildSubmitButton(isMobile),
            ],
          ),
        ),
      ),
    ];
  }

  // Build status section
  Widget _buildStatusSection(TextScaler textScaler, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: textScaler.scale(isMobile ? 14 : 16),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusItem(
            icon: isVideoLoaded ? Icons.check_circle : Icons.error,
            text: isVideoLoaded ? 'Video loaded' : 'No video loaded',
            isComplete: isVideoLoaded,
            textScaler: textScaler,
            isMobile: isMobile,
          ),
          const SizedBox(height: 8),
          _buildStatusItem(
            icon: apiEndpoint != null ? Icons.check_circle : Icons.error,
            text: apiEndpoint != null ? 'API endpoint set' : 'No API endpoint set',
            isComplete: apiEndpoint != null,
            textScaler: textScaler,
            isMobile: isMobile,
          ),
          if (apiEndpoint != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Endpoint: ${apiEndpoint!.length > 40 ? '${apiEndpoint!.substring(0, 40)}...' : apiEndpoint!}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: textScaler.scale(isMobile ? 9 : 10),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Build status item
  Widget _buildStatusItem({
    required IconData icon,
    required String text,
    required bool isComplete,
    required TextScaler textScaler,
    required bool isMobile,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isComplete ? Colors.green[400] : Colors.red[400],
          size: textScaler.scale(isMobile ? 14 : 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isComplete ? Colors.green[400] : Colors.red[400],
              fontSize: textScaler.scale(isMobile ? 12 : 14),
            ),
          ),
        ),
      ],
    );
  }

  // Build action button
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF8B5CF6) : Colors.grey[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  // Build video placeholder
  Widget _buildVideoPlaceholder(TextScaler textScaler, bool isMobile) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[800]!,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: textScaler.scale(isMobile ? 60 : 80),
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          GradientText(
            'No Video Loaded',
            style: TextStyle(
              fontSize: textScaler.scale(isMobile ? 20 : 24),
              fontWeight: FontWeight.bold,
            ),
            colors: const [
              Colors.white,
              Colors.grey,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Load Video" to select a video file',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: textScaler.scale(isMobile ? 12 : 14),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build submit button
  Widget _buildSubmitButton(bool isMobile) {
    return Container(
      width: double.infinity,
      height: isMobile ? 45 : 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green[400]!,
            Colors.teal[400]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _navigateToAnalytics,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: isMobile ? 18 : 20,
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Text(
                  'Start Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: isMobile ? 18 : 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}