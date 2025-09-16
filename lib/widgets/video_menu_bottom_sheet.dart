import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/video_info.dart';
import '../services/theme_service.dart';
import '../utils/image_url.dart';

/// 视频菜单选项
enum VideoMenuAction {
  play,
  favorite,
  unfavorite,
  deleteRecord,
  doubanDetail,
  bangumiDetail,
}

/// 视频菜单底部弹窗组件
class VideoMenuBottomSheet extends StatelessWidget {
  final VideoInfo videoInfo;
  final bool isFavorited; // 是否已收藏
  final Function(VideoMenuAction) onActionSelected;
  final VoidCallback onClose;
  final String from; // 来源场景

  const VideoMenuBottomSheet({
    super.key,
    required this.videoInfo,
    required this.isFavorited,
    required this.onActionSelected,
    required this.onClose,
    this.from = 'playrecord',
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: themeService.isDarkMode 
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF2C2C2C),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 6),
                          
                          // 源名称标签
                          (videoInfo.source == 'douban' || videoInfo.source == 'bangumi')
                              ? // 豆瓣或Bangumi来源：纯文本，无边框
                                Text(
                                  videoInfo.source == 'douban' ? '来自豆瓣' : '来自 Bangumi',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: themeService.isDarkMode 
                                        ? const Color(0xFF999999)
                                        : const Color(0xFF666666),
                                  ),
                                )
                              : // 其他来源：带边框的标签
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
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
                        ],
                      ),
                    ),
                    
                    // 关闭按钮
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 32,
                        height: 32,
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
    // 如果是豆瓣来源，只显示播放和豆瓣详情
    if (videoInfo.source == 'douban') {
      return Column(
        children: [
          _buildMenuItem(
            context,
            themeService,
            icon: Icons.play_circle_fill,
            iconColor: const Color(0xFF27AE60),
            title: '播放',
            subtitle: _getEpisodeSubtitle(),
            onTap: () {
              onActionSelected(VideoMenuAction.play);
              onClose();
            },
          ),
          
          _buildDivider(themeService),
          
          _buildMenuItem(
            context,
            themeService,
            icon: Icons.link,
            iconColor: const Color(0xFF3498DB),
            title: '豆瓣详情',
            onTap: () async {
              onClose();
              // 从videoInfo中获取doubanId，优先使用doubanId，如果为空或为0则使用id
              final doubanId = (videoInfo.doubanId != null && videoInfo.doubanId!.isNotEmpty && videoInfo.doubanId != "0") 
                  ? videoInfo.doubanId! 
                  : videoInfo.id;
              await _openDoubanDetail(doubanId);
            },
          ),
        ],
      );
    }
    
    // 如果是Bangumi来源，只显示播放和Bangumi详情
    if (videoInfo.source == 'bangumi') {
      return Column(
        children: [
          _buildMenuItem(
            context,
            themeService,
            icon: Icons.play_circle_fill,
            iconColor: const Color(0xFF27AE60),
            title: '播放',
            subtitle: _getEpisodeSubtitle(),
            onTap: () {
              onActionSelected(VideoMenuAction.play);
              onClose();
            },
          ),
          
          _buildDivider(themeService),
          
          _buildMenuItem(
            context,
            themeService,
            icon: Icons.link,
            iconColor: const Color(0xFF3498DB),
            title: 'Bangumi 详情',
            onTap: () async {
              onClose();
              // 从videoInfo中获取bangumiId，优先使用bangumiId，如果为空或为0则使用id
              final bangumiId = (videoInfo.bangumiId != null && videoInfo.bangumiId! > 0) 
                  ? videoInfo.bangumiId!.toString() 
                  : videoInfo.id;
              await _openBangumiDetail(bangumiId);
            },
          ),
        ],
      );
    }
    
    // 如果是收藏场景，只显示播放和取消收藏
    if (from == 'favorite') {
      return Column(
        children: [
          _buildMenuItem(
            context,
            themeService,
            icon: Icons.play_circle_fill,
            iconColor: const Color(0xFF27AE60),
            title: '播放',
            subtitle: _getEpisodeSubtitle(),
            onTap: () {
              onActionSelected(VideoMenuAction.play);
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
        ],
      );
    }
    
    // 如果是搜索场景，显示播放、收藏/取消收藏，如果有豆瓣ID则显示豆瓣详情
    if (from == 'search') {
      List<Widget> menuItems = [
        _buildMenuItem(
          context,
          themeService,
          icon: Icons.play_circle_fill,
          iconColor: const Color(0xFF27AE60),
          title: '播放',
          subtitle: _getEpisodeSubtitle(),
          onTap: () {
            onActionSelected(VideoMenuAction.play);
            onClose();
          },
        ),
        
        _buildDivider(themeService),
        
        // 根据收藏状态动态显示收藏或取消收藏
        _buildMenuItem(
          context,
          themeService,
          icon: isFavorited ? Icons.favorite : Icons.favorite_border,
          iconColor: const Color(0xFFE74C3C),
          title: isFavorited ? '取消收藏' : '收藏',
          onTap: () {
            onActionSelected(isFavorited ? VideoMenuAction.unfavorite : VideoMenuAction.favorite);
            onClose();
          },
        ),
      ];
      
      // 如果有豆瓣ID且不为0，添加豆瓣详情选项
      if (videoInfo.doubanId != null && videoInfo.doubanId!.isNotEmpty && videoInfo.doubanId != "0") {
        menuItems.addAll([
          _buildDivider(themeService),
          _buildMenuItem(
            context,
            themeService,
            icon: Icons.link,
            iconColor: const Color(0xFF3498DB),
            title: '豆瓣详情',
            onTap: () async {
              onClose();
              await _openDoubanDetail(videoInfo.doubanId!);
            },
          ),
        ]);
      }
      
      // 如果有Bangumi ID且不为0，添加Bangumi详情选项
      if (videoInfo.bangumiId != null && videoInfo.bangumiId! > 0) {
        menuItems.addAll([
          _buildDivider(themeService),
          _buildMenuItem(
            context,
            themeService,
            icon: Icons.link,
            iconColor: const Color(0xFF3498DB),
            title: 'Bangumi 详情',
            onTap: () async {
              onClose();
              await _openBangumiDetail(videoInfo.bangumiId!.toString());
            },
          ),
        ]);
      }
      
      return Column(children: menuItems);
    }
    
    // 其他来源显示完整菜单
    return Column(
      children: [
        _buildMenuItem(
          context,
          themeService,
          icon: Icons.play_circle_fill,
          iconColor: const Color(0xFF27AE60),
          title: '播放',
          subtitle: _getEpisodeSubtitle(),
          onTap: () {
            onActionSelected(VideoMenuAction.play);
            onClose();
          },
        ),
        
        _buildDivider(themeService),
        
        // 根据收藏状态动态显示收藏或取消收藏
        _buildMenuItem(
          context,
          themeService,
          icon: isFavorited ? Icons.favorite : Icons.favorite_border,
          iconColor: const Color(0xFFE74C3C),
          title: isFavorited ? '取消收藏' : '收藏',
          onTap: () {
            onActionSelected(isFavorited ? VideoMenuAction.unfavorite : VideoMenuAction.favorite);
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

  

  /// 获取集数副标题
  String? _getEpisodeSubtitle() {
    // 如果总集数只有1，则不显示集数信息
    if (videoInfo.totalEpisodes <= 1) {
      return null;
    }
    
    // 只有 from=playrecord 和 from=favorite 且 index 不为 0 的场景才显示集数信息
    if (from == 'playrecord') {
      return '${videoInfo.index}/${videoInfo.totalEpisodes}';
    }
    
    if (from == 'favorite' && videoInfo.index > 0) {
      return '${videoInfo.index}/${videoInfo.totalEpisodes}';
    }
    
    // 其他所有场景都不显示集数信息
    return null;
  }

  /// 打开豆瓣详情页面
  static Future<void> _openDoubanDetail(String doubanId) async {
    try {
      final url = 'https://movie.douban.com/subject/$doubanId';
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // 不处理
    }
  }

  /// 打开Bangumi详情页面
  static Future<void> _openBangumiDetail(String bangumiId) async {
    try {
      final url = 'https://bgm.tv/subject/$bangumiId';
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // 不处理
    }
  }

  /// 显示视频菜单底部弹窗
  static void show(
    BuildContext context, {
    required VideoInfo videoInfo,
    required bool isFavorited,
    required Function(VideoMenuAction) onActionSelected,
    String from = 'playrecord',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoMenuBottomSheet(
        videoInfo: videoInfo,
        isFavorited: isFavorited,
        onActionSelected: onActionSelected,
        onClose: () => Navigator.of(context).pop(),
        from: from,
      ),
    );
  }
}
