import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  int selectedIndex = -1;

  // Video player components
  late final Player player;
  late final VideoController controller;
  String? currentVideoPath;
  bool isVideoLoaded = false;

  // Endpoint input components
  final TextEditingController _endpointController = TextEditingController();
  String? apiEndpoint;
  bool isEndpointValid = false;

  @override
  void initState() {
    super.initState();
    // Initialize video player
    player = Player();
    controller = VideoController(player);

    // Listen to player state changes
    player.stream.buffering.listen((buffering) {
      if (mounted) {
        setState(() {
          // Update UI based on buffering state if needed
        });
      }
    });

    // Listen to endpoint input changes
    _endpointController.addListener(_validateEndpoint);
  }

  @override
  void dispose() {
    player.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  // Validate endpoint input
  void _validateEndpoint() {
    final input = _endpointController.text.trim();
    setState(() {
      isEndpointValid = input.isNotEmpty &&
          (input.startsWith('http://') || input.startsWith('https://'));
      print('Endpoint input: $input, isValid: $isEndpointValid');
    });
  }

  // Method to pick and load video file
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

  // Method to load video from specific path
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

  // Submit endpoint
  void _submitEndpoint() {
    if (isEndpointValid) {
      setState(() {
        apiEndpoint = _endpointController.text.trim();
        print('Endpoint submitted: $apiEndpoint, isEndpointValid: $isEndpointValid');
      });
    } else {
      _showErrorDialog('Please enter a valid API endpoint (must start with http:// or https://)');
    }
  }

  void _navigateToNextPage() {
    print('Navigating - isVideoLoaded: $isVideoLoaded, currentVideoPath: $currentVideoPath, apiEndpoint: $apiEndpoint');
    if (isVideoLoaded && currentVideoPath != null && apiEndpoint != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 500),
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
      _showErrorDialog('Please submit a valid API endpoint before continuing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 1000,
                      height: 500,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: isVideoLoaded
                            ? Video(
                          controller: controller,
                          fill: Colors.black,
                        )
                            : _buildVideoPlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 800,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (currentVideoPath != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Playing: ${currentVideoPath!.split('\\').last}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildControlButton(
                                icon: Icons.video_file,
                                label: 'Load Video',
                                onPressed: _pickAndLoadVideo,
                              ),
                              if (isVideoLoaded)
                                _buildControlButton(
                                  icon: Icons.clear,
                                  label: 'Clear',
                                  onPressed: _clearVideo,
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Endpoint upload section
                          _buildEndpointSection(),
                          const SizedBox(height: 24),
                          // Submit button - only shown when video and endpoint are ready
                          if (isVideoLoaded && apiEndpoint != null)
                            _buildSubmitButton(),
                        ],
                      ),
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
              title: 'TimeClip AI',
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

  // Build endpoint upload section
  Widget _buildEndpointSection() {
    return Container(
      width: 600,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter API Endpoint',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _endpointController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'https://example.com/api/predict',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isEndpointValid ? Colors.green[400]! : Colors.grey[600]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.blue[400]!,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.red[400]!,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.link,
                      color: Colors.grey[400],
                    ),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue[400]!,
                      Colors.purple[400]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: isEndpointValid ? _submitEndpoint : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (apiEndpoint != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Endpoint set: $apiEndpoint',
                style: TextStyle(
                  color: Colors.green[400],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Build video placeholder when no video is loaded
  Widget _buildVideoPlaceholder() {
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
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          GradientText(
            'No Video Loaded',
            style: const TextStyle(
              fontSize: 24,
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
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build control button
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Build submit button
  Widget _buildSubmitButton() {
    return Container(
      width: 200,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green[400]!,
            Colors.teal[400]!,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
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
          borderRadius: BorderRadius.circular(25),
          onTap: _navigateToNextPage,
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}