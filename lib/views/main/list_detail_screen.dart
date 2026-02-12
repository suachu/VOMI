import 'package:flutter/material.dart';
import 'package:vomi/services/liked_volunteer_service.dart';
import 'package:vomi/views/main/list_models.dart';

class ListDetailScreen extends StatefulWidget {
  final ListItem item;

  const ListDetailScreen({super.key, required this.item});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  bool _isLiked = false;

  String get _likeId => '${widget.item.title}|${widget.item.subtitle}';

  @override
  void initState() {
    super.initState();
    _loadLikedState();
  }

  Future<void> _loadLikedState() async {
    final liked = await LikedVolunteerService.isLiked(_likeId);
    if (!mounted) return;
    setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike() async {
    final previous = _isLiked;
    setState(() => _isLiked = !_isLiked);
    try {
      await LikedVolunteerService.ensureLoaded();
      await LikedVolunteerService.toggle(
        LikedVolunteer(
          id: _likeId,
          title: widget.item.title,
          subtitle: widget.item.subtitle,
          thumbnailAsset: widget.item.thumbnailAsset,
        ),
      );
      if (!mounted) return;
      setState(() {
        _isLiked = LikedVolunteerService.isLikedSync(_likeId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLiked = previous);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상세'),
        actions: [
          IconButton(
            onPressed: _toggleLike,
            icon: Image.asset(
              _isLiked
                  ? 'assets/images/heart3.png'
                  : 'assets/images/volunteer/heart.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              widget.item.subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            const Text('상세 내용은 여기에서 채울 수 있어요.', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
