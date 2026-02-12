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
  bool _navigating = false;

  static const _items = <_EmotionItem>[
    _EmotionItem(
      iconAssetPath: 'assets/images/love.png',
      fillColor: Color(0xFFFFE8D2),
    ),
    _EmotionItem(
      iconAssetPath: 'assets/images/emotion_neutral.png',
      fillColor: Color(0xFFDDF6F3),
    ),
    _EmotionItem(
      iconAssetPath: 'assets/images/sad.png',
      fillColor: Color(0xFFDBF1F6),
    ),
    _EmotionItem(
      iconAssetPath: 'assets/images/emotion_proud.png',
      fillColor: Color(0xFFE1F4E5),
    ),
    _EmotionItem(
      iconAssetPath: 'assets/images/emotion_happy.png',
      fillColor: Color(0xFFFFF7D8),
    ),
  ];

  Future<void> _selectEmotion(int index) async {
    if (_navigating) return;
    setState(() {
      _selected = index;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 58),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox(
                        width: 26,
                        height: 26,
                        child: _BackArrow(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '오늘의 일기',
                      style: TextStyle(
                        fontFamily: 'Pretendard Variable',
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF273036),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 68, top: 4),
                child: Text(
                  '오늘의 봉사활동, 어떤 감정이었나요?',
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6D767D),
                  ),
                ),
              ),
              const SizedBox(height: 64),
              Expanded(
                child: Stack(
                  children: [
                    const Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _EmotionBubble(
                          item: _topItem,
                          size: 98,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 188,
                      left: 34,
                      child: GestureDetector(
                        onTap: () => _selectEmotion(1),
                        child: _EmotionBubble(item: _items[1], size: 100),
                      ),
                    ),
                    Positioned(
                      top: 188,
                      right: 34,
                      child: GestureDetector(
                        onTap: () => _selectEmotion(2),
                        child: _EmotionBubble(item: _items[2], size: 100),
                      ),
                    ),
                    Positioned(
                      top: 392,
                      left: 82,
                      child: GestureDetector(
                        onTap: () => _selectEmotion(3),
                        child: _EmotionBubble(item: _items[3], size: 100),
                      ),
                    ),
                    Positioned(
                      top: 392,
                      right: 82,
                      child: GestureDetector(
                        onTap: () => _selectEmotion(4),
                        child: _EmotionBubble(item: _items[4], size: 100),
                      ),
                    ),
                    const Positioned(
                      top: 182,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _CenterHintBubble(),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _selectEmotion(0),
                          child: const _EmotionBubble(item: _topItem, size: 98),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (darkened)
            Positioned.fill(
              child: Container(color: const Color(0xA3000000)),
            ),
          if (_selected != null)
            Positioned.fill(
              child: Center(
                child: _EmotionBubble(
                  item: _items[_selected!],
                  size: 150,
                  iconScale: 0.58,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

const _topItem = _EmotionItem(
  iconAssetPath: 'assets/images/love.png',
  fillColor: Color(0xFFFFE8D2),
);

class _BackArrow extends StatelessWidget {
  const _BackArrow();

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0xFF20282E), BlendMode.srcIn),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(-1.0, 1.0),
        child: const Image(
          image: AssetImage('assets/images/volunteer/b.png'),
          width: 20,
          height: 10,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _EmotionItem {
  const _EmotionItem({
    required this.iconAssetPath,
    required this.fillColor,
  });

  final String iconAssetPath;
  final Color fillColor;
}

class _EmotionBubble extends StatelessWidget {
  const _EmotionBubble({
    required this.item,
    required this.size,
    this.iconScale = 0.52,
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
          width: size * iconScale,
          height: size * iconScale,
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
      width: 150,
      height: 150,
      decoration: const BoxDecoration(
        color: Color(0xFFE6F0F4),
        shape: BoxShape.circle,
      ),
    );
  }
}
