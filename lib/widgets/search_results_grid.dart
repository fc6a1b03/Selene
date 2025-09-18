import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/search_result.dart';
import '../models/video_info.dart';
import '../services/page_cache_service.dart';
import '../services/theme_service.dart';
import 'video_card.dart';
import 'video_menu_bottom_sheet.dart';

/// 搜索结果网格组件
class SearchResultsGrid extends StatefulWidget {
  final List<SearchResult> results;
  final ThemeService themeService;
  final Function(VideoInfo)? onVideoTap;
  final Function(VideoInfo, VideoMenuAction)? onGlobalMenuAction;
  final bool hasReceivedStart;

  const SearchResultsGrid({
    super.key,
    required this.results,
    required this.themeService,
    this.onVideoTap,
    this.onGlobalMenuAction,
    required this.hasReceivedStart,
  });

  @override
  State<SearchResultsGrid> createState() => _SearchResultsGridState();
}

class _SearchResultsGridState extends State<SearchResultsGrid>
    with AutomaticKeepAliveClientMixin {
  final PageCacheService _cacheService = PageCacheService();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以支持 AutomaticKeepAliveClientMixin

    if (widget.results.isEmpty && widget.hasReceivedStart) {
      return _buildEmptyState();
    }

    if (widget.results.isEmpty && !widget.hasReceivedStart) {
      return const SizedBox.shrink(); // 搜索开始但未收到start消息时，不显示任何内容
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算每列的宽度，确保严格三列布局
        final double screenWidth = constraints.maxWidth;
        final double padding = 16.0; // 左右padding
        final double spacing = 12.0; // 列间距
        final double availableWidth =
            screenWidth - (padding * 2) - (spacing * 2); // 减去padding和间距
        // 确保最小宽度，防止负宽度约束
        final double minItemWidth = 80.0; // 最小项目宽度
        final double calculatedItemWidth = availableWidth / 3;
        final double itemWidth = math.max(calculatedItemWidth, minItemWidth);
        final double itemHeight = itemWidth * 2.0; // 增加高度比例，确保有足够空间避免溢出

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 严格3列布局
            childAspectRatio: itemWidth / itemHeight, // 精确计算宽高比
            crossAxisSpacing: spacing, // 列间距
            mainAxisSpacing: 16, // 行间距 - 与收藏grid保持一致
          ),
          itemCount: widget.results.length,
          itemBuilder: (context, index) {
            final result = widget.results[index];
            final videoInfo = result.toVideoInfo();

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: VideoCard(
                key: ValueKey(
                    '${result.id}_${result.source}'), // 为每个卡片添加唯一key
                videoInfo: videoInfo,
                onTap: widget.onVideoTap != null
                    ? () => widget.onVideoTap!(videoInfo)
                    : null,
                from: 'search',
                cardWidth: itemWidth, // 传递计算出的宽度
                onGlobalMenuAction: widget.onGlobalMenuAction != null
                    ? (action) => widget.onGlobalMenuAction!(videoInfo, action)
                    : null,
                isFavorited: _cacheService.isFavoritedSync(
                    videoInfo.source, videoInfo.id), // 同步检查收藏状态
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 80,
            color: Color(0xFFbdc3c7),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无搜索结果',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7f8c8d),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '请尝试其他关键词或调整筛选条件',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF95a5a6),
            ),
          ),
        ],
      ),
    );
  }
}
