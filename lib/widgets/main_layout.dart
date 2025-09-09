import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';

class MainLayout extends StatelessWidget {
  final Widget content;
  final int currentBottomNavIndex;
  final Function(int) onBottomNavChanged;
  final String selectedTopTab;
  final Function(String) onTopTabChanged;

  const MainLayout({
    super.key,
    required this.content,
    required this.currentBottomNavIndex,
    required this.onBottomNavChanged,
    required this.selectedTopTab,
    required this.onTopTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, child) {
        final themeService = ThemeService();
        return Theme(
          data: themeService.isDarkMode ? themeService.darkTheme : themeService.lightTheme,
          child: Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFe6f3fb), // #e6f3fb 0%
                    Color(0xFFeaf3f7), // #eaf3f7 18%
                    Color(0xFFf7f7f3), // #f7f7f3 38%
                    Color(0xFFe9ecef), // #e9ecef 60%
                    Color(0xFFdbe3ea), // #dbe3ea 80%
                    Color(0xFFd3dde6), // #d3dde6 100%
                  ],
                  stops: [0.0, 0.18, 0.38, 0.60, 0.80, 1.0],
                ),
              ),
              child: Column(
                children: [
                  // 固定 Header
                  _buildHeader(context, themeService),
                  // 主要内容区域
                  Expanded(
                    child: content,
                  ),
                ],
              ),
            ),
            // 固定底部导航栏
            bottomNavigationBar: _buildBottomNavBar(),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ThemeService themeService) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // 左侧搜索图标
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 32,
              height: 32,
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      // TODO: 实现搜索功能
                    },
                    child: Center(
                      child: Icon(
                        Icons.search,
                        color: const Color(0xFF2c3e50),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 完全居中的 Logo
          Center(
            child: Text(
              'Selene',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF2c3e50),
                letterSpacing: 1.5,
              ),
            ),
          ),
          // 右侧按钮组
          Positioned(
            right: 0,
            top: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 深浅模式切换按钮
                Container(
                  width: 32,
                  height: 32,
                  child: Material(
                    color: Colors.transparent,
                    child: Ink(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          themeService.toggleTheme();
                        },
                        child: Center(
                          child: Icon(
                            themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: const Color(0xFF2c3e50),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 按钮间距
                const SizedBox(width: 12),
                // 用户按钮
                Container(
                  width: 32,
                  height: 32,
                  child: Material(
                    color: Colors.transparent,
                    child: Ink(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          // TODO: 实现用户功能
                        },
                        child: Center(
                          child: Icon(
                            Icons.person,
                            color: const Color(0xFF2c3e50),
                            size: 24,
                          ),
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
    );
  }

  Widget _buildBottomNavBar() {
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.home, 'label': '首页'},
      {'icon': Icons.movie, 'label': '电影'},
      {'icon': Icons.tv, 'label': '剧集'},
      {'icon': Icons.pets, 'label': '动漫'},
      {'icon': Icons.mic, 'label': '综艺'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> item = entry.value;
              bool isSelected = currentBottomNavIndex == index;
              
              return GestureDetector(
                onTap: () {
                  onBottomNavChanged(index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'],
                        color: isSelected 
                            ? const Color(0xFF27ae60) 
                            : const Color(0xFF7f8c8d),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected 
                              ? const Color(0xFF27ae60) 
                              : const Color(0xFF7f8c8d),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
