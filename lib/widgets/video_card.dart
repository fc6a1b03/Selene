import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/play_record.dart';

/// 视频卡片组件
class VideoCard extends StatelessWidget {
  final PlayRecord playRecord;
  final VoidCallback? onTap;
  final String from; // 场景值：'favorite', 'playrecord'
  final String? source; // 来源标识
  final String? id; // 唯一标识
  final double? cardWidth; // 卡片宽度，用于响应式布局

  const VideoCard({
    super.key,
    required this.playRecord,
    this.onTap,
    this.from = 'playrecord',
    this.source,
    this.id,
    this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    // 使用传入的宽度或默认宽度
    final double width = cardWidth ?? 120.0;
    final double height = width * 1.5; // 2:3 比例
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      playRecord.cover,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.movie,
                            color: Colors.grey,
                            size: 40,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2c3e50),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // 集数指示器
                if (_shouldShowEpisodeInfo())
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27ae60),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getEpisodeText(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                // 进度条
                if (_shouldShowProgress())
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: playRecord.progressPercentage,
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
            // 标题
            Center(
              child: Text(
                playRecord.title,
                style: GoogleFonts.poppins(
                  fontSize: width < 100 ? 10 : 11, // 根据宽度调整字体大小
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2c3e50),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 3), // 增加title和sourceName之间的间距
            // 视频源名称
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width < 100 ? 2 : 4, 
                  vertical: 0.5, // 进一步减少垂直padding
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF7f8c8d),
                    width: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  playRecord.sourceName,
                  style: GoogleFonts.poppins(
                    fontSize: width < 100 ? 9 : 10, // 根据宽度调整字体大小
                    color: const Color(0xFF7f8c8d),
                    height: 1.0, // 进一步减少行高
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据场景判断是否显示集数信息
  bool _shouldShowEpisodeInfo() {
    // 总集数为1时永远不显示集数指示器
    if (playRecord.totalEpisodes <= 1) {
      return false;
    }
    
    switch (from) {
      case 'favorite':
        return true; // 收藏夹中显示总集数
      case 'playrecord':
      default:
        return true; // 播放记录中显示当前/总集数
    }
  }

  /// 获取集数显示文本
  String _getEpisodeText() {
    switch (from) {
      case 'favorite':
        return '${playRecord.totalEpisodes}'; // 收藏夹只显示总集数
      case 'playrecord':
      default:
        return '${playRecord.index}/${playRecord.totalEpisodes}'; // 播放记录显示当前/总集数
    }
  }

  /// 根据场景判断是否显示进度条
  bool _shouldShowProgress() {
    switch (from) {
      case 'favorite':
        return false; // 收藏夹中不显示进度条
      case 'playrecord':
      default:
        return true; // 播放记录中显示进度条
    }
  }
}
