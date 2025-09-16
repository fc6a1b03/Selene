import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class SimpleTabSwitcher extends StatelessWidget {
  final List<String> tabs;
  final String selectedTab;
  final Function(String) onTabChanged;

  const SimpleTabSwitcher({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          height: 32, // 与 CapsuleTabSwitcher 相同的高度
          margin: const EdgeInsets.symmetric(vertical: 4), // 与 CapsuleTabSwitcher 相同的 margin
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tabs.map((tab) {
                final isSelected = tab == selectedTab;
                return GestureDetector(
                  onTap: () => onTabChanged(tab),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 32, // 确保与容器高度一致
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center, // 垂直居中
                    child: Text(
                      tab,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? const Color(0xFF27AE60) // 绿色
                            : (themeService.isDarkMode
                                ? const Color(0xFFb0b0b0)
                                : const Color(0xFF7f8c8d)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
