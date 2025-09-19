import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/search_result.dart';
import '../models/aggregated_search_result.dart';
import '../models/video_info.dart';
import '../services/theme_service.dart';
import 'video_card.dart';
import 'video_menu_bottom_sheet.dart';

/// 聚合搜索结果网格组件
class SearchResultAggGrid extends StatefulWidget {
  final List<SearchResult> results;
  final ThemeService themeService;
  final Function(VideoInfo)? onVideoTap;
  final Function(VideoInfo, VideoMenuAction)? onGlobalMenuAction;
  final bool hasReceivedStart;

  const SearchResultAggGrid({
    super.key,
    required this.results,
    required this.themeService,
    this.onVideoTap,
    this.onGlobalMenuAction,
    required this.hasReceivedStart,
  });

  @override
  State<SearchResultAggGrid> createState() => _SearchResultAggGridState();
}

class _SearchResultAggGridState extends State<SearchResultAggGrid> 
    with AutomaticKeepAliveClientMixin {
  
  // 聚合结果映射，key为聚合键，value为聚合结果
  Map<String, AggregatedSearchResult> _aggregatedResults = {};
  
  // 按添加顺序排列的聚合键列表
  List<String> _orderedKeys = [];
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _updateAggregatedResults();
  }

  @override
  void didUpdateWidget(SearchResultAggGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.results != oldWidget.results) {
      _updateAggregatedResults();
    }
  }

  /// 更新聚合结果
  void _updateAggregatedResults() {
    final newAggregatedResults = <String, AggregatedSearchResult>{};
    final newOrderedKeys = <String>[];
    
    for (final result in widget.results) {
      final key = AggregatedSearchResult.generateKey(
        result.title, 
        result.year, 
        result.episodes.length
      );
      
      if (newAggregatedResults.containsKey(key)) {
        // 已存在，添加到现有聚合结果中
        newAggregatedResults[key] = newAggregatedResults[key]!.addResult(result);
      } else {
        // 新的聚合结果
        newAggregatedResults[key] = AggregatedSearchResult.fromSearchResult(result);
        newOrderedKeys.add(key);
      }
    }
    
    setState(() {
      _aggregatedResults = newAggregatedResults;
      _orderedKeys = newOrderedKeys; // 直接使用新的顺序
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以支持 AutomaticKeepAliveClientMixin
    
    if (_aggregatedResults.isEmpty && widget.hasReceivedStart) {
      return _buildEmptyState();
    }
    
    if (_aggregatedResults.isEmpty && !widget.hasReceivedStart) {
      return const SizedBox.shrink(); // 搜索开始但未收到start消息时，不显示任何内容
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算每列的宽度，确保严格三列布局
        final double screenWidth = constraints.maxWidth;
        final double padding = 16.0; // 左右padding
        final double spacing = 12.0; // 列间距
        final double availableWidth = screenWidth - (padding * 2) - (spacing * 2); // 减去padding和间距
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
          itemCount: _orderedKeys.length,
          itemBuilder: (context, index) {
            final key = _orderedKeys[index];
            final aggregatedResult = _aggregatedResults[key]!;
            final videoInfo = aggregatedResult.toVideoInfo();
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: VideoCard(
                key: ValueKey(key), // 使用聚合键作为唯一key
                videoInfo: videoInfo,
                onTap: widget.onVideoTap != null ? () => _handleVideoTap(aggregatedResult) : null,
                from: 'agg', // 标记为聚合卡片
                cardWidth: itemWidth, // 传递计算出的宽度
                onGlobalMenuAction: widget.onGlobalMenuAction != null 
                    ? (action) => _handleGlobalMenuAction(aggregatedResult, action) 
                    : null,
                isFavorited: false, // 聚合卡片不显示收藏状态
              ),
            );
          },
        );
      },
    );
  }

  /// 处理视频点击
  void _handleVideoTap(AggregatedSearchResult aggregatedResult) {
    if (widget.onVideoTap != null) {
      // 对于聚合结果，显示源选择对话框
      _showSourceSelectionDialog(aggregatedResult);
    }
  }

  /// 显示源选择对话框
  void _showSourceSelectionDialog(AggregatedSearchResult aggregatedResult) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.themeService.isDarkMode 
              ? const Color(0xFF2C2C2C)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '选择播放源',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.themeService.isDarkMode 
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFF2C2C2C),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: aggregatedResult.originalResults.map((result) {
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9b59b6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: const Color(0xFF9b59b6),
                    size: 20,
                  ),
                ),
                title: Text(
                  result.sourceName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.themeService.isDarkMode 
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF2C2C2C),
                  ),
                ),
                subtitle: Text(
                  '${result.episodes.length}集',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: widget.themeService.isDarkMode 
                        ? const Color(0xFFB0B0B0)
                        : const Color(0xFF666666),
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onVideoTap!(result.toVideoInfo());
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '取消',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: widget.themeService.isDarkMode 
                      ? const Color(0xFFB0B0B0)
                      : const Color(0xFF666666),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 处理全局菜单操作
  void _handleGlobalMenuAction(AggregatedSearchResult aggregatedResult, VideoMenuAction action) {
    if (widget.onGlobalMenuAction != null) {
      if (action == VideoMenuAction.play) {
        // 播放操作显示源选择对话框
        _showSourceSelectionDialog(aggregatedResult);
      } else {
        // 其他操作直接传递
        final videoInfo = aggregatedResult.toVideoInfo();
        widget.onGlobalMenuAction!(videoInfo, action);
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: const Color(0xFFbdc3c7),
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
            '请尝试其他关键词',
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
