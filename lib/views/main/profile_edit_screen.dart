import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vomi/core/theme/colors.dart';
import 'package:vomi/services/liked_volunteer_service.dart';
import 'package:vomi/services/user_profile_local_service.dart';
import 'package:vomi/views/main/list_detail_screen.dart';
import 'package:vomi/views/main/list_models.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, required this.user});

  final User user;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final UserProfileLocalService _profileService =
      const UserProfileLocalService();
  late final TextEditingController _nameController;
  late final TextEditingController _idController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  final ImagePicker _imagePicker = ImagePicker();
  String _email = '이메일 없음';
  String _photoPath = '';

  Future<void> _loadProfile() async {
    final profile = await _profileService.ensure(widget.user);
    if (!mounted) return;
    _nameController.text = profile.name;
    _idController.text = profile.appId;
    _phoneController.text = profile.phone;
    _addressController.text = profile.address;
    _photoPath = profile.photoPath;
    _email = (widget.user.email?.trim().isNotEmpty ?? false)
        ? widget.user.email!.trim()
        : '이메일 없음';
    setState(() {});
  }

  Future<void> _saveName(String value) async =>
      _profileService.saveName(widget.user, value);
  Future<void> _saveId(String value) async =>
      _profileService.saveAppId(widget.user, value);
  Future<void> _savePhone(String value) async =>
      _profileService.savePhone(widget.user, value);
  Future<void> _saveAddress(String value) async =>
      _profileService.saveAddress(widget.user, value);

  Future<void> _pickProfilePhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1800,
      );
      if (!mounted || picked == null) return;
      await _profileService.savePhotoPath(widget.user, picked.path);
      setState(() {
        _photoPath = picked.path;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진을 불러오지 못했어요. 권한을 확인해주세요.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _idController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const designWidth = 402.0;
    const designHeight = 874.0;
    final sx = screenSize.width / designWidth;
    final sy = screenSize.height / designHeight;
    final titleTop = 70 * sy;
    final titleCenterY = titleTop + ((18 * sx) / 2);
    final backButtonTop = titleCenterY - (12 * sy);
    final localPhotoAvailable =
        _photoPath.isNotEmpty && File(_photoPath).existsSync();
    final ImageProvider? profileImage = localPhotoAvailable
        ? FileImage(File(_photoPath))
        : (widget.user.photoURL != null
              ? NetworkImage(widget.user.photoURL!)
              : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              left: 24 * sx,
              top: 105 * sy,
              child: Container(
                width: 354 * sx,
                height: 468 * sy,
                padding: EdgeInsets.fromLTRB(
                  20 * sx,
                  180 * sy,
                  20 * sx,
                  20 * sy,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(20 * sx),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 22 * sy),
                    _EditableAddressRow(
                      label: '이름',
                      controller: _nameController,
                      scale: sx,
                      hintText: '이름 입력',
                      onChanged: _saveName,
                    ),
                    SizedBox(height: 30 * sy),
                    _EditableAddressRow(
                      label: '아이디',
                      controller: _idController,
                      scale: sx,
                      hintText: '아이디 입력',
                      onChanged: _saveId,
                    ),
                    SizedBox(height: 30 * sy),
                    _EditableAddressRow(
                      label: '전화번호',
                      controller: _phoneController,
                      scale: sx,
                      hintText: '전화번호 입력',
                      onChanged: _savePhone,
                    ),
                    SizedBox(height: 30 * sy),
                    _ProfileInfoRow(label: '이메일주소', value: _email, scale: sx),
                    SizedBox(height: 30 * sy),
                    _EditableAddressRow(
                      label: '집주소',
                      controller: _addressController,
                      scale: sx,
                      onChanged: _saveAddress,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 148 * sx,
              top: 137 * sy,
              child: CircleAvatar(
                radius: 50 * sx,
                backgroundColor: const Color(0xFFE8E8E8),
                backgroundImage: profileImage,
                child: profileImage == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 48 * sx,
                        color: const Color(0xFF8D8D8D),
                      )
                    : null,
              ),
            ),
            Positioned(
              left: 152 * sx,
              top: 253 * sy,
              child: GestureDetector(
                onTap: _pickProfilePhoto,
                child: Text(
                  '프로필 사진 수정',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 14 * sx,
                    fontWeight: FontWeight.w500,
                    height: 20 / 14,
                    letterSpacing: 0,
                    color: const Color(0xFF00A5DF),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24 * sx,
              top: backButtonTop,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 31.63 * sx,
                  height: 17 * sy,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 11.63 * sx,
                        top: 7 * sy,
                        child: Image(
                          image: const AssetImage(
                            'assets/images/volunteer/b.png',
                          ),
                          width: 20 * sx,
                          height: 10 * sy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: titleTop,
              child: Center(
                child: Text(
                  '프로필 편집',
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 18 * sx,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                    letterSpacing: 0,
                    color: const Color(0xFF000000),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TitleOnlyScreen extends StatelessWidget {
  const TitleOnlyScreen({super.key, required this.title});

  final String title;

  bool get _isLikedVolunteerPage => title == '찜한 봉사';

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const designWidth = 402.0;
    const designHeight = 874.0;
    final sx = screenSize.width / designWidth;
    final sy = screenSize.height / designHeight;
    final titleTop = 70 * sy;
    final titleCenterY = titleTop + ((18 * sx) / 2);
    final backButtonTop = titleCenterY - (12 * sy);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<void>(
        future: LikedVolunteerService.ensureLoaded(),
        builder: (context, snapshot) {
          return Stack(
            children: [
              if (_isLikedVolunteerPage)
                Positioned.fill(
                  top: 120 * sy,
                  child: ValueListenableBuilder<List<LikedVolunteer>>(
                    valueListenable: LikedVolunteerService.likedItems,
                    builder: (context, items, child) {
                      if (items.isEmpty) {
                        return const Center(
                          child: Text(
                            '아직 찜한 봉사가 없어요.',
                            style: TextStyle(
                              fontFamily: 'Pretendard Variable',
                              fontSize: 14,
                              color: Color(0xFF6A7282),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          24 * sx,
                          8 * sy,
                          24 * sx,
                          24 * sy,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ListDetailScreen(
                                      item: ListItem(
                                        title: item.title,
                                        subtitle: item.subtitle,
                                        distanceKm: 0,
                                        popularity: 0,
                                        createdAt: DateTime.now(),
                                        thumbnailAsset: item.thumbnailAsset,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Image.asset(
                                        item.thumbnailAsset,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.pets),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontFamily: 'Pretendard Variable',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.subtitle,
                                            style: const TextStyle(
                                              fontFamily: 'Pretendard Variable',
                                              fontSize: 13,
                                              color: Color(0xFF6A7282),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              Positioned(
                left: 24 * sx,
                top: backButtonTop,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 31.63 * sx,
                    height: 17 * sy,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 11.63 * sx,
                          top: 7 * sy,
                          child: Image(
                            image: const AssetImage(
                              'assets/images/volunteer/b.png',
                            ),
                            width: 20 * sx,
                            height: 10 * sy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: titleTop,
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 18 * sx,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                      letterSpacing: 0,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.label,
    required this.value,
    required this.scale,
  });

  final String label;
  final String value;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 108 * scale,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 14 * scale,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF5F666D),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 14 * scale,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF373B40),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditableAddressRow extends StatelessWidget {
  const _EditableAddressRow({
    required this.label,
    required this.controller,
    required this.scale,
    required this.onChanged,
    this.hintText = '집주소 추가',
  });

  final String label;
  final TextEditingController controller;
  final double scale;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 108 * scale,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 14 * scale,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF5F666D),
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: 1,
            textAlignVertical: TextAlignVertical.center,
            onChanged: onChanged,
            style: TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 14 * scale,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF2F3338),
            ),
            decoration: InputDecoration.collapsed(
              hintText: hintText,
              hintStyle: TextStyle(
                fontFamily: 'Pretendard Variable',
                fontSize: 14 * scale,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFA9ACB1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
