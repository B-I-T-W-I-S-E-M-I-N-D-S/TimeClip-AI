// widgets/timeline_widget.dart

import 'package:flutter/material.dart';
import '../../../models/AnalyticsResponse.dart';


class TimelineWidget extends StatelessWidget {
  final List<PredictionSegment> segments;
  final String selectedLabel;
  final Function(PredictionSegment) onSegmentTap;
  final double? videoDuration; // Total video duration for proper scaling

  const TimelineWidget({
    Key? key,
    required this.segments,
    required this.selectedLabel,
    required this.onSegmentTap,
    this.videoDuration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return _buildEmptyState();
    }

    // Calculate the maximum time for scaling
    final maxTime = videoDuration ??
        segments.map((s) => s.end).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTimelineScale(maxTime),
          const SizedBox(height: 12),
          _buildTimelineBar(maxTime),
          const SizedBox(height: 16),
          _buildSegmentsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xff5A1E96),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            selectedLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${segments.length} occurrence${segments.length != 1 ? 's' : ''}',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Icon(
          Icons.timeline,
          color: Colors.blue[400],
          size: 20,
        ),
      ],
    );
  }

  Widget _buildTimelineScale(double maxTime) {
    final intervals = _calculateTimeIntervals(maxTime);

    return Container(
      height: 20,
      child: Row(
        children: intervals.map((time) {
          final position = time / maxTime;
          return Expanded(
            flex: position == 0 ? 1 : (position * 100).round(),
            child: Text(
              _formatTime(time),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
              ),
              textAlign: position == 0 ? TextAlign.start : TextAlign.center,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineBar(double maxTime) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Background timeline
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[800]!,
                  Colors.grey[700]!,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // Segments
          ...segments.asMap().entries.map((entry) {
            final index = entry.key;
            final segment = entry.value;
            return _buildSegmentBar(segment, maxTime, index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSegmentBar(PredictionSegment segment, double maxTime, int index) {
    final leftPosition = (segment.start / maxTime);
    final width = (segment.duration / maxTime);

    return Positioned(
      left: leftPosition * 300, // Adjust based on container width
      top: 4,
      child: GestureDetector(
        onTap: () => onSegmentTap(segment),
        child: Container(
          width: width * 300, // Adjust based on container width
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xff5A1E96).withOpacity(0.8),
                const Color(0xff5A1E96),
              ],
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentsList() {
    return Container(
      height: 200,
      child: ListView.builder(
        itemCount: segments.length,
        itemBuilder: (context, index) {
          final segment = segments[index];
          return _buildSegmentItem(segment, index + 1);
        },
      ),
    );
  }

  Widget _buildSegmentItem(PredictionSegment segment, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[600]!,
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () => onSegmentTap(segment),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            // Segment number
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xff5A1E96),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Time range
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${segment.formattedStartTime} - ${segment.formattedEndTime}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Duration: ${segment.formattedDuration}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Confidence
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: segment.confidenceColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: segment.confidenceColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    segment.confidenceLevel,
                    style: TextStyle(
                      color: segment.confidenceColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(segment.score * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.play_arrow,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 12),
          Text(
            'No segments found for "$selectedLabel"',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  List<double> _calculateTimeIntervals(double maxTime) {
    // Calculate appropriate time intervals based on video duration
    final intervals = <double>[];
    final step = maxTime / 5; // Show 5 intervals

    for (int i = 0; i <= 5; i++) {
      intervals.add(i * step);
    }

    return intervals;
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}