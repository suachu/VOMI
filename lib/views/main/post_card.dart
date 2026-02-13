import 'package:flutter/material.dart';
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
  final String scope;
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
    required this.scope,
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
  final bool isDetail;

  const PostCard({super.key, required this.post, this.isDetail = false});

  static const double _imgGap = 4;
  static const double _imgAspect = 156 / 208;

  @override
  Widget build(BuildContext context) {
    final lastTextIndex = post.blocks.lastIndexWhere((b) => b is TextBlock);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 354),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 8.02,
                offset: Offset(0, 4.01),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(post),
              const SizedBox(height: 16),
              _TitleRow(post),
              const SizedBox(height: 0),
              _DateScopeRow(post),
              const SizedBox(height: 0),
              _LocationRow(post.location),
              const SizedBox(height: 16),

              // ---------- Dynamic Content ----------
              ..._buildContentWidgets(post.blocks, lastTextIndex, isDetail),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContentWidgets(
    List<PostBlock> blocks,
    int lastTextIndex,
    bool isDetail,
  ) {
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
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: _imgAspect,
                      child: _FixedImage(image: left),
                    ),
                  ),
                  const SizedBox(width: _imgGap),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: _imgAspect,
                      child: _FixedImage(image: right),
                    ),
                  ),
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
              style: const TextStyle(
                fontFamily: 'Pretendard Variable',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 24.05 / 15,
                color: Color(0xFF2C343A),
                letterSpacing: 0,
              ),
              maxLines: (!isDetail && isLastText) ? 5 : null,
              overflow: isLastText
                  ? ((!isDetail && isLastText)
                        ? TextOverflow.ellipsis
                        : TextOverflow.visible)
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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // borderRadius: BorderRadius.circular(12),
      child: SizedBox.expand(child: Image(image: image, fit: BoxFit.cover)),
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
          radius: 15,
          backgroundColor: const Color(0xFFE8E8E8),
          backgroundImage: isDefaultVAsset ? null : image,
          child: isDefaultVAsset
              ? ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFACD7E6),
                    BlendMode.srcIn,
                  ),
                  child: Image(
                    image: image,
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            post.userName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 14.03,
              fontWeight: FontWeight.w600,
              height: 1.0,
              letterSpacing: 0,
              color: Color(0xFF1F272D),
            ),
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    final safe = post.emotionIndex.clamp(0, 4);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            post.title,
            style: const TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 20.04,
              fontWeight: FontWeight.w600,
              height: 21.04 / 20.04,
              letterSpacing: 0,
              color: Color(0xFF2B3137),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _emotionFillColors[safe],
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            _emotionImagePaths[safe],
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

class _DateScopeRow extends StatelessWidget {
  const _DateScopeRow(this.post);

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Text(
        '${post.date} · ${post.scope}',
        style: const TextStyle(
          fontFamily: 'Pretendard Variable',
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: Color(0xFFB1B3B9),
        ),
      ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Image(
          image: AssetImage('assets/images/location.png'),
          width: 14,
          height: 14,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            location,
            style: const TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7D878F),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
