import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VarietyScreen extends StatelessWidget {
  const VarietyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // 综艺内容区域
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 标题
                Text(
                  '综艺',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2c3e50),
                  ),
                ),
                const SizedBox(height: 20),
                // 占位内容
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFecf0f1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.mic,
                          size: 60,
                          color: const Color(0xFFbdc3c7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '综艺内容',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7f8c8d),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '即将推出精彩综艺内容',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF95a5a6),
                          ),
                        ),
                      ],
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
}
