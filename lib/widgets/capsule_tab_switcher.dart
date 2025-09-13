import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class CapsuleTabSwitcher extends StatefulWidget {
  final List<String> tabs;
  final String selectedTab;
  final Function(String) onTabChanged;

  const CapsuleTabSwitcher({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  State<CapsuleTabSwitcher> createState() => _CapsuleTabSwitcherState();
}

class _CapsuleTabSwitcherState extends State<CapsuleTabSwitcher>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _leftAnimation;
  late Animation<double> _widthAnimation;

  int _selectedIndex = 0;
  int _oldIndex = 0;

  final List<double> _tabWidths = [];
  final List<double> _tabOffsets = [];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.tabs.indexOf(widget.selectedTab);
    _oldIndex = _selectedIndex;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _calculateTabMetrics();
    _createAnimations();
  }

  void _calculateTabMetrics() {
    _tabWidths.clear();
    _tabOffsets.clear();

    for (final tab in widget.tabs) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: tab,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: double.infinity);
      _tabWidths.add(textPainter.size.width + 24); // 12 padding on each side
    }

    _tabOffsets.add(0.0);
    for (int i = 0; i < _tabWidths.length - 1; i++) {
      _tabOffsets.add(_tabOffsets[i] + _tabWidths[i]);
    }
  }

  void _createAnimations() {
    final beginLeft = _tabOffsets[_selectedIndex];
    final beginWidth = _tabWidths[_selectedIndex];

    _leftAnimation = Tween<double>(begin: beginLeft, end: beginLeft)
        .animate(_progressAnimation);
    _widthAnimation = Tween<double>(begin: beginWidth, end: beginWidth)
        .animate(_progressAnimation);
  }

  @override
  void didUpdateWidget(CapsuleTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabs.toString() != oldWidget.tabs.toString()) {
      _calculateTabMetrics();
    }
    if (widget.selectedTab != oldWidget.selectedTab) {
      _animateToTab(widget.selectedTab);
    }
  }

  void _animateToTab(String tab) {
    if (_animationController.isAnimating) return;
    final newIndex = widget.tabs.indexOf(tab);
    if (newIndex != _selectedIndex) {
      _oldIndex = _selectedIndex;
      _selectedIndex = newIndex;

      final oldLeft = _tabOffsets[_oldIndex];
      final oldWidth = _tabWidths[_oldIndex];
      final newLeft = _tabOffsets[_selectedIndex];
      final newWidth = _tabWidths[_selectedIndex];

      setState(() {
        _leftAnimation =
            Tween<double>(begin: oldLeft, end: newLeft).animate(_progressAnimation);
        _widthAnimation = Tween<double>(begin: oldWidth, end: newWidth)
            .animate(_progressAnimation);
      });

      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tabWidths.length != widget.tabs.length) {
      return const SizedBox.shrink();
    }

    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final totalWidth =
            _tabWidths.isNotEmpty ? _tabWidths.reduce((a, b) => a + b) : 0.0;

        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            width: totalWidth,
            height: 32,
            decoration: BoxDecoration(
              color: themeService.isDarkMode
                  ? const Color(0xFF333333)
                  : const Color(0xFFe0e0e0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: _leftAnimation.value,
                      top: 0,
                      child: Container(
                        width: _widthAnimation.value,
                        height: 32,
                        decoration: BoxDecoration(
                          color: themeService.isDarkMode
                              ? const Color(0xFF1e1e1e)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: themeService.isDarkMode
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Row(
                  children: widget.tabs.map((tab) {
                    final index = widget.tabs.indexOf(tab);
                    return SizedBox(
                      width: _tabWidths[index],
                      child: _buildTabButton(tab, index, themeService),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String label, int index, ThemeService themeService) {
    return GestureDetector(
      onTap: () {
        if (!_animationController.isAnimating) {
          widget.onTabChanged(label);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            double progress = 0.0;
            if (index == _selectedIndex) {
              progress = _animationController.isAnimating ? _progressAnimation.value : 1.0;
            } else if (index == _oldIndex) {
              progress = _animationController.isAnimating ? 1.0 - _progressAnimation.value : 0.0;
            }

            final color = Color.lerp(
              themeService.isDarkMode
                  ? const Color(0xFFb0b0b0)
                  : const Color(0xFF7f8c8d),
              themeService.isDarkMode ? Colors.white : Colors.black,
              progress,
            );

            final fontWeight = progress > 0.5 ? FontWeight.w600 : FontWeight.w400;

            return Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: fontWeight,
                color: color,
              ),
            );
          },
        ),
      ),
    );
  }
}
