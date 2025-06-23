// models/video_analytics_models.dart

import 'dart:ui';

import 'package:flutter/material.dart';

class VideoAnalyticsResponse {
  final String videoName;
  final List<PredictionSegment> predSegments;

  VideoAnalyticsResponse({
    required this.videoName,
    required this.predSegments,
  });

  factory VideoAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return VideoAnalyticsResponse(
      videoName: json['video_name'] as String,
      predSegments: (json['pred_segments'] as List<dynamic>)
          .map((segment) => PredictionSegment.fromJson(segment as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'video_name': videoName,
      'pred_segments': predSegments.map((segment) => segment.toJson()).toList(),
    };
  }

  // Get all unique labels from segments
  List<String> get uniqueLabels {
    return predSegments
        .map((segment) => segment.label)
        .toSet()
        .toList()
      ..sort();
  }

  // Get segments by label
  List<PredictionSegment> getSegmentsByLabel(String label) {
    return predSegments
        .where((segment) => segment.label == label)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }
}

class PredictionSegment {
  final String label;
  final double start;
  final double end;
  final double duration;
  final double score;

  PredictionSegment({
    required this.label,
    required this.start,
    required this.end,
    required this.duration,
    required this.score,
  });

  factory PredictionSegment.fromJson(Map<String, dynamic> json) {
    return PredictionSegment(
      label: json['label'] as String,
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      score: (json['score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'start': start,
      'end': end,
      'duration': duration,
      'score': score,
    };
  }

  // Format time as MM:SS
  String get formattedStartTime {
    final minutes = (start / 60).floor();
    final seconds = (start % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedEndTime {
    final minutes = (end / 60).floor();
    final seconds = (end % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDuration {
    final seconds = duration.floor();
    final milliseconds = ((duration - seconds) * 1000).floor();
    return '${seconds}s ${milliseconds}ms';
  }

  // Get confidence level based on score
  String get confidenceLevel {
    if (score >= 0.7) return 'High';
    if (score >= 0.4) return 'Medium';
    return 'Low';
  }

  Color get confidenceColor {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }
}