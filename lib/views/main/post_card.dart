import 'package:flutter/material.dart';
import 'package:vomi/core/theme/colors.dart';
import 'package:vomi/core/theme/text_styles.dart';
import 'package:vomi/views/main/facility_models.dart';

/// ---------- Post Blocks ----------

sealed class PostBlock {}

class TextBlock extends PostBlock {
  final String text;
  TextBlock(this.text);
}

class ImageBlock extends PostBlock {
  final ImageProvider image;
  ImageBlock(this.image);
}

/// ---------- Post Model ----------

class Post {
  final String id;
  final String userName;
  final ImageProvider profileImage;

  final String title;
  final String date;
  final String location;

  final Facility facility;
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final int emotionIndex;

  final ImageProvider emojiImage;
  final List<PostBlock> blocks;

  const Post({
    required this.id,
    required this.userName,
    required this.profileImage,
    required this.title,
    required this.date,
    required this.location,
    required this.facility,
    required this.likeCount,
    required this.commentCount,
    required this.saveCount,
    required this.emotionIndex,
    required this.emojiImage,
    required this.blocks,
  });
}

/// ---------- Post Card ----------

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  static const double _imgGap = 4;

  @override
  Widget build(BuildContext context) {
    final lastTextIndex = post.blocks.lastIndexWhere((b) => b is TextBlock);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 354, maxHeight: 632),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(post),
              const SizedBox(height: 16),
              _TitleRow(post),
              const SizedBox(height: 5),
              _LocationRow(post.location),
              const SizedBox(height: 16.5),

              // ---------- Dynamic Content ----------
              ..._buildContentWidgets(post.blocks, lastTextIndex),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContentWidgets(List<PostBlock> blocks, int lastTextIndex) {
    final widgets = <Widget>[];
    final imageBuffer = <ImageProvider>[];

    void flushImages() {
      if (imageBuffer.isEmpty) return;

      for (int i = 0; i < imageBuffer.length; i += 2) {
        final left = imageBuffer[i];
        final right = (i + 1 < imageBuffer.length) ? imageBuffer[i + 1] : null;

        // ✅ If only one image in this row -> center it
        if (right == null) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(child: _FixedImage(image: left)),
            ),
          );
        } else {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FixedImage(image: left),
                  const SizedBox(width: _imgGap),
                  _FixedImage(image: right),
                ],
              ),
            ),
          );
        }
      }

      imageBuffer.clear();
    }

    for (int index = 0; index < blocks.length; index++) {
      final block = blocks[index];

      if (block is ImageBlock) {
        imageBuffer.add(block.image);
        continue;
      }

      if (block is TextBlock) {
        flushImages();

        final isLastText = index == lastTextIndex;

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              block.text,
              style: AppTextStyles.body,
              maxLines: isLastText ? 5 : null,
              overflow: isLastText
                  ? TextOverflow.ellipsis
                  : TextOverflow.visible,
            ),
          ),
        );
        continue;
      }

      flushImages();
    }

    flushImages();
    return widgets;
  }
}

/// ---------- Fixed Image Widget ----------

class _FixedImage extends StatelessWidget {
  final ImageProvider image;
  const _FixedImage({required this.image});

  static const double _imgW = 156;
  static const double _imgH = 208;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: _imgW,
        height: _imgH,
        child: Image(image: image, fit: BoxFit.cover),
      ),
    );
  }
}

/// ---------- Header ----------

class _Header extends StatelessWidget {
  final Post post;
  const _Header(this.post);

  @override
  Widget build(BuildContext context) {
    final image = post.profileImage;
    final isDefaultVAsset =
        image is AssetImage && image.assetName.endsWith('/V.png');

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.transparent,
          backgroundImage: isDefaultVAsset ? null : image,
          child: isDefaultVAsset
              ? ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFACD7E6),
                    BlendMode.srcIn,
                  ),
                  child: Image(
                    image: image,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(post.userName, style: AppTextStyles.username),
      ],
    );
  }
}

/// ---------- Title + Emoji ----------

class _TitleRow extends StatelessWidget {
  final Post post;
  const _TitleRow(this.post);

  static const _emotionImagePaths = [
    'assets/images/love.png',
    'assets/images/emotion_neutral.png',
    'assets/images/sad.png',
    'assets/images/emotion_proud.png',
    'assets/images/emotion_happy.png',
  ];

  static const _emotionFillColors = [
    Color(0xFFFFE7D1),
    Color(0xFFE5FFFA),
    Color(0xFFEFFEFF),
    Color(0xFFEEFFF0),
    Color(0xFFFFFAE7),
  ];

  static const _iconSizes = <(double width, double height)>[
    (42, 35.73),
    (42, 42),
    (42, 42),
    (42, 42.36),
    (42, 42),
  ];

  @override
  Widget build(BuildContext context) {
    final safe = post.emotionIndex.clamp(0, 4);
    final iconSize = _iconSizes[safe];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.title, style: AppTextStyles.title),
              const SizedBox(height: 2),
              Text(post.date, style: AppTextStyles.date),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _emotionFillColors[safe],
            ),
            alignment: Alignment.center,
            child: Image.asset(
              _emotionImagePaths[safe],
              width: iconSize.$1 * (18 / 42),
              height: iconSize.$2 * (18 / 42),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

/// ---------- Location ----------

class _LocationRow extends StatelessWidget {
  final String location;
  const _LocationRow(this.location);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.location_on_rounded,
          size: 16,
          color: AppColors.tertiary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            location,
            style: AppTextStyles.location,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
