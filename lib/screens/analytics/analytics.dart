import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:parallax_rain/parallax_rain.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'dart:async';
import '../Common/widgets/Appbar.dart';
import '../home/home.dart';

class Analytics extends StatefulWidget {
  final String? videoPath;
  final String? apiEndpoint;

  const Analytics({super.key, this.videoPath, this.apiEndpoint});

  @override
  State<Analytics> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<Analytics> {
  int selectedIndex = 1; // Default to Analytics
  String? selectedActionFilter;
  late final Player player;
  late final VideoController controller;
  bool isVideoLoaded = false;
  bool isVideoLoading = true;
  String? videoErrorMessage;
  String? videoStreamUrl;
  List<Map<String, dynamic>> timelineData = [];
  bool isApiLoading = true;
  String? apiErrorMessage;
  Timer? _pollingTimer;
  String? _videoTaskId;
  final ScrollController _timelineScrollController = ScrollController();


  final Map<String, Color> _actionColorCache = {};
  final List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.deepOrange,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    player = Player();
    _timelineScrollController.dispose();
    controller = VideoController(player);

    player.stream.buffering.listen((buffering) {
      if (mounted) {
        setState(() {});
      }
    });

    if (widget.videoPath != null) {
      _fetchTimelineData();
    } else {
      setState(() {
        isVideoLoading = false;
        videoErrorMessage = 'No video path provided';
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    player.dispose();
    super.dispose();
  }

  // Fetch timeline data
  Future<void> _fetchTimelineData() async {
    try {
      setState(() {
        isApiLoading = true;
        apiErrorMessage = null;
        _actionColorCache.clear();
      });

      final String apiUrl = '${widget.apiEndpoint ?? 'https://c315-34-139-115-168.ngrok-free.app/'}/predict';
      String? videoName = widget.videoPath?.split(Platform.pathSeparator).last.split('.').first;

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "video_path": "./data/Test/$videoName.mp4",//
          "video_name": videoName
        }),
      ).timeout(
        const Duration(seconds: 200),
        onTimeout: () {
          throw Exception('Request timeout - API took too long to respond');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        _videoTaskId = jsonData['video_task_id']?.toString();
        if (_videoTaskId != null) {
          _pollTaskStatus(widget.apiEndpoint, _videoTaskId!);
        } else {
          setState(() {
            isVideoLoading = false;
            videoErrorMessage = 'No video_task_id found in API response';
          });
        }

        List<dynamic> apiTimelineData;
        if (jsonData.containsKey('data')) {
          apiTimelineData = jsonData['data'];
        } else if (jsonData.containsKey('timeline')) {
          apiTimelineData = jsonData['timeline'];
        } else if (jsonData.containsKey('actions')) {
          apiTimelineData = jsonData['actions'];
        } else if (jsonData is List) {
          apiTimelineData = jsonData as List;
        } else {
          apiTimelineData = jsonData.values.firstWhere(
                (value) => value is List,
            orElse: () => [],
          );
        }

        final List<Map<String, dynamic>> parsedData = [];
        for (var item in apiTimelineData) {
          if (item is Map<String, dynamic>) {
            final parsedItem = {
              'label': item['label']?.toString() ?? item['action']?.toString() ?? item['class']?.toString() ?? 'Unknown',
              'start': _parseDouble(item['start'] ?? item['start_time'] ?? item['startTime'] ?? 0),
              'end': _parseDouble(item['end'] ?? item['end_time'] ?? item['endTime'] ?? 0),
              'duration': _parseDouble(item['duration'] ?? 0),
              'score': _parseDouble(item['score'] ?? item['confidence'] ?? item['probability'] ?? 0),
            };
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
          _loadFallbackData();
        });
      }
    }
  }

  List<String> get alphabeticallySortedActions {
    return uniqueActionClasses..sort();
  }
  void _scrollToAction(String action) {
    final dataToShow = filteredTimelineData;
    final index = dataToShow.indexWhere((item) => item['label'] == action);

    if (index != -1) {
      // Calculate approximate position (each timeline item is roughly 120px height)
      final double position = index * 120.0;
      _timelineScrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }



  // Poll task status
  Future<void> _pollTaskStatus(String? baseUrl, String videoTaskId) async {
    const Duration pollInterval = Duration(seconds: 5);
    const int maxAttempts = 60;
    int attempts = 0;

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(pollInterval, (timer) async {
      if (!mounted || attempts >= maxAttempts) {
        timer.cancel();
        if (mounted) {
          setState(() {
            isVideoLoading = false;
            videoErrorMessage = 'Video generation timed out after ${maxAttempts * pollInterval.inSeconds}s';
          });
        }
        return;
      }

      try {
        final response = await http.get(
          Uri.parse('$baseUrl/task_status/$videoTaskId'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Task status request timeout');
          },
        );

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          final String status = jsonData['status']?.toString() ?? 'unknown';
          final String? videoStreamUrlFromApi = jsonData['video_stream_url']?.toString();

          if (status == 'completed' && videoStreamUrlFromApi != null) {
            timer.cancel();
            setState(() {
              videoStreamUrl = videoStreamUrlFromApi;
              _loadVideoFromUrl(videoStreamUrl!);
            });
          } else if (status == 'failed') {
            timer.cancel();
            setState(() {
              isVideoLoading = false;
              videoErrorMessage = jsonData['error']?.toString() ?? 'Video generation failed';
            });
          }
        } else {
          throw Exception('Failed to fetch task status: ${response.statusCode}');
        }
      } catch (e) {
        print('Error polling task status: $e');
        attempts++;
        if (attempts >= maxAttempts) {
          timer.cancel();
          if (mounted) {
            setState(() {
              isVideoLoading = false;
              videoErrorMessage = 'Error polling task status: $e';
            });
          }
        }
      }
    });
  }

  // Parse double values
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Load fallback data
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

  // Get unique action classes
  List<String> get uniqueActionClasses {
    return timelineData.map((item) => item['label'] as String).toSet().toList();
  }

  // Get filtered timeline data
  List<Map<String, dynamic>> get filteredTimelineData {
    if (selectedActionFilter == null) {
      return timelineData;
    }
    return timelineData.where((item) => item['label'] == selectedActionFilter).toList();
  }

  // Load video from URL
  Future<void> _loadVideoFromUrl(String url) async {
    try {
      setState(() {
        isVideoLoading = true;
        videoErrorMessage = null;
      });

      await player.open(Media(url), play: true);

      if (mounted) {
        setState(() {
          isVideoLoaded = true;
          isVideoLoading = false;
        });
      }
    } catch (e) {
      print('Error loading video: $e');
      if (mounted) {
        setState(() {
          isVideoLoading = false;
          isVideoLoaded = false;
          videoErrorMessage = 'Error loading video: $e';
        });
      }
    }
  }

  // Retry video loading
  void _retryVideoLoading() {
    if (_videoTaskId != null) {
      _pollTaskStatus(widget.apiEndpoint, _videoTaskId!);
    } else if (widget.videoPath != null) {
      _fetchTimelineData();
    }
  }

  // Get action color
  Color _getActionColor(String label) {
    if (_actionColorCache.containsKey(label)) {
      return _actionColorCache[label]!;
    }
    final color = _colors[Random().nextInt(_colors.length)];
    _actionColorCache[label] = color;
    return color;
  }

  // Format timestamp
  String _formatTimestamp(double timestamp) {
    int minutes = (timestamp / 60).floor();
    int seconds = (timestamp % 60).floor();
    int milliseconds = ((timestamp % 1) * 1000).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLargeScreen = screenSize.width > 800;
    final double padding = screenSize.width * 0.05;
    const double videoAspectRatio = 16 / 9;

    return Scaffold(
      backgroundColor: Colors.black,
      body: ParallaxRain(
        dropColors: const [Colors.white],
        dropHeight: 2,
        dropWidth: 0.5,
        dropFallSpeed: 0.5,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/Back light.png',
                width: screenSize.width,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: screenSize.height * 0.05,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FloatingAppBar(
                          title: 'TimeClip AI - Analytics',
                          selectedIndex: selectedIndex,
                          onItemSelected: (index) {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          isLandingPage: false,
                          videoPath: widget.videoPath,
                        ),
                        SizedBox(height: screenSize.height * 0.02),
                        isLargeScreen
                            ? _buildLargeScreenLayout(context, screenSize, videoAspectRatio)
                            : _buildSmallScreenLayout(context, screenSize, videoAspectRatio),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Large screen layout
  Widget _buildLargeScreenLayout(BuildContext context, Size screenSize, double videoAspectRatio) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Here's the Predicted Action Classes from your Video...",
                style: TextStyle(
                  fontSize: screenSize.width * 0.03,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.start,
              ),
              SizedBox(height: screenSize.height * 0.02),
              if (isApiLoading)
                _buildApiLoadingWidget()
              else if (apiErrorMessage != null)
                _buildApiErrorWidget()
              else
                _buildFilterChips(),
              SizedBox(height: screenSize.height * 0.03),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimelineHeader(),
                  SizedBox(height: screenSize.height * 0.02),
                  SizedBox(
                    height: screenSize.height * 0.5,
                    child: _buildTimelineContent(),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: screenSize.width * 0.03),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: videoAspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildVideoContent(),
                ),
              ),
              SizedBox(height: screenSize.height * 0.02),
              _buildVideoInfo(),
            ],
          ),
        ),
      ],
    );
  }

  // Small screen layout
  Widget _buildSmallScreenLayout(BuildContext context, Size screenSize, double videoAspectRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Here's the Predicted Action Classes from your Video...",
          style: TextStyle(
            fontSize: screenSize.width * 0.05,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.start,
        ),
        SizedBox(height: screenSize.height * 0.02),
        AspectRatio(
          aspectRatio: videoAspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildVideoContent(),
          ),
        ),
        SizedBox(height: screenSize.height * 0.02),
        _buildVideoInfo(),
        SizedBox(height: screenSize.height * 0.03),
        if (isApiLoading)
          _buildApiLoadingWidget()
        else if (apiErrorMessage != null)
          _buildApiErrorWidget()
        else
          _buildFilterChips(),
        SizedBox(height: screenSize.height * 0.03),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimelineHeader(),
            SizedBox(height: screenSize.height * 0.02),
            SizedBox(
              height: screenSize.height * 0.5,
              child: _buildTimelineContent(),
            ),
          ],
        ),
      ],
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
          const SizedBox(
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
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry API Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    final Size screenSize = MediaQuery.of(context).size;
    return Wrap(
      spacing: screenSize.width * 0.02,
      runSpacing: screenSize.height * 0.01,
      children: [
        _buildFilterChip('All'),
        ...uniqueActionClasses.map((action) => _buildFilterChip(action)).toList(),
      ],
    );
  }

  // Build timeline header
  Widget _buildTimelineHeader() {
    return Row(
      children: [
        const Text(
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
              const CircularProgressIndicator(
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

    return Row(
      children: [
        Expanded(
          child: _buildTimeline(),
        ),
        const SizedBox(width: 8),
        _buildTimelineSidebar(),
      ],
    );
  }

  Widget _buildTimelineSidebar() {
    final dataToShow = filteredTimelineData;
    if (dataToShow.isEmpty) return const SizedBox.shrink();

    final sortedActions = alphabeticallySortedActions;

    return Container(
      width: 40,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Icon(
              Icons.list,
              color: Colors.grey[400],
              size: 16,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sortedActions.length,
              itemBuilder: (context, index) {
                final action = sortedActions[index];
                final actionColor = _getActionColor(action);
                final isFiltered = selectedActionFilter == action;

                return GestureDetector(
                  onTap: () => _scrollToAction(action),
                  child: Container(
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: isFiltered
                          ? actionColor.withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isFiltered
                          ? Border.all(color: actionColor, width: 1)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        action.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: isFiltered ? actionColor : Colors.grey[400],
                          fontSize: 14,
                          fontWeight: isFiltered ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: GestureDetector(
              onTap: () {
                _timelineScrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.5)),
                ),
                child: Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.blue[400],
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // Build timeline
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
      child: Scrollbar(
        controller: _timelineScrollController,
        thumbVisibility: true,
        thickness: 8,
        radius: const Radius.circular(4),
        child: ListView.builder(
          controller: _timelineScrollController,
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
      ),
    );
  }


  // Get action icon
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

  // Build video content
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
            'Generating Video...',
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
          if (videoStreamUrl != null)
            Text(
              'Loading: ${videoStreamUrl!.split('/').last}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          if (_videoTaskId != null)
            Text(
              'Task ID: $_videoTaskId',
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

  // Build video placeholder
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
            'No video stream URL provided',
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

  // Build video info
  Widget _buildVideoInfo() {
    if (videoStreamUrl == null && widget.videoPath == null) return const SizedBox.shrink();

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
                  'Video: ${videoStreamUrl?.split('/').last ?? widget.videoPath!.split(Platform.pathSeparator).last}',
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
                isVideoLoaded ? 'Video loaded successfully' : 'Waiting for video generation...',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (_videoTaskId != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[400],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Task ID: $_videoTaskId',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Build filter chip
  Widget _buildFilterChip(String label) {
    final bool isSelected = (label == 'All' && selectedActionFilter == null) || (selectedActionFilter == label);
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
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: (isAllOption ? Colors.blue : _getActionColor(label)).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ]
              : [],
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