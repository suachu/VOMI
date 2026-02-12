import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vomi/core/theme/colors.dart';
import 'package:vomi/services/user_profile_local_service.dart';
import 'package:vomi/views/main/journal/journal_entry.dart';
import 'package:vomi/views/main/journal/journal_storage.dart';

class JournalWriteScreen extends StatefulWidget {
  const JournalWriteScreen({
    super.key,
    required this.selectedEmotionIndex,
    this.initialEntry,
  });

  final int selectedEmotionIndex;
  final JournalEntry? initialEntry;

  @override
  State<JournalWriteScreen> createState() => _JournalWriteScreenState();
}

class _JournalWriteScreenState extends State<JournalWriteScreen> {
  final UserProfileLocalService _profileService =
      const UserProfileLocalService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  late int _emotionIndex;
  bool _showScopePicker = false;
  String _scope = '전체공개';
  final List<XFile> _pickedImages = [];
  final List<String> _existingImagePaths = [];
  final List<String> _existingImageUrls = [];

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emotionIndex = widget.selectedEmotionIndex;
    final initial = widget.initialEntry;
    if (initial != null) {
      _titleController.text = initial.title;
      _locationController.text = initial.location;
      _contentController.text = initial.content;
      _scope = initial.scope;
      _emotionIndex = initial.emotionIndex;
      _existingImagePaths.addAll(initial.imagePaths);
      _existingImageUrls.addAll(initial.imageUrls);
    }
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
        const SnackBar(content: Text('사진 권한이 필요하거나, 사진 선택 중 오류가 발생했어요.')),
      );
    }
  }

  Future<void> _saveEntry() async {
    if (!_canSave) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final profile = await _profileService.ensure(user);
    final uid = user.uid;
    final isEdit = widget.initialEntry != null;
    final entryId = isEdit
        ? widget.initialEntry!.id
        : DateTime.now().microsecondsSinceEpoch.toString();
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
      emotionIndex: _emotionIndex,
      createdAt: isEdit ? widget.initialEntry!.createdAt : DateTime.now(),
      imagePaths: [..._existingImagePaths, ..._pickedImages.map((e) => e.path)],
      imageUrls: [..._existingImageUrls, ...uploadedImageUrls],
      authorUid: uid,
      authorName: profile.name.trim().isNotEmpty ? profile.name.trim() : '익명',
      authorPhotoUrl: user.photoURL ?? '',
      likeCount: widget.initialEntry?.likeCount ?? 0,
      commentCount: widget.initialEntry?.commentCount ?? 0,
    );
    if (isEdit) {
      await JournalStorage.updateEntry(uid, entry);
    } else {
      await JournalStorage.addEntry(uid, entry);
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const _JournalSavingScreen(),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(entry);
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

  Widget _buildScopeChip(String text, String iconAsset) {
    final selected = _scope == text;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _scope = text;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 32,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFA9D8EA) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  selected ? Colors.white : const Color(0xFF6E7880),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  iconAsset,
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 19.5 / 13,
                  letterSpacing: 0,
                  color: selected ? Colors.white : const Color(0xFF6E7880),
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              child: Container(width: 402, height: 106, color: Colors.white),
            ),
            Positioned(
              left: 35,
              top: 77,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: const Image(
                  image: AssetImage('assets/images/volunteer/b.png'),
                  width: 20,
                  height: 10,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 61,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showScopePicker = !_showScopePicker;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '나의 일지 · $_scope',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Pretendard Variable',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 42 / 17,
                          letterSpacing: 0,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(width: 5),
                      AnimatedRotation(
                        turns: _showScopePicker ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        child: const Image(
                          image: AssetImage('assets/images/tri.png'),
                          width: 12,
                          height: 12,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 138,
              child: Container(
                width: 354,
                height: 672,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 24 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(
                          fontFamily: 'Pretendard Variable',
                          fontSize: 25,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF646E75),
                          height: 24 / 25,
                          letterSpacing: 0,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: '제목',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            fontFamily: 'Pretendard Variable',
                            fontSize: 25,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF7A848B),
                            height: 24 / 25,
                            letterSpacing: 0,
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
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF6D767D),
                                height: 1.0,
                                letterSpacing: 0,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: '위치',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  fontFamily: 'Pretendard Variable',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF7E878E),
                                  height: 1.0,
                                  letterSpacing: 0,
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
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 8),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 24 / 15,
                            color: Color(0xFF5F676F),
                            letterSpacing: 0,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '이번 봉사활동을 통해 느낀 점을 기록해보세요!',
                            hintStyle: TextStyle(
                              fontFamily: 'Pretendard Variable',
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFB7BEC4),
                              height: 24 / 15,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: GestureDetector(
                          onTap: _canSave ? _saveEntry : null,
                          child: Container(
                            width: 306.5369873046875,
                            height: 51.9912109375,
                            decoration: BoxDecoration(
                              color: const Color(0xFFACD7E6),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Text(
                                '저장하기',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Pretendard Variable',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 24 / 16,
                                  letterSpacing: 0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_showScopePicker)
              Positioned(
                left: 61,
                width: 280,
                top: 95,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 4,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildScopeChip('비공개', 'assets/images/lock.png'),
                      _buildScopeChip('친구공개', 'assets/images/volunteer/twopeople.png'),
                      _buildScopeChip('전체공개', 'assets/images/uni.png'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JournalSavingScreen extends StatefulWidget {
  const _JournalSavingScreen();

  @override
  State<_JournalSavingScreen> createState() => _JournalSavingScreenState();
}

class _JournalSavingScreenState extends State<_JournalSavingScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF3FCFF),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFF3FCFF),
                        blurRadius: 2.88,
                        offset: Offset(0, 0),
                      ),
                      BoxShadow(
                        color: Color(0xFFF3FCFF),
                        blurRadius: 5.76,
                        offset: Offset(0, 0),
                      ),
                      BoxShadow(
                        color: Color(0xFFF3FCFF),
                        blurRadius: 20.16,
                        offset: Offset(0, 0),
                      ),
                      BoxShadow(
                        color: Color(0xFFF3FCFF),
                        blurRadius: 40.32,
                        offset: Offset(0, 0),
                      ),
                      BoxShadow(
                        color: Color(0xFFF3FCFF),
                        blurRadius: 69.12,
                        offset: Offset(0, 0),
                      ),
                      BoxShadow(
                        color: Color(0xFFF3FCFF),
                        blurRadius: 120.96,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: const [
                      Positioned(
                        left: 69.98,
                        top: 79.9,
                        child: Image(
                          image: AssetImage('assets/images/heart4.png'),
                          width: 100.00032043457031,
                          height: 85.0792007446289,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 46),
                const Text(
                  '저장 중...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF757575),
                    height: 24 / 30,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '봉사는 즐거운 일이죠!\n앞으로도 Vomi와 함께해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF757575),
                    height: 21 / 14,
                    letterSpacing: 0,
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
