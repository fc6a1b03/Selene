import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_info.dart';
import '../services/theme_service.dart';
import 'video_menu_bottom_sheet.dart';
import '../utils/image_url.dart';

/// 视频卡片组件
class VideoCard extends StatelessWidget {
  final VideoInfo videoInfo;
  final VoidCallback? onTap;
  final String from; // 场景值：'favorite', 'playrecord', 'search'
  final double? cardWidth; // 卡片宽度，用于响应式布局
  final Function(VideoMenuAction)? onGlobalMenuAction; // 视频菜单操作回调
  final bool isFavorited; // 是否已收藏

  const VideoCard({
    super.key,
    required this.videoInfo,
    this.onTap,
    this.from = 'playrecord',
    this.cardWidth,
    this.onGlobalMenuAction,
    this.isFavorited = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        // 使用传入的宽度或默认宽度
        final double width = cardWidth ?? 120.0;
        final double height = width * 1.5; // 2:3 比例
        
        // 缓存计算结果
        final bool shouldShowEpisodeInfo = _shouldShowEpisodeInfo();
        final bool shouldShowProgress = _shouldShowProgress();
        final String episodeText = shouldShowEpisodeInfo ? _getEpisodeText() : '';
        
        return FutureBuilder<String>(
          future: getImageUrl(videoInfo.cover, videoInfo.source),
          builder: (context, snapshot) {
            final String imageUrl = snapshot.data ?? videoInfo.cover;
            final headers = getImageRequestHeaders(imageUrl, videoInfo.source);
        
        return GestureDetector(
          onTap: onTap,
          onLongPress: (from == 'playrecord' || from == 'douban' || from == 'bangumi' || from == 'favorite' || from == 'search') ? () {
            // 触发震动反馈
            try {
              HapticFeedback.mediumImpact();
            } catch (e) {
              // 震动失败时静默处理，不影响菜单显示
            }
            
            _showGlobalMenu(context);
          } : null,
          // 优化长按响应
          onLongPressStart: (from == 'playrecord' || from == 'douban' || from == 'bangumi' || from == 'favorite' || from == 'search') ? (_) {
            // 长按开始时的视觉反馈
          } : null,
          // 设置手势行为，确保长按优先级
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
          width: width,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 封面图片和进度指示器
            Stack(
              children: [
                // 封面图片
                Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        // 使用图片URL作为缓存key
                        cacheKey: imageUrl,
                        httpHeaders: headers,
                        // 添加缓存配置
                        memCacheWidth: (width * MediaQuery.of(context).devicePixelRatio).round(),
                        memCacheHeight: (height * MediaQuery.of(context).devicePixelRatio).round(),
                        // 占位符
                        placeholder: (context, url) => Container(
                          width: width,
                          height: height,
                          decoration: BoxDecoration(
                            color: themeService.isDarkMode 
                                ? const Color(0xFF333333)
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // 错误占位符
                        errorWidget: (context, url, error) => Container(
                          color: themeService.isDarkMode 
                              ? const Color(0xFF333333)
                              : Colors.grey[300],
                          child: Icon(
                            Icons.movie,
                            color: themeService.isDarkMode 
                                ? const Color(0xFF666666)
                                : Colors.grey,
                            size: 40,
                          ),
                        ),
                        // 图片淡入动画
                        fadeInDuration: const Duration(milliseconds: 200),
                        fadeOutDuration: const Duration(milliseconds: 100),
                      ),
                    ),
                ),
                // 年份徽章（搜索模式）
                if (from == 'search' && videoInfo.year.isNotEmpty)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2c3e50).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        videoInfo.year,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                // 集数指示器或评分指示器
                if ((from == 'douban' || from == 'bangumi') && _shouldShowRating())
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFe91e63), // 粉色圆形背景
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          videoInfo.rate!,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (shouldShowEpisodeInfo)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27ae60),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        episodeText,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                // 进度条
                if (shouldShowProgress)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: videoInfo.progressPercentage,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF27ae60),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            // 标题和源名称容器，确保居中对齐
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题
                  Text(
                    videoInfo.title,
                    style: GoogleFonts.poppins(
                      fontSize: width < 100 ? 12 : 13, // 根据宽度调整字体大小，调大字体
                      fontWeight: FontWeight.w500,
                      color: themeService.isDarkMode 
                          ? const Color(0xFFffffff)
                          : const Color(0xFF2c3e50),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: from == 'douban' ? 2 : 1, // 豆瓣模式允许两行，其他模式一行
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 豆瓣模式和Bangumi模式不显示来源信息
                  if (from != 'douban' && from != 'bangumi') ...[
                    const SizedBox(height: 3), // 增加title和sourceName之间的间距
                    // 视频源名称
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: width < 100 ? 2 : 4, 
                        vertical: 2.0, // 增加垂直padding，让border不紧贴文字
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF7f8c8d),
                          width: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        videoInfo.sourceName,
                        style: GoogleFonts.poppins(
                          fontSize: width < 100 ? 11 : 12, // 根据宽度调整字体大小，调大字体
                          color: const Color(0xFF7f8c8d),
                          height: 1.0, // 进一步减少行高
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
          },
        );
      },
    );
  }

  /// 根据场景判断是否显示集数信息
  bool _shouldShowEpisodeInfo() {
    // 豆瓣模式和Bangumi模式不显示集数信息
    if (from == 'douban' || from == 'bangumi') {
      return false;
    }
    
    // 总集数为1时永远不显示集数指示器
    if (videoInfo.totalEpisodes <= 1) {
      return false;
    }
    
    switch (from) {
      case 'favorite':
        return true; // 收藏夹中显示总集数
      case 'playrecord':
        return true; // 播放记录中显示当前/总集数
      case 'search':
        return true; // 搜索模式中显示总集数
      default:
        return true; // 默认显示当前/总集数
    }
  }

  /// 获取集数显示文本
  String _getEpisodeText() {
    switch (from) {
      case 'favorite':
        // 收藏夹：如果有播放记录（index > 0）显示 x/y，否则只显示总集数
        return videoInfo.index > 0 
            ? '${videoInfo.index}/${videoInfo.totalEpisodes}'
            : '${videoInfo.totalEpisodes}';
      case 'playrecord':
        return '${videoInfo.index}/${videoInfo.totalEpisodes}'; // 播放记录显示当前/总集数
      case 'search':
        return '${videoInfo.totalEpisodes}'; // 搜索模式只显示总集数
      default:
        return '${videoInfo.index}/${videoInfo.totalEpisodes}'; // 默认显示当前/总集数
    }
  }

  /// 根据场景判断是否显示进度条
  bool _shouldShowProgress() {
    switch (from) {
      case 'favorite':
        return false; // 收藏夹中不显示进度条
      case 'douban':
        return false; // 豆瓣模式不显示进度条
      case 'bangumi':
        return false; // Bangumi模式不显示进度条
      case 'search':
        return false; // 搜索模式不显示进度条
      case 'playrecord':
      default:
        return true; // 播放记录中显示进度条
    }
  }

  

  /// 判断是否应该显示评分
  bool _shouldShowRating() {
    // 评分为空或null时不显示
    if (videoInfo.rate == null || videoInfo.rate!.isEmpty) {
      return false;
    }
    
    // 尝试解析评分为数字，如果为0或解析失败则不显示
    try {
      final rating = double.parse(videoInfo.rate!);
      return rating > 0;
    } catch (e) {
      // 如果评分不是数字格式，则不显示
      return false;
    }
  }

  /// 显示视频菜单
  void _showGlobalMenu(BuildContext context) {
    if (onGlobalMenuAction != null) {
      VideoMenuBottomSheet.show(
        context,
        videoInfo: videoInfo,
        isFavorited: isFavorited,
        onActionSelected: onGlobalMenuAction!,
        from: from,
      );
    }
  }
}
