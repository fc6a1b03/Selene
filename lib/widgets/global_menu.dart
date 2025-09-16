import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_info.dart';
import '../services/theme_service.dart';
import '../utils/image_url.dart';

/// 视频菜单选项
enum VideoMenuAction {
  play,
  playInNewTab,
  unfavorite,
  deleteRecord,
}

/// 视频菜单组件
class VideoMenu extends StatelessWidget {
  final VideoInfo videoInfo;
  final Function(VideoMenuAction) onActionSelected;
  final VoidCallback onClose;

  const VideoMenu({
    super.key,
    required this.videoInfo,
    required this.onActionSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return FutureBuilder<String>(
          future: getImageUrl(videoInfo.cover, videoInfo.source),
          builder: (context, snapshot) {
            final String thumbUrl = snapshot.data ?? videoInfo.cover;
            final headers = getImageRequestHeaders(thumbUrl, videoInfo.source);
        return Container(
          decoration: BoxDecoration(
            color: themeService.isDarkMode 
                ? const Color(0xFF2C2C2C)
                : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部拖拽指示器
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeService.isDarkMode 
                      ? const Color(0xFF666666)
                      : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 头部信息区域
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 缩略图
                    Container(
                      width: 60,
                      height: 80,
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
                          imageUrl: thumbUrl,
                          httpHeaders: headers,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: themeService.isDarkMode 
                                ? const Color(0xFF333333)
                                : Colors.grey[300],
                            child: Icon(
                              Icons.movie,
                              color: themeService.isDarkMode 
                                  ? const Color(0xFF666666)
                                  : Colors.grey,
                              size: 24,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: themeService.isDarkMode 
                                ? const Color(0xFF333333)
                                : Colors.grey[300],
                            child: Icon(
                              Icons.movie,
                              color: themeService.isDarkMode 
                                  ? const Color(0xFF666666)
                                  : Colors.grey,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // 标题和分类信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题
                          Text(
                            videoInfo.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: themeService.isDarkMode 
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF2C2C2C),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // 分类标签
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: themeService.isDarkMode 
                                    ? const Color(0xFF666666)
                                    : const Color(0xFFE0E0E0),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              videoInfo.sourceName,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: themeService.isDarkMode 
                                    ? const Color(0xFF999999)
                                    : const Color(0xFF666666),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // 选择操作提示
                          Text(
                            '选择操作',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: themeService.isDarkMode 
                                  ? const Color(0xFF999999)
                                  : const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 关闭按钮
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: themeService.isDarkMode 
                              ? const Color(0xFF404040)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: themeService.isDarkMode 
                              ? const Color(0xFF999999)
                              : const Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 菜单选项
              _buildMenuOptions(context, themeService),
              
              // 底部安全区域
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
          },
        );
      },
    );
  }

  /// 构建菜单选项
  Widget _buildMenuOptions(BuildContext context, ThemeService themeService) {
    return Column(
      children: [
        _buildMenuItem(
          context,
          themeService,
          icon: Icons.play_circle_fill,
          iconColor: const Color(0xFF27AE60),
          title: '播放',
          subtitle: '${videoInfo.index}/${videoInfo.totalEpisodes}',
          onTap: () {
            onActionSelected(VideoMenuAction.play);
            onClose();
          },
        ),
        
        _buildDivider(themeService),
        
        _buildMenuItem(
          context,
          themeService,
          icon: Icons.open_in_new,
          iconColor: const Color(0xFF666666),
          title: '新标签页播放',
          onTap: () {
            onActionSelected(VideoMenuAction.playInNewTab);
            onClose();
          },
        ),
        
        _buildDivider(themeService),
        
        _buildMenuItem(
          context,
          themeService,
          icon: Icons.favorite,
          iconColor: const Color(0xFFE74C3C),
          title: '取消收藏',
          onTap: () {
            onActionSelected(VideoMenuAction.unfavorite);
            onClose();
          },
        ),
        
        _buildDivider(themeService),
        
        _buildMenuItem(
          context,
          themeService,
          icon: Icons.delete,
          iconColor: const Color(0xFFE74C3C),
          title: '删除记录',
          onTap: () {
            onActionSelected(VideoMenuAction.deleteRecord);
            onClose();
          },
        ),
      ],
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem(
    BuildContext context,
    ThemeService themeService, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 图标
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: iconColor,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 标题
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: themeService.isDarkMode 
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF2C2C2C),
                  ),
                ),
              ),
              
              // 副标题（集数信息）
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: themeService.isDarkMode 
                        ? const Color(0xFF999999)
                        : const Color(0xFF666666),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建分割线
  Widget _buildDivider(ThemeService themeService) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: themeService.isDarkMode 
          ? const Color(0xFF404040)
          : const Color(0xFFE0E0E0),
    );
  }

  

  /// 显示视频菜单
  static void show(
    BuildContext context, {
    required VideoInfo videoInfo,
    required Function(VideoMenuAction) onActionSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoMenu(
        videoInfo: videoInfo,
        onActionSelected: onActionSelected,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}
