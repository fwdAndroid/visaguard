import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visaguard/screens/main/main_dashboard_screen.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  List<Map<String, dynamic>> videos = [];
  int currentIndex = 0;

  VideoPlayerController? _controller;
  bool _isButtonEnabled = false;
  bool _isLoading = true;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('videos').get();

      if (snapshot.docs.isNotEmpty) {
        videos = snapshot.docs
            .map((doc) => {'id': doc.id, 'url': doc['url'] as String})
            .toList();

        _loadVideoAtIndex(0);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading videos: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVideoAtIndex(int index) async {
    if (_controller != null) {
      _controller!.removeListener(_checkProgress);
      await _controller!.dispose();
    }

    final videoUrl = videos[index]['url'];

    _controller = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isLoading = false;
          _progress = 0.0;
          _isButtonEnabled = false;
        });
        _controller!.play();
        _controller!.addListener(_checkProgress);
      });

    _controller!.setLooping(false);
  }

  void _checkProgress() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    if (duration.inMilliseconds == 0) return;

    final watchedPercent =
        position.inMilliseconds / duration.inMilliseconds;

    setState(() {
      _progress = watchedPercent.clamp(0.0, 1.0);
    });

    if (watchedPercent >= 0.9 && !_isButtonEnabled) {
      _isButtonEnabled = true;
    }
  }

  Future<void> _nextVideo() async {
    if (currentIndex < videos.length - 1) {
      currentIndex++;
      _loadVideoAtIndex(currentIndex);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasWatchedVideos', true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
      );
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
      appBar: AppBar(title: const Text('Watch Videos')),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Video ${currentIndex + 1} of ${videos.length}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Watched: ${(_progress * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isButtonEnabled ? _nextVideo : null,
                  child: Text(
                    currentIndex < videos.length - 1
                        ? 'Next Video'
                        : 'Go to Dashboard',
                  ),
                ),
              ],
            ),
    );
  }
}
