// lib/features/intro/splash_intro_page.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../home/home_page.dart';
import 'splash_intro_config.dart';

class SplashIntroPage extends StatefulWidget {
  const SplashIntroPage({super.key});

  @override
  State<SplashIntroPage> createState() => _SplashIntroPageState();
}

class _SplashIntroPageState extends State<SplashIntroPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AudioPlayer _logoPlayer = AudioPlayer();
  bool _navigated = false;

  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;

  late Animation<double> _centerOpacity;
  late Animation<double> _centerSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: splashTimelineDuration,
    );

    // Logo main: fade in + scale (0.0→0.40)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          splashLogoIntervalBegin,
          splashLogoIntervalEnd,
          curve: Curves.easeOut,
        ),
      ),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          splashLogoIntervalBegin,
          splashLogoIntervalEnd,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    // Logo center: fade in + slide up (0.45→0.70)
    _centerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          splashSwapIntervalBegin + 0.05,
          splashSwapIntervalEnd,
          curve: Curves.easeOut,
        ),
      ),
    );

    _centerSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          splashSwapIntervalBegin + 0.05,
          splashSwapIntervalEnd,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _logoPlayer.play(AssetSource('audio/intro_logo.mp3'), volume: 1.0);
    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_navigated) {
        Future.delayed(splashPostDelay, () {
          if (!mounted || _navigated) return;
          _navigated = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _logoPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: splashBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return SizedBox(
              width: 350,
              height: 350,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Image.asset(
                        'assets/images/bill_pit_logo_main.png',
                        width: splashMainWidth,
                        height: splashMainHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: _centerOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _centerSlide.value - 50),
                      child: Image.asset(
                        'assets/images/bill_pit_logo_center.png',
                        width: splashLogoSize,
                        height: splashLogoSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
