import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopTabSwitcher extends StatefulWidget {
  final String selectedTab;
  final Function(String) onTabChanged;

  const TopTabSwitcher({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  State<TopTabSwitcher> createState() => _TopTabSwitcherState();
}

class _TopTabSwitcherState extends State<TopTabSwitcher>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // 根据初始选中状态设置动画
    if (widget.selectedTab == '首页') {
      _animationController.value = 0.0;
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TopTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTab != widget.selectedTab) {
      _animateToTab(widget.selectedTab);
    }
  }

  void _animateToTab(String tab) {
    if (tab == '首页') {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 160, // 缩小宽度
        height: 32, // 缩小高度
        decoration: BoxDecoration(
          color: const Color(0xFFe0e0e0), // 浅灰色背景
          borderRadius: BorderRadius.circular(16), // 相应调整圆角
        ),
        child: Stack(
          children: [
            // 动画背景胶囊
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  left: _animation.value * 80, // 80是每个胶囊的宽度
                  top: 0,
                  child: Container(
                    width: 80,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // 标签按钮
            Row(
              children: [
                // 首页按钮
                Expanded(
                  child: _buildTabButton('首页', widget.selectedTab == '首页', 0),
                ),
                // 收藏夹按钮
                Expanded(
                  child: _buildTabButton('收藏夹', widget.selectedTab == '收藏夹', 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建标签按钮
  Widget _buildTabButton(String label, bool isSelected, int index) {
    return GestureDetector(
      onTap: () {
        widget.onTabChanged(label);
      },
      child: Container(
        height: 32,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            // 计算当前按钮的文字颜色
            Color textColor;
            FontWeight fontWeight;
            
            if (label == '首页') {
              // 首页按钮：动画值越小（接近0）越选中
              double progress = 1.0 - _animation.value;
              textColor = Color.lerp(
                const Color(0xFF7f8c8d), // 未选中颜色
                const Color(0xFF2c3e50), // 选中颜色
                progress,
              )!;
              fontWeight = progress > 0.5 ? FontWeight.w600 : FontWeight.w400;
            } else {
              // 收藏夹按钮：动画值越大（接近1）越选中
              textColor = Color.lerp(
                const Color(0xFF7f8c8d), // 未选中颜色
                const Color(0xFF2c3e50), // 选中颜色
                _animation.value,
              )!;
              fontWeight = _animation.value > 0.5 ? FontWeight.w600 : FontWeight.w400;
            }

            return Center(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12, // 缩小字体
                  fontWeight: fontWeight,
                  color: textColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
