
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import '../Common/widgets/Appbar.dart';
import '../home/home.dart';

class Analytics extends StatefulWidget {
  final String? videoPath;
  final String? apiEndpoint; // Add API endpoint parameter

  const Analytics({super.key, this.videoPath, this.apiEndpoint});

  @override
  State<Analytics> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<Analytics> {
  int selectedIndex = -1;
  String? selectedActionFilter; // For filtering timeline by action class

  // Video player components
  late final Player player;
  late final VideoController controller;
  bool isVideoLoaded = false;
  bool isVideoLoading = true;
  String? videoErrorMessage;

  // API data components
  List<Map<String, dynamic>> timelineData = [];
  bool isApiLoading = true;
  String? apiErrorMessage;

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

    // Load video if path is provided
    if (widget.videoPath != null) {
      _loadVideoFromPath(widget.videoPath!);
    } else {
      setState(() {
        isVideoLoading = false;
        videoErrorMessage = 'No video path provided';
      });
    }

    // Fetch timeline data from API
    _fetchTimelineData();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  // Fetch timeline data from API
  Future<void> _fetchTimelineData() async {
    try {
      setState(() {
        isApiLoading = true;
        apiErrorMessage = null;
      });

      // Use provided API endpoint or default
      final String apiUrl = widget.apiEndpoint ?? 'https://c315-34-139-115-168.ngrok-free.app/predict';
      String? videoName = widget.videoPath?.split('\\').last.split('.').first;

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "video_path": "./data/I3D/$videoName.mp4",
          "video_name": videoName
        }),
      ).timeout(
        const Duration(seconds: 200), // 200 second timeout
        onTimeout: () {
          throw Exception('Request timeout - API took too long to respond');
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        // Handle different possible API response structures
        List<dynamic> apiTimelineData;

        if (jsonData.containsKey('data')) {
          // If API returns {data: [...], status: "success", etc.}
          apiTimelineData = jsonData['data'];
        } else if (jsonData.containsKey('timeline')) {
          // If API returns {timeline: [...], etc.}
          apiTimelineData = jsonData['timeline'];
        } else if (jsonData.containsKey('actions')) {
          // If API returns {actions: [...], etc.}
          apiTimelineData = jsonData['actions'];
        } else if (jsonData is List) {
          // If API returns array directly
          apiTimelineData = jsonData as List;
        } else {
          // Try to find the first array in the response
          apiTimelineData = jsonData.values.firstWhere(
                (value) => value is List,
            orElse: () => [],
          );
        }

        // Validate and parse the timeline data
        final List<Map<String, dynamic>> parsedData = [];

        for (var item in apiTimelineData) {
          if (item is Map<String, dynamic>) {
            // Ensure all required fields exist with fallback values
            final parsedItem = {
              'label': item['label']?.toString() ?? item['action']?.toString() ?? item['class']?.toString() ?? 'Unknown',
              'start': _parseDouble(item['start'] ?? item['start_time'] ?? item['startTime'] ?? 0),
              'end': _parseDouble(item['end'] ?? item['end_time'] ?? item['endTime'] ?? 0),
              'duration': _parseDouble(item['duration'] ?? 0),
              'score': _parseDouble(item['score'] ?? item['confidence'] ?? item['probability'] ?? 0),
            };

            // Calculate duration if not provided
            // if (parsedItem['duration'] == 0 && parsedItem['end']! > parsedItem['start']) {
            //   parsedItem['duration'] = (parsedItem['end'] - parsedItem['start'])!;
            // }

            parsedData.add(parsedItem);
          }
        }

        if (mounted) {
          setState(() {
            timelineData = parsedData;
            isApiLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load timeline data: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching timeline data: $e');
      if (mounted) {
        setState(() {
          isApiLoading = false;
          apiErrorMessage = 'Error loading timeline data: ${e.toString()}';
          // Optionally load fallback data
          _loadFallbackData();
        });
      }
    }
  }

  // Helper method to safely parse double values
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Load fallback data if API fails
  void _loadFallbackData() {
    timelineData = [
      {
        "label": "Open",
        "start": 108.84,
        "end": 110.88,
        "duration": 2.04,
        "score": 0.103
      },
      {
        "label": "Take",
        "start": 114.83,
        "end": 116.67,
        "duration": 1.84,
        "score": 0.104
      },
      {
        "label": "Cut",
        "start": 120.5,
        "end": 122.3,
        "duration": 1.8,
        "score": 0.75
      },
    ];
  }

  // Retry API call
  void _retryApiCall() {
    _fetchTimelineData();
  }

  // Get unique action classes for chips
  List<String> get uniqueActionClasses {
    return timelineData.map((item) => item['label'] as String).toSet().toList();
  }

  // Get filtered timeline data based on selected action
  List<Map<String, dynamic>> get filteredTimelineData {
    if (selectedActionFilter == null) {
      return timelineData;
    }
    return timelineData.where((item) => item['label'] == selectedActionFilter).toList();
  }

  // Method to load video from specific path
  Future<void> _loadVideoFromPath(String filePath) async {
    try {
      setState(() {
        isVideoLoading = true;
        videoErrorMessage = null;
      });

      final file = File(filePath);
      if (await file.exists()) {
        await player.open(Media('file:///$filePath'));

        if (mounted) {
          setState(() {
            isVideoLoaded = true;
            isVideoLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isVideoLoading = false;
            videoErrorMessage = 'Video file not found at: $filePath';
          });
        }
      }
    } catch (e) {
      print('Error loading video: $e');
      if (mounted) {
        setState(() {
          isVideoLoading = false;
          videoErrorMessage = 'Error loading video: $e';
        });
      }
    }
  }

  // Retry loading video
  void _retryVideoLoading() {
    if (widget.videoPath != null) {
      _loadVideoFromPath(widget.videoPath!);
    }
  }

  // Get color for different action labels
  Color _getActionColor(String label) {
    switch (label.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'take':
        return Colors.green;
      case 'cut':
        return Colors.red;
      case 'close':
        return Colors.orange;
      case 'slicing':
        return Colors.purple;
      case 'cooking':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  // Format timestamp to readable format
  String _formatTimestamp(double timestamp) {
    int minutes = (timestamp / 60).floor();
    int seconds = (timestamp % 60).floor();
    int milliseconds = ((timestamp % 1) * 1000).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}';
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
          // Main content
          Padding(
            padding: const EdgeInsets.only(top: 100.0, left: 70.0, right: 70.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Video container
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 850,
                            child: Text(
                              "Here's the Predicted Action Classes from your Video...",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Show loading or error state for API
                          if (isApiLoading)
                            _buildApiLoadingWidget()
                          else if (apiErrorMessage != null)
                            _buildApiErrorWidget()
                          else
                            _buildFilterChips(),

                          const SizedBox(height: 30),
                          // Timeline section
                          Container(
                            width: 850,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTimelineHeader(),
                                const SizedBox(height: 20),
                                _buildTimelineContent(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            width: 500,
                            height: 300,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildVideoContent(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Video info and controls
                          _buildVideoInfo(),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Floating AppBar
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: FloatingAppBar(
              title: 'TimeClip AI - Analytics',
              selectedIndex: selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              isLandingPage: false,
            ),
          ),
        ],
      ),
    );
  }

  // Build API loading widget
  Widget _buildApiLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Loading timeline data from API...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Build API error widget
  Widget _buildApiErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[900]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'API Error',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            apiErrorMessage!,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _retryApiCall,
                icon: Icon(Icons.refresh, size: 16),
                label: Text('Retry API Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              if (timelineData.isNotEmpty) ...[
                const SizedBox(width: 12),
                Text(
                  'Using fallback data (${timelineData.length} items)',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Build filter chips
  Widget _buildFilterChips() {
    return Container(
      width: 850,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _buildFilterChip('All'),
          ...uniqueActionClasses.map((action) => _buildFilterChip(action)).toList(),
        ],
      ),
    );
  }

  // Build timeline header
  Widget _buildTimelineHeader() {
    return Row(
      children: [
        Text(
          'Action Timeline',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        if (selectedActionFilter != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getActionColor(selectedActionFilter!).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getActionColor(selectedActionFilter!),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filtered: $selectedActionFilter',
                  style: TextStyle(
                    color: _getActionColor(selectedActionFilter!),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${filteredTimelineData.length} items)',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        // API status indicator
        if (timelineData.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[900]!.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_done,
                  color: Colors.green[400],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'API Data (${timelineData.length})',
                  style: TextStyle(
                    color: Colors.green[400],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Build timeline content
  Widget _buildTimelineContent() {
    if (isApiLoading) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading timeline data...',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildTimeline();
  }

  // Build the timeline widget (existing method, unchanged)
  Widget _buildTimeline() {
    final dataToShow = filteredTimelineData;

    if (dataToShow.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list_off,
                size: 48,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                selectedActionFilter != null
                    ? 'No actions found for "$selectedActionFilter"'
                    : 'No timeline data available',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              if (selectedActionFilter != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedActionFilter = null;
                    });
                  },
                  child: Text(
                    'Show All Actions',
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontSize: 14,
                    ),
                  ),
                )
              else if (apiErrorMessage != null)
                TextButton(
                  onPressed: _retryApiCall,
                  child: Text(
                    'Retry Loading Data',
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 400,
      child: ListView.builder(
        itemCount: dataToShow.length,
        itemBuilder: (context, index) {
          final item = dataToShow[index];
          final isFirst = index == 0;
          final isLast = index == dataToShow.length - 1;

          return TimelineTile(
            alignment: TimelineAlign.start,
            isFirst: isFirst,
            isLast: isLast,
            indicatorStyle: IndicatorStyle(
              width: 24,
              height: 24,
              indicator: Container(
                decoration: BoxDecoration(
                  color: _getActionColor(item['label']),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  _getActionIcon(item['label']),
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
            beforeLineStyle: LineStyle(
              color: Colors.grey[600]!,
              thickness: 2,
            ),
            endChild: Container(
              margin: const EdgeInsets.only(left: 16, bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getActionColor(item['label']).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getActionColor(item['label']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item['label'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Score: ${(item['score'] * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.play_arrow,
                        color: Colors.green[400],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Start: ${_formatTimestamp(item['start'])}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.stop,
                        color: Colors.red[400],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'End: ${_formatTimestamp(item['end'])}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        color: Colors.blue[400],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Duration: ${item['duration'].toStringAsFixed(2)}s',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Get icon for different action labels
  IconData _getActionIcon(String label) {
    switch (label.toLowerCase()) {
      case 'open':
        return Icons.open_in_new;
      case 'take':
        return Icons.pan_tool;
      case 'cut':
        return Icons.content_cut;
      case 'close':
        return Icons.close;
      case 'slicing':
        return Icons.cut;
      case 'cooking':
        return Icons.local_fire_department;
      default:
        return Icons.circle;
    }
  }

  // Build video content based on current state
  Widget _buildVideoContent() {
    if (isVideoLoading) {
      return _buildLoadingPlaceholder();
    } else if (videoErrorMessage != null) {
      return _buildErrorPlaceholder();
    } else if (isVideoLoaded) {
      return Video(
        controller: controller,
        fill: Colors.black,
      );
    } else {
      return _buildVideoPlaceholder();
    }
  }

  // Build loading placeholder
  Widget _buildLoadingPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.transparent,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 16),
          GradientText(
            'Loading Video...',
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
          if (widget.videoPath != null)
            Text(
              'Loading: ${widget.videoPath!.split('\\').last}',
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

  // Build error placeholder
  Widget _buildErrorPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red[900]!.withOpacity(0.3),
            Colors.grey[900]!,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          GradientText(
            'Error Loading Video',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            colors: [
              Colors.red[300]!,
              Colors.grey,
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              videoErrorMessage!,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _retryVideoLoading,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
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
            Icons.video_library_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          GradientText(
            'No Video Available',
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
            'No video path was provided',
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

  // Build video info section
  Widget _buildVideoInfo() {
    if (widget.videoPath == null) return const SizedBox.shrink();

    return Container(
      width: 500,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.video_file,
                color: Colors.blue[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Video: ${widget.videoPath!.split('\\').last}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isVideoLoaded ? Icons.check_circle : Icons.pending,
                color: isVideoLoaded ? Colors.green[400] : Colors.orange[400],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isVideoLoaded ? 'Video loaded successfully' : 'Loading video...',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), // Rounded shape
      ),
      child: Center(
        child: Chip(
          label: Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 1.2),
          ),
          backgroundColor: Color(0xff5A1E96), // Remove default chip background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white), // Optional: subtle border
          ),
        ),
      ),
    );
  }

  // Build filter chip with selection functionality
  Widget _buildFilterChip(String label) {
    final bool isSelected = (label == 'All' && selectedActionFilter == null) ||
        (selectedActionFilter == label);
    final bool isAllOption = label == 'All';

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isAllOption) {
            selectedActionFilter = null;
          } else {
            selectedActionFilter = isSelected ? null : label;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [
            BoxShadow(
              color: (isAllOption ? Colors.blue : _getActionColor(label)).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ] : [],
        ),
        child: Chip(
          label: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[300],
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              height: 1.2,
            ),
          ),
          backgroundColor: isSelected
              ? (isAllOption ? Colors.blue : _getActionColor(label))
              : Colors.grey[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? (isAllOption ? Colors.blue : _getActionColor(label))
                  : Colors.grey[600]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          elevation: isSelected ? 4 : 0,
        ),
      ),
    );
  }
}