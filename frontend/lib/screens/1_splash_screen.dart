import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/logo_video.mp4');
      await _videoController!.initialize();

      if (!mounted) return;

      setState(() {
        _isVideoInitialized = true;
      });

      _videoController!.setVolume(0.0); // Mute audio
      _videoController!.play();

      _videoController!.addListener(() {
        if (_videoController != null &&
            _videoController!.value.isInitialized &&
            !_hasNavigated) {
          final position = _videoController!.value.position;
          final duration = _videoController!.value.duration;

          // When video finishes playing, navigate directly to Farmer Login
          if (duration > Duration.zero && position >= duration) {
            _navigateToFarmerLogin();
          }
        }
      });
    } catch (e) {
      debugPrint("[SplashScreen] Video playback fallback: $e");
      // Fallback timer if video playback is not supported
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted && !_hasNavigated) {
          _navigateToFarmerLogin();
        }
      });
    }
  }

  void _navigateToFarmerLogin() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _videoController?.pause();
    Navigator.pushReplacementNamed(context, '/farmer_auth');
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fullscreen Video Player (BoxFit.cover fills screen completely)
          if (_isVideoInitialized && _videoController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          else
            const ColoredBox(color: Colors.black),

          // 2. Skip Button in Top Right (visible when video is playing)
          if (_isVideoInitialized)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _navigateToFarmerLogin,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "SKIP",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
