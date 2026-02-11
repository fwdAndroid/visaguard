import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visaguard/provider/language_provider.dart';
import 'package:visaguard/screens/main/main_dashboard_screen.dart';
import 'package:iconsax/iconsax.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> videos = [];
  int currentIndex = 0;

  VideoPlayerController? _controller;
  bool _isButtonEnabled = false;
  bool _isLoading = true;
  bool _isPlaying = true;
  bool _showControls = false;
  bool _hasError = false;
  double _progress = 0.0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('videos')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final loadedVideos = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'url': data['url'] as String? ?? '',
            'title': data['title'] as String? ?? 'Visa Process Video ${doc.id}',
            'description': data['description'] as String? ?? 'Important information about visa process',
           
          };
        }).toList();

        // Filter out videos with empty URLs
        final validVideos = loadedVideos.where((video) => (video['url'] as String?)?.isNotEmpty == true).toList();

        if (validVideos.isNotEmpty) {
          setState(() {
            videos = validVideos;
          });
          await _loadVideoAtIndex(0);
        } else {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading videos: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVideoAtIndex(int index) async {
    if (index < 0 || index >= videos.length) {
      debugPrint('Invalid index: $index');
      return;
    }

    // Dispose previous controller
    if (_controller != null) {
      _controller!.removeListener(_checkProgress);
      await _controller!.dispose();
    }

    final videoUrl = videos[index]['url'] as String;

    if (videoUrl.isEmpty) {
      debugPrint('Empty video URL at index: $index');
      return;
    }

    try {
      _controller = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _progress = 0.0;
              _isButtonEnabled = false;
              _isPlaying = true;
            });
            _controller!.play();
            _controller!.addListener(_checkProgress);
          }
        })
        ..addListener(() {
          if (_controller!.value.hasError) {
            debugPrint('Video error: ${_controller!.value.errorDescription}');
          }
        });

      _controller!.setLooping(false);
    } catch (e) {
      debugPrint('Error loading video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _checkProgress() {
    if (_controller == null || !_controller!.value.isInitialized || !mounted) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    if (duration.inMilliseconds == 0) return;

    final watchedPercent = position.inMilliseconds / duration.inMilliseconds;

    setState(() {
      _progress = watchedPercent.clamp(0.0, 1.0);
    });

    if (watchedPercent >= 0.95 && !_isButtonEnabled) {
      setState(() => _isButtonEnabled = true);
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  Future<void> _nextVideo() async {
    if (!_isButtonEnabled) return;

    _animationController.reset();
    await _animationController.forward();

    if (currentIndex < videos.length - 1) {
      setState(() {
        currentIndex++;
      });
      await _loadVideoAtIndex(currentIndex);
    } else {
      await _completeVideosAndNavigate();
    }
  }

  Future<void> _skipAllVideos() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Skip Videos',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            
            'Are you sure you want to skip all videos? You can watch them later from the help section.',
            style: const TextStyle(height: 1.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _completeVideosAndNavigate();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                 'Skip',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeVideosAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasWatchedVideos', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainDashboardScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  String _formatTime(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    } else {
      final minutes = duration.inMinutes.toString().padLeft(2, '0');
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_checkProgress);
    _controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            children: [
              // App Bar with Skip Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Logo/Back Button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Iconsax.video,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Title Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.localizedStrings["Learn About Visa Process"] ?? 'Learn About Visa Process',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            languageProvider.localizedStrings["Complete all videos to continue"] ?? 'Complete all videos to continue',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Video Counter
                    if (videos.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentIndex + 1}/${videos.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    
                    const SizedBox(width: 12),
                    
                    // Skip Button
                    if (videos.isNotEmpty)
                      TextButton(
                        onPressed: _skipAllVideos,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          languageProvider.localizedStrings["Skip"] ?? 'Skip',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingScreen(isDarkMode)
                    : _hasError || videos.isEmpty
                        ? _buildErrorScreen(isDarkMode)
                        : _buildVideoContent(context, isDarkMode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(bool isDarkMode) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.blue[700]!),
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            languageProvider.localizedStrings["Loading videos..."] ?? 'Loading videos...',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(bool isDarkMode) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              languageProvider.localizedStrings["No Videos Available"] ?? 'No Videos Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              languageProvider.localizedStrings["There are no videos to display at the moment."] ??
              'There are no videos to display at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadVideos,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(languageProvider.localizedStrings["Retry"] ?? 'Retry'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _skipAllVideos,
              child: Text(
                languageProvider.localizedStrings["Skip to Dashboard"] ?? 'Skip to Dashboard',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent(BuildContext context, bool isDarkMode) {
    final currentVideo = videos[currentIndex];
    final hasNextVideo = currentIndex < videos.length - 1;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Video Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.play_circle_filled_rounded,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentVideo['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.grey[900],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currentVideo['description'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Video Player
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _showControls = !_showControls);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (_controller != null && _controller!.value.isInitialized)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
                      ),

                    // Controls Overlay
                    if (_showControls)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: IconButton(
                            onPressed: _togglePlayPause,
                            icon: Icon(
                              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              size: 60,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ),

                    // Progress Bar
                    if (_controller != null && _controller!.value.isInitialized)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.blue[700],
                                  inactiveTrackColor: Colors.grey[600],
                                  thumbColor: Colors.blue[700],
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                  trackHeight: 3,
                                ),
                                child: Slider(
                                  value: _progress,
                                  onChanged: (value) {
                                    if (_controller != null && _controller!.value.isInitialized) {
                                      final position = _controller!.value.duration * value;
                                      _controller!.seekTo(position);
                                    }
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatTime(_controller!.value.position),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _formatTime(_controller!.value.duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Play/Pause Button (always visible minimal)
                    if (!_showControls && _controller != null && _controller!.value.isInitialized)
                      Center(
                        child: AnimatedOpacity(
                          opacity: _isPlaying ? 0 : 0.7,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.pause_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      languageProvider.localizedStrings["Completion Progress"] ?? 'Completion Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${((_progress) * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    color: Colors.blue[700],
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${languageProvider.localizedStrings["Video"] ?? "Video"} ${currentIndex + 1}/${videos.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    if (_progress >= 0.95)
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            languageProvider.localizedStrings["Ready to continue"] ?? 'Ready to continue',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Next Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isButtonEnabled ? _nextVideo : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isButtonEnabled
                    ? Colors.blue[700]
                    : Colors.grey[400],
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shadowColor: Colors.blue.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hasNextVideo
                        ? languageProvider.localizedStrings["Next Video"] ?? 'Next Video'
                        : languageProvider.localizedStrings["Complete & Continue"] ?? 'Complete & Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    hasNextVideo ? Icons.arrow_forward_rounded : Icons.check_circle_rounded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Skip Individual Video Button (optional)
          if (!_isButtonEnabled)
            TextButton(
              onPressed: _skipAllVideos,
              child: Text(
                languageProvider.localizedStrings["Skip All Videos"] ?? 'Skip All Videos',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}