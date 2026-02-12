import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vomi/core/theme/colors.dart';
import 'package:vomi/views/main/journal/journal_write_screen.dart';

class EmotionSelectScreen extends StatefulWidget {
  const EmotionSelectScreen({super.key});

  @override
  State<EmotionSelectScreen> createState() => _EmotionSelectScreenState();
}

class _EmotionSelectScreenState extends State<EmotionSelectScreen> {
  int? _selected;
  int? _activeEmotion;
  bool _navigating = false;

  static const _items = <_EmotionItem>[
    _EmotionItem(
      iconAssetPath: 'assets/images/love.png',
      fillColor: Color(0xFFFFE7D1),
      iconWidth: 42,
      iconHeight: 35.73,
    ),
    _EmotionItem(
      iconAssetPath: 'assets/images/emotion_neutral.png',
      fillColor: Color(0xFFE5FFFA),
      iconWidth: 42,
      iconHeight: 42,
    ),
    _EmotionItem(
      iconAssetPath: 'assets/images/sad.png',
      fillColor: Color(0xFFEFFEFF),
      iconWidth: 42,
      iconHeight: 42,
    ),
    _EmotionItem(
      iconAssetPath: 'assets/images/emotion_proud.png',
      fillColor: Color(0xFFEEFFF0),
      iconWidth: 42,
      iconHeight: 42.36,
    ),
    _EmotionItem(
      iconAssetPath: 'assets/images/emotion_happy.png',
      fillColor: Color(0xFFFFFAE7),
      iconWidth: 42,
      iconHeight: 42,
    ),
  ];

  Future<void> _selectEmotion(int index) async {
    if (_navigating) return;
    setState(() {
      _selected = index;
      _activeEmotion = null;
      _navigating = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => JournalWriteScreen(selectedEmotionIndex: index),
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _selected = null;
      _navigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkened = _selected != null;
    const frameW = 402.0;
    const frameH = 874.0;
    const centerSize = 120.0;
    const bubbleSize = 80.0;
    const centerX = frameW / 2;
    const centerY = 430.0;
    const radius = 155.0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SizedBox(
          width: frameW,
          height: frameH,
          child: Stack(
            children: [
              Positioned(
                left: 35,
                top: 93,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(
                    width: 20,
                    height: 10,
                    child: _BackArrow(),
                  ),
                ),
              ),
              const Positioned(
                left: 62,
                top: 81,
                child: Text(
                  '오늘의 일기',
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 42 / 28,
                    letterSpacing: 0,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ),
              const Positioned(
                left: 63,
                top: 123,
                child: Text(
                  '오늘의 봉사활동, 어떤 감정이었나요?',
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 24 / 16,
                    letterSpacing: 0,
                    color: Color(0xFF636E72),
                  ),
                ),
              ),
              Positioned(
                left: centerX - centerSize / 2,
                top: centerY - centerSize / 2,
                child: const _CenterHintBubble(),
              ),
              for (var i = 0; i < _items.length; i++)
                Positioned(
                  left: centerX +
                      radius * math.cos(-math.pi / 2 + i * (2 * math.pi / 5)) -
                      bubbleSize / 2,
                  top: centerY +
                      radius * math.sin(-math.pi / 2 + i * (2 * math.pi / 5)) -
                      bubbleSize / 2,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _activeEmotion = i),
                    onExit: (_) => setState(() => _activeEmotion = null),
                    child: GestureDetector(
                      onTap: () => _selectEmotion(i),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOutBack,
                        scale: _activeEmotion == i ? 1.12 : 1.0,
                        child: _EmotionBubble(item: _items[i], size: bubbleSize),
                      ),
                    ),
                  ),
                ),
              if (darkened)
                Positioned.fill(
                  child: Container(color: const Color(0xA3000000)),
                ),
              if (_selected != null)
                Positioned(
                  left: centerX - centerSize / 2,
                  top: centerY - centerSize / 2,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) {
                      return Transform.scale(
                        scale: 0.7 + (0.3 * t),
                        child: Opacity(opacity: t, child: child),
                      );
                    },
                    child: _EmotionBubble(
                      item: _items[_selected!],
                      size: centerSize,
                      iconScale: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackArrow extends StatelessWidget {
  const _BackArrow();

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0xFF20282E), BlendMode.srcIn),
      child: const Image(
        image: AssetImage('assets/images/volunteer/b.png'),
        width: 20,
        height: 10,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _EmotionItem {
  const _EmotionItem({
    required this.iconAssetPath,
    required this.fillColor,
    required this.iconWidth,
    required this.iconHeight,
  });

  final String iconAssetPath;
  final Color fillColor;
  final double iconWidth;
  final double iconHeight;
}

class _EmotionBubble extends StatelessWidget {
  const _EmotionBubble({
    required this.item,
    required this.size,
    this.iconScale = 1.0,
  });

  final _EmotionItem item;
  final double size;
  final double iconScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: item.fillColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Image.asset(
          item.iconAssetPath,
          width: item.iconWidth * iconScale,
          height: item.iconHeight * iconScale,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _CenterHintBubble extends StatelessWidget {
  const _CenterHintBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        color: Color(0xFFF3FCFF),
        shape: BoxShape.circle,
      ),
    );
  }
}
