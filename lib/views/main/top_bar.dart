import 'package:flutter/material.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  final String selectedLabel;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddPressed;
  final VoidCallback onMenuPressed;
  final ImageProvider? logoImage;

  const TopBar({
    super.key,
    required this.selectedLabel,
    required this.onSelect,
    required this.onAddPressed,
    required this.onMenuPressed,
    this.logoImage,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  bool _isOpen = false;

  Future<void> _openDropdown(BuildContext context) async {
    setState(() => _isOpen = true);

    final picked = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _DropdownDialog(initial: widget.selectedLabel),
    );

    if (picked != null) widget.onSelect(picked);

    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              // LEFT: dropdown trigger (NO ripple)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openDropdown(context),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.selectedLabel == '내 친구')
                      const Text(
                        '친구소식',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      )
                    else if (widget.logoImage != null)
                      Image(
                        image: widget.logoImage!,
                        height: 40,
                        width: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: _isOpen ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // RIGHT: plus button (NO ripple)
              _NoRippleIconButton(
                onTap: widget.onAddPressed,
                child: const Icon(
                  Icons.add,
                  size: 20,
                  weight: 700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Dropdown ----------

class _DropdownDialog extends StatelessWidget {
  final String initial;
  const _DropdownDialog({required this.initial});

  @override
  Widget build(BuildContext context) {
  

    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
        ),
        Positioned(
          left: 12,
          top: 60,
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 20,
                  offset: Offset(0, 8),
                  color: Color(0x22000000),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NoRippleMenuItem(
                  text: '전체',
                  isSelected: initial == '전체',
                  onTap: () => Navigator.pop(context, '전체'),
                ),
                _NoRippleMenuItem(
                  text: '내 친구',
                  isSelected: initial == '내 친구',
                  onTap: () => Navigator.pop(context, '내 친구'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ---------- Menu Item (NO ripple) ----------

class _NoRippleMenuItem extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _NoRippleMenuItem({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: Colors.black.withValues(alpha: isSelected ? 1.0 : 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- Square Button (NO ripple) ----------

class _NoRippleIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _NoRippleIconButton({
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: Color.fromRGBO(19, 21, 24, 1),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
