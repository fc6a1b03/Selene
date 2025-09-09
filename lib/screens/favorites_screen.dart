import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 收藏夹页面
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '收藏夹',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2c3e50),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF2c3e50),
        ),
      ),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 64,
                color: const Color(0xFF2c3e50).withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                '收藏夹功能',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF2c3e50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '即将上线...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF7f8c8d),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
