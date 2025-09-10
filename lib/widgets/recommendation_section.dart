import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import 'video_card.dart';

/// 推荐信息模块组件
class RecommendationSection extends StatelessWidget {
  final String title; // 标题
  final String? moreText; // 查看更多文本
  final VoidCallback? onMoreTap; // 查看更多点击回调
  final List<VideoInfo>? videoInfos; // 视频信息列表
  final List<PlayRecord>? items; // 数据列表（向后兼容）
  final Function(VideoInfo)? onItemTap; // 项目点击回调
  final Function(PlayRecord)? onPlayRecordTap; // PlayRecord点击回调（向后兼容）
  final bool isLoading; // 是否加载中
  final bool hasError; // 是否有错误
  final VoidCallback? onRetry; // 重试回调
  final double cardCount; // 显示的卡片数量（如2.75）
  final Map<String, String>? rateMap; // 评分映射，key为item.id，value为评分

  const RecommendationSection({
    super.key,
    required this.title,
    this.moreText,
    this.onMoreTap,
    this.videoInfos,
    this.items,
    this.onItemTap,
    this.onPlayRecordTap,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
    this.cardCount = 2.75,
    this.rateMap,
  });

  @override
  Widget build(BuildContext context) {
    // 获取当前使用的数据列表
    final currentItems = videoInfos ?? items ?? [];
    
    // 如果没有数据且不在加载中，隐藏组件
    if (!isLoading && currentItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和查看更多按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2c3e50),
                  ),
                ),
                if (moreText != null && onMoreTap != null)
                  TextButton(
                    onPressed: onMoreTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      moreText!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF7f8c8d),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 内容区域
          if (isLoading)
            _buildLoadingState()
          else if (hasError)
            _buildErrorState()
          else
            _buildContent(),
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算卡片宽度
        final double screenWidth = constraints.maxWidth;
        final double padding = 32.0; // 左右padding (16 * 2)
        final double spacing = 12.0; // 卡片间距
        final double availableWidth = screenWidth - padding;
        // 确保最小宽度，防止负宽度约束
        final double minCardWidth = 120.0; // 最小卡片宽度
        final double calculatedCardWidth = (availableWidth - (spacing * (cardCount - 1))) / cardCount;
        final double cardWidth = math.max(calculatedCardWidth, minCardWidth);
        
        return SizedBox(
          height: (cardWidth * 1.5) + 50, // 动态计算高度
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: (videoInfos ?? items ?? []).length,
            itemBuilder: (context, index) {
              if (videoInfos != null) {
                // 使用VideoInfo
                final videoInfo = videoInfos![index];
                return Container(
                  margin: EdgeInsets.only(
                    right: index < videoInfos!.length - 1 ? spacing : 0,
                  ),
                  child: VideoCard(
                    videoInfo: videoInfo,
                    onTap: () => onItemTap?.call(videoInfo),
                    from: videoInfo.source == 'douban' ? 'douban' : (videoInfo.source == 'bangumi' ? 'bangumi' : 'playrecord'),
                    cardWidth: cardWidth,
                  ),
                );
              } else {
                // 使用PlayRecord（向后兼容）
                final item = items![index];
                final videoInfo = VideoInfo.fromPlayRecord(
                  item,
                  doubanId: rateMap?[item.id],
                  bangumiId: null,
                  rate: rateMap?[item.id],
                );
                return Container(
                  margin: EdgeInsets.only(
                    right: index < items!.length - 1 ? spacing : 0,
                  ),
                  child: VideoCard(
                    videoInfo: videoInfo,
                    onTap: () => onPlayRecordTap?.call(item),
                    from: item.source == 'douban' ? 'douban' : (item.source == 'bangumi' ? 'bangumi' : 'playrecord'),
                    cardWidth: cardWidth,
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算卡片宽度
        final double screenWidth = constraints.maxWidth;
        final double padding = 32.0; // 左右padding (16 * 2)
        final double spacing = 12.0; // 卡片间距
        final double availableWidth = screenWidth - padding;
        // 确保最小宽度，防止负宽度约束
        final double minCardWidth = 120.0; // 最小卡片宽度
        final double calculatedCardWidth = (availableWidth - (spacing * (cardCount - 1))) / cardCount;
        final double cardWidth = math.max(calculatedCardWidth, minCardWidth);
        
        return Container(
          height: (cardWidth * 1.5) + 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3, // 显示3个骨架卡片
            itemBuilder: (context, index) {
              return Container(
                width: cardWidth,
                margin: EdgeInsets.only(
                  right: index < 2 ? spacing : 0,
                ),
                child: _buildSkeletonCard(cardWidth),
              );
            },
          ),
        );
      },
    );
  }

  /// 构建骨架卡片
  Widget _buildSkeletonCard(double width) {
    final double height = width * 1.5;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 封面骨架
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        // 标题骨架
        Container(
          height: 14,
          width: width * 0.8,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        // 源名称骨架
        Container(
          height: 10,
          width: width * 0.6,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '加载失败',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  '重试',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF2c3e50),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
