import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class MainLayout extends StatelessWidget {
  final Widget content;
  final int currentBottomNavIndex;
  final Function(int) onBottomNavChanged;
  final String selectedTopTab;
  final Function(String) onTopTabChanged;
  final bool isSearchMode;
  final Function(bool)? onSearchModeChanged;

  const MainLayout({
    super.key,
    required this.content,
    required this.currentBottomNavIndex,
    required this.onBottomNavChanged,
    required this.selectedTopTab,
    required this.onTopTabChanged,
    this.isSearchMode = false,
    this.onSearchModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Theme(
          data: themeService.isDarkMode ? themeService.darkTheme : themeService.lightTheme,
          child: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                color: themeService.isDarkMode 
                    ? const Color(0xFF000000) // 深色模式纯黑色
                    : null,
                gradient: themeService.isDarkMode 
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFe6f3fb), // 浅色模式渐变
                          Color(0xFFeaf3f7),
                          Color(0xFFf7f7f3),
                          Color(0xFFe9ecef),
                          Color(0xFFdbe3ea),
                          Color(0xFFd3dde6),
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
            bottomNavigationBar: _buildBottomNavBar(themeService),
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
        color: themeService.isDarkMode 
            ? const Color(0xFF1e1e1e).withOpacity(0.9)
            : Colors.white.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: themeService.isDarkMode 
                ? const Color(0xFF333333).withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
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
                      if (onSearchModeChanged != null) {
                        onSearchModeChanged!(!isSearchMode);
                      }
                    },
                    child: Center(
                      child: Icon(
                        LucideIcons.search,
                        color: themeService.isDarkMode 
                            ? const Color(0xFFffffff)
                            : const Color(0xFF2c3e50),
                        size: 24,
                        weight: 1.0,
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
                color: themeService.isDarkMode 
                    ? const Color(0xFFffffff)
                    : const Color(0xFF2c3e50),
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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Icon(
                              themeService.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                              key: ValueKey(themeService.isDarkMode),
                              color: themeService.isDarkMode 
                                  ? const Color(0xFFffffff)
                                  : const Color(0xFF2c3e50),
                              size: 24,
                              weight: 1.0,
                            ),
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
                            LucideIcons.user,
                            color: themeService.isDarkMode 
                                ? const Color(0xFFffffff)
                                : const Color(0xFF2c3e50),
                            size: 24,
                            weight: 1.0,
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

  Widget _buildBottomNavBar(ThemeService themeService) {
    final List<Map<String, dynamic>> navItems = [
      {'icon': LucideIcons.house, 'label': '首页'},
      {'icon': LucideIcons.video, 'label': '电影'},
      {'icon': LucideIcons.tv, 'label': '剧集'},
      {'icon': LucideIcons.cat, 'label': '动漫'},
      {'icon': LucideIcons.clover, 'label': '综艺'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: themeService.isDarkMode 
            ? const Color(0xFF1e1e1e).withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: themeService.isDarkMode 
                ? const Color(0xFF333333).withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
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
              bool isSelected = !isSearchMode && currentBottomNavIndex == index;
              
              return GestureDetector(
                onTap: () {
                  onBottomNavChanged(index);
                },
                behavior: HitTestBehavior.opaque, // 确保整个区域都可以点击
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'],
                        color: isSelected 
                            ? const Color(0xFF27ae60) 
                            : themeService.isDarkMode 
                                ? const Color(0xFFb0b0b0)
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
                              : themeService.isDarkMode 
                                  ? const Color(0xFFb0b0b0)
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

