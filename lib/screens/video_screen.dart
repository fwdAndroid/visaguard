import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visaguard/screens/main/main_dashboard_screen.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  VideoPlayerController? _controller;
  bool _isButtonEnabled = false;
  bool _isLoading = true;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      // Fetch first video URL from Firestore 'videos' collection
      final snapshot = await FirebaseFirestore.instance
          .collection('videos')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Directly use the 'url' field from Firestore
        final videoUrl = snapshot.docs.first['url'] as String;

        _controller = VideoPlayerController.network(videoUrl)
          ..initialize().then((_) {
            setState(() {
              _isLoading = false;
            });
            _controller!.play();

            // Listen for progress
            _controller!.addListener(_checkProgress);
          });

        // Prevent scrubbing by disabling gestures
        _controller!.setLooping(false);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading video: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkProgress() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    if (duration.inSeconds == 0) return;

    final watchedPercent = position.inMilliseconds / duration.inMilliseconds;

    // Update progress bar
    setState(() {
      _progress = watchedPercent.clamp(0.0, 1.0);
    });

    if (watchedPercent >= 0.9 && !_isButtonEnabled) {
      setState(() {
        _isButtonEnabled = true;
      });
    }

    // Prevent skipping: if user tries to seek ahead, reset to current progress
    if (position > duration * watchedPercent) {
      _controller!.seekTo(duration * watchedPercent);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_checkProgress);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watch Video')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_controller != null && _controller!.value.isInitialized)
                  AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: Stack(
                      children: [
                        VideoPlayer(_controller!),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.black26,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Watched: ${(_progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isButtonEnabled
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MainDashboardScreen()),
                          );
                        }
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
    );
  }
}
