import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../services/page_cache_service.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  /// 刷新剧集数据
  Future<void> _refreshSeriesData() async {
    try {
      final cacheService = PageCacheService();
      
      // 刷新剧集相关缓存数据
      await Future.wait([
        cacheService.refreshPlayRecords(context),
        cacheService.refreshFavorites(context),
        cacheService.refreshSearchHistory(context),
      ]);
      
      // 强制重建页面
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // 刷新失败，静默处理
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyledRefreshIndicator(
      onRefresh: _refreshSeriesData,
      refreshText: '刷新剧集数据...',
      primaryColor: const Color(0xFF27AE60), // 绿色主题
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 剧集内容区域
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 标题
                  Text(
                    '剧集',
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
                            Icons.tv,
                            size: 60,
                            color: const Color(0xFFbdc3c7),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '剧集内容',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7f8c8d),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '即将推出精彩剧集内容',
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
      ),
    );
  }
}
