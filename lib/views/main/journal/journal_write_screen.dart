import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vomi/core/theme/colors.dart';
import 'package:vomi/views/main/journal/journal_entry.dart';
import 'package:vomi/views/main/journal/journal_storage.dart';

class JournalWriteScreen extends StatefulWidget {
  const JournalWriteScreen({super.key, required this.selectedEmotionIndex});

  final int selectedEmotionIndex;

  @override
  State<JournalWriteScreen> createState() => _JournalWriteScreenState();
}

class _JournalWriteScreenState extends State<JournalWriteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _showScopePicker = false;
  String _scope = '전체공개';
  final List<XFile> _pickedImages = [];

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onInputChanged);
    _contentController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onInputChanged);
    _contentController.removeListener(_onInputChanged);
    _titleController.dispose();
    _locationController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {});
  }

  Future<void> _pickImages() async {
    try {
      final files = await _imagePicker.pickMultiImage(
        imageQuality: 90,
        maxWidth: 1800,
      );
      if (!mounted || files.isEmpty) return;
      setState(() {
        _pickedImages.addAll(files);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사진 권한이 필요하거나, 사진 선택 중 오류가 발생했어요.'),
        ),
      );
    }
  }

  Future<void> _saveEntry() async {
    if (!_canSave) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final entryId = DateTime.now().microsecondsSinceEpoch.toString();
    final uploadedImageUrls = await _uploadImages(
      uid: uid,
      entryId: entryId,
      files: _pickedImages,
    );

    final entry = JournalEntry(
      id: entryId,
      title: _titleController.text.trim(),
      location: _locationController.text.trim(),
      content: _contentController.text.trim(),
      scope: _scope,
      emotionIndex: widget.selectedEmotionIndex,
      createdAt: DateTime.now(),
      imagePaths: _pickedImages.map((e) => e.path).toList(),
      imageUrls: uploadedImageUrls,
      authorUid: uid,
      authorName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : '익명',
      authorPhotoUrl: user.photoURL ?? '',
    );
    await JournalStorage.addEntry(uid, entry);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<List<String>> _uploadImages({
    required String uid,
    required String entryId,
    required List<XFile> files,
  }) async {
    if (files.isEmpty) return const [];
    final storage = FirebaseStorage.instance;
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final file = File(files[i].path);
      final ref = storage.ref().child(
        'users/$uid/journal_images/${entryId}_$i.jpg',
      );
      await ref.putFile(file);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Widget _buildScopeChip(String text, IconData icon) {
    final selected = _scope == text;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _scope = text;
            _showScopePicker = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFA9D8EA) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF6E7880)),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6E7880),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 24 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: _showScopePicker ? 120 : 72,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        top: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: const SizedBox(
                            width: 28,
                            height: 28,
                            child: _BackArrow(),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 18,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showScopePicker = !_showScopePicker;
                              });
                            },
                            child: Text(
                              '나의 일기 · $_scope ${_showScopePicker ? '▲' : '▼'}',
                              style: const TextStyle(
                                fontFamily: 'Pretendard Variable',
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F262C),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_showScopePicker)
                        Positioned(
                          left: 24,
                          right: 24,
                          top: 58,
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x26000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _buildScopeChip('비공개', Icons.lock_outline_rounded),
                                _buildScopeChip(
                                  '친구공개',
                                  Icons.group_outlined,
                                ),
                                _buildScopeChip(
                                  '전체공개',
                                  Icons.public_rounded,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 700),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(
                          fontFamily: 'Pretendard Variable',
                          fontSize: 46,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF646E75),
                          height: 1.05,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: '제목',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            fontFamily: 'Pretendard Variable',
                            fontSize: 46,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7A848B),
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE8ECEF)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 22,
                            color: Color(0xFF9ED4EA),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _locationController,
                              style: const TextStyle(
                                fontFamily: 'Pretendard Variable',
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF6D767D),
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: '위치',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  fontFamily: 'Pretendard Variable',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF7E878E),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F6F9),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 18,
                                    color: Color(0xFF6E7880),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '사진 추가',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard Variable',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6E7880),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.text_fields_rounded,
                            size: 18,
                            color: Color(0xFF8B959D),
                          ),
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.format_align_left_rounded,
                            size: 18,
                            color: Color(0xFF8B959D),
                          ),
                        ],
                      ),
                      if (_pickedImages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 84,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pickedImages.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(_pickedImages[index].path),
                                      width: 84,
                                      height: 84,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _pickedImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: Color(0xAA000000),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 420,
                        child: TextField(
                          controller: _contentController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: const TextStyle(
                            fontFamily: 'Pretendard Variable',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            color: Color(0xFF5F676F),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '이번 봉사활동을 통해 느낀 점을 기록해보세요!',
                            hintStyle: TextStyle(
                              fontFamily: 'Pretendard Variable',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFB7BEC4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _canSave ? _saveEntry : null,
                        child: Container(
                          width: double.infinity,
                          height: 70,
                          decoration: BoxDecoration(
                            color: _canSave
                                ? const Color(0xFFA9D3E4)
                                : const Color(0xFFE6EDF2),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(
                            child: Text(
                              '저장하기',
                              style: TextStyle(
                                fontFamily: 'Pretendard Variable',
                                fontSize: 40,
                                fontWeight: FontWeight.w600,
                                color: _canSave
                                    ? Colors.white
                                    : const Color(0xFFB4C0C7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
