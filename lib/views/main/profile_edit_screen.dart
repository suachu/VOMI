import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vomi/core/theme/colors.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, required this.user});

  final User user;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  static const _addressKey = 'profile_edit_address';
  late final TextEditingController _addressController;

  Future<void> _loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_addressKey) ?? '';
    if (!mounted) return;
    _addressController.text = saved;
  }

  Future<void> _saveAddressValue(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressKey, value.trim());
  }

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _loadAddress();
  }

  @override
  void dispose() {
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
    final name = (widget.user.displayName?.trim().isNotEmpty ?? false)
        ? widget.user.displayName!.trim()
        : '이름 없음';
    final id = (widget.user.email?.split('@').first.trim().isNotEmpty ?? false)
        ? widget.user.email!.split('@').first.trim()
        : '아이디 없음';
    final email = (widget.user.email?.trim().isNotEmpty ?? false)
        ? widget.user.email!.trim()
        : '이메일 없음';
    final profileImage = widget.user.photoURL != null
        ? NetworkImage(widget.user.photoURL!)
        : null;

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
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 15 * sy),
                      _ProfileInfoRow(label: '이름', value: name, scale: sx),
                      SizedBox(height: 38 * sy),
                      _ProfileInfoRow(label: '아이디', value: id, scale: sx),
                      SizedBox(height: 38 * sy),
                      _ProfileInfoRow(
                        label: '전화번호',
                        value: '010-1234-5678',
                        scale: sx,
                      ),
                      SizedBox(height: 38 * sy),
                      _ProfileInfoRow(label: '이메일주소', value: email, scale: sx),
                      SizedBox(height: 38 * sy),
                      _EditableAddressRow(
                        label: '집주소',
                        controller: _addressController,
                        scale: sx,
                        onChanged: _saveAddressValue,
                      ),
                    ],
                  ),
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
                          image: const AssetImage('assets/images/volunteer/b.png'),
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
      body: Stack(
        children: [
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
                        image: const AssetImage('assets/images/volunteer/b.png'),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
  });

  final String label;
  final TextEditingController controller;
  final double scale;
  final ValueChanged<String> onChanged;

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
              hintText: '집주소 추가',
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
