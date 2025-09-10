import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 收藏夹模块组件
class FavoritesSection extends StatelessWidget {
  final VoidCallback? onTap;

  const FavoritesSection({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '收藏夹',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2c3e50),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 收藏夹内容
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 左侧图标
                    Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(left: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2c3e50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFFe74c3c),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 中间内容
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '我的收藏',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2c3e50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '查看收藏的影视内容',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF7f8c8d),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 右侧箭头
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF7f8c8d),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

