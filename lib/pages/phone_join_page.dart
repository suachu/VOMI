import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/back_icon_button.dart';
import '../widgets/home_indicator.dart';
import '../widgets/rounded_action_button.dart';
import '../widgets/screen_frame.dart';
import 'main_shell.dart';

/// 3) 개인정보 입력 페이지
class PhoneJoinPage extends StatefulWidget {
  const PhoneJoinPage({super.key});

  @override
  State<PhoneJoinPage> createState() => _PhoneJoinPageState();
}

class _PhoneJoinPageState extends State<PhoneJoinPage> {
  final nameCtrl = TextEditingController();
  final rrnFrontCtrl = TextEditingController();
  final rrnBackFirstCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  bool carrierOpen = false;
  String carrierValue = 'SKT';

  String? rrnError;
  String? phoneError;

  @override
  void dispose() {
    nameCtrl.dispose();
    rrnFrontCtrl.dispose();
    rrnBackFirstCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  TextStyle get inputStyle => const TextStyle(
        color: Colors.black,
        fontSize: 21,
        fontWeight: FontWeight.w500,
      );

  bool _isDigitsOnly(String s) => RegExp(r'^\d+$').hasMatch(s);

  void _validateDigitsLive() {
    final f = rrnFrontCtrl.text;
    final b = rrnBackFirstCtrl.text;
    String? rrnMsg;
    if (f.isNotEmpty && !_isDigitsOnly(f)) {
      rrnMsg = '주민번호 앞자리는 숫자만 입력할 수 있어요.';
    }
    if (b.isNotEmpty && !_isDigitsOnly(b)) {
      rrnMsg = '주민번호 뒷자리는 숫자만 입력할 수 있어요.';
    }

    final p = phoneCtrl.text;
    String? phoneMsg;
    if (p.isNotEmpty && !_isDigitsOnly(p)) {
      phoneMsg = '휴대폰 번호는 숫자만 입력할 수 있어요.';
    }

    setState(() {
      rrnError = rrnMsg;
      phoneError = phoneMsg;
    });
  }

  void _goMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _toggleCarrier() => setState(() => carrierOpen = !carrierOpen);

  void _selectCarrier(String v) {
    setState(() {
      carrierValue = v;
      carrierOpen = false;
    });
  }

  Widget _dividerLine() {
    return Opacity(
      opacity: 0.80,
      child: Container(
        width: double.infinity,
        decoration: const ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 0.50,
              strokeAlign: BorderSide.strokeAlignCenter,
              color: Color(0xFFACD7E6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _carrierRow(String label, {required bool enabled}) {
    return InkWell(
      onTap: enabled ? () => _selectCarrier(label) : null,
      child: SizedBox(
        width: double.infinity,
        height: 25,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              color:
                  enabled ? const Color(0xFF141510) : const Color(0xFF636E72),
              fontSize: 19,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (carrierOpen) setState(() => carrierOpen = false);
        },
        child: ScreenFrame(
          clipBehavior: Clip.none,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 뒤로가기
              Positioned(
                left: 23.70,
                top: 86,
                child: BackIconButton(onTap: () => Navigator.pop(context)),
              ),

              // 제목
              const Positioned(
                left: 25.18,
                top: 141,
                child: Text(
                  '이름을',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    height: 1.44,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const Positioned(
                left: 25,
                top: 177,
                child: Text(
                  '입력해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    height: 1.44,
                    letterSpacing: -1,
                  ),
                ),
              ),

              // 이름 박스
              Positioned(
                left: 29,
                top: 253,
                child: Container(
                  width: 344,
                  height: 90,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1.50,
                        color: Color(0xFF00A4DE),
                      ),
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 51,
                top: 271,
                child: Text(
                  '이름',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF636E72),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Positioned(
                left: 51,
                top: 289,
                child: SizedBox(
                  width: 300,
                  child: TextField(
                    controller: nameCtrl,
                    style: inputStyle,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: '이름 입력',
                      hintStyle: TextStyle(
                        color: Color(0xFFB1B3B9),
                        fontSize: 21,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // 통신사 상단 박스
              Positioned(
                left: 29,
                top: 361,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleCarrier,
                  child: Container(
                    width: 344,
                    height: 90,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1.50,
                          color: Color(0xFF00A4DE),
                        ),
                        borderRadius: carrierOpen
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(17),
                                topRight: Radius.circular(17),
                              )
                            : BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 51,
                top: 379,
                child: Text(
                  '통신사',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF636E72),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Positioned(
                left: 51,
                top: 397,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleCarrier,
                  child: Text(
                    carrierValue,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 21,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // 주민등록번호 박스
              Positioned(
                left: 29,
                top: 469,
                child: Container(
                  width: 344,
                  height: 90,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1.50,
                        color: Color(0xFF00A4DE),
                      ),
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 51,
                top: 487,
                child: Text(
                  '주민등록번호',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF636E72),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Positioned(
                left: 51,
                top: 505,
                child: SizedBox(
                  width: 120,
                  child: TextField(
                    controller: rrnFrontCtrl,
                    style: inputStyle,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _validateDigitsLive(),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      isDense: true,
                      hintText: '앞 6자리',
                      hintStyle: TextStyle(
                        color: Color(0xFFB1B3B9),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 196,
                top: 508,
                child: Text(
                  '-',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 23,
                    fontWeight: FontWeight.w500,
                    height: 1.57,
                  ),
                ),
              ),
              Positioned(
                left: 216.69,
                top: 505,
                child: SizedBox(
                  width: 30,
                  child: TextField(
                    controller: rrnBackFirstCtrl,
                    style: inputStyle,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _validateDigitsLive(),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      isDense: true,
                      hintText: '1',
                      hintStyle: TextStyle(
                        color: Color(0xFFB1B3B9),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(left: 241, top: 496, child: _Dot45()),
              const Positioned(left: 260, top: 496, child: _Dot45()),
              const Positioned(left: 279, top: 496, child: _Dot45()),
              const Positioned(left: 298, top: 496, child: _Dot45()),
              const Positioned(left: 317, top: 496, child: _Dot45()),
              const Positioned(left: 336, top: 496, child: _Dot45()),

              // 휴대폰번호 박스
              Positioned(
                left: 29,
                top: 576,
                child: Container(
                  width: 344,
                  height: 90,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1.50,
                        color: Color(0xFF00A4DE),
                      ),
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 51,
                top: 594,
                child: Text(
                  '휴대폰번호',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF636E72),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Positioned(
                left: 51,
                top: 612,
                child: SizedBox(
                  width: 300,
                  child: TextField(
                    controller: phoneCtrl,
                    style: inputStyle,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _validateDigitsLive(),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: '01012345678',
                      hintStyle: TextStyle(
                        color: Color(0xFFB1B3B9),
                        fontSize: 21,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // 에러 안내
              Positioned(
                left: 29,
                top: 674,
                child: SizedBox(
                  width: 344,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (rrnError != null)
                        Text(
                          rrnError!,
                          style: const TextStyle(
                            color: Color(0xFFE74C3C),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (phoneError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            phoneError!,
                            style: const TextStyle(
                              color: Color(0xFFE74C3C),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 확인 버튼
              Positioned(
                left: 28.49,
                top: 744.65,
                child: RoundedActionButton(
                  width: 345.02,
                  height: 68.10,
                  text: '확인',
                  background: const Color(0xFF00A4DE),
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.50,
                  ),
                  onTap: _goMain,
                ),
              ),

              // 드롭다운
              if (carrierOpen)
                Positioned(
                  left: 29,
                  top: 449,
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: Container(
                        width: 344,
                        height: 289,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        decoration: const ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1.50, color: Color(0xFF00A4DE)),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(17),
                              bottomRight: Radius.circular(17),
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _carrierRow('KT', enabled: true),
                            _dividerLine(),
                            _carrierRow('LG U+', enabled: true),
                            _dividerLine(),
                            _carrierRow('SKT 알뜰폰', enabled: true),
                            _dividerLine(),
                            _carrierRow('KT 알뜰폰', enabled: true),
                            _dividerLine(),
                            _carrierRow('LG U+ 알뜰폰', enabled: true),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 홈 인디케이터
              const Positioned(left: 128.50, top: 861, child: HomeIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot45 extends StatelessWidget {
  const _Dot45();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.black,
        fontSize: 45,
        fontWeight: FontWeight.w500,
        height: 0.80,
      ),
    );
  }
}
