import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/favorites_grid.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import '../widgets/video_menu_bottom_sheet.dart';
import '../services/api_service.dart';
import '../services/page_cache_service.dart';

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
        child: FavoritesGrid(
          onVideoTap: (PlayRecord playRecord) {
            // TODO: 实现视频播放逻辑
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '播放: ${playRecord.title}',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                backgroundColor: const Color(0xFF27ae60),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
          onGlobalMenuAction: (VideoInfo videoInfo, VideoMenuAction action) {
            switch (action) {
              case VideoMenuAction.play:
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '播放: ${videoInfo.title}',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF27AE60),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                break;
              case VideoMenuAction.unfavorite:
                _handleUnfavorite(context, videoInfo);
                break;
              default:
                break;
            }
          },
        ),
      ),
    );
  }

  /// 处理取消收藏
  Future<void> _handleUnfavorite(BuildContext context, VideoInfo videoInfo) async {
    try {
      // 先立即从UI中移除该项目
      FavoritesGrid.removeFavoriteFromUI(videoInfo.source, videoInfo.id);
      
      // 立即从缓存中移除该项目
      PageCacheService().removeFavoriteFromCache(videoInfo.source, videoInfo.id);
      
      // 调用API取消收藏
      final response = await ApiService.unfavorite(videoInfo.source, videoInfo.id, context);

      if (!response.success) {
        // API调用失败，显示错误提示
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message ?? '取消收藏失败',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFe74c3c),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        // API失败时重新刷新缓存以恢复数据
        _refreshFavorites(context);
      }
    } catch (e) {
      // 显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '取消收藏失败: ${e.toString()}',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFe74c3c),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      // 异常时重新刷新缓存以恢复数据
      _refreshFavorites(context);
    }
  }

  /// 异步刷新收藏夹数据
  Future<void> _refreshFavorites(BuildContext context) async {
    try {
      // 刷新收藏夹缓存数据
      await PageCacheService().refreshFavorites(context);
      
      // 通知收藏夹组件刷新UI
      FavoritesGrid.refreshFavorites();
    } catch (e) {
      // 错误处理，静默处理
    }
  }
}

