import 'package:flutter/material.dart';
import '../models/bangumi.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import '../services/page_cache_service.dart';
import 'recommendation_section.dart';
import 'video_menu_bottom_sheet.dart';

/// 新番放送组件
class BangumiSection extends StatefulWidget {
  final Function(PlayRecord)? onBangumiTap;
  final VoidCallback? onMoreTap;
  final Function(VideoInfo, VideoMenuAction)? onGlobalMenuAction; // 全局菜单操作回调

  const BangumiSection({
    super.key,
    this.onBangumiTap,
    this.onMoreTap,
    this.onGlobalMenuAction,
  });

  @override
  State<BangumiSection> createState() => _BangumiSectionState();
}

class _BangumiSectionState extends State<BangumiSection> {
  List<BangumiItem> _bangumiItems = [];
  bool _isLoading = true;
  bool _hasError = false;
  final PageCacheService _cacheService = PageCacheService();

  @override
  void initState() {
    super.initState();
    _loadBangumiCalendar();
  }

  /// 加载新番放送数据
  Future<void> _loadBangumiCalendar() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // 使用缓存服务获取数据
      final bangumiItems = await _cacheService.getBangumiCalendar(context);

      if (bangumiItems != null) {
        setState(() {
          _bangumiItems = bangumiItems;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  /// 转换为VideoInfo列表
  List<VideoInfo> _convertToVideoInfos() {
    return _bangumiItems.map((item) => item.toVideoInfo()).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 创建评分映射
    final rateMap = <String, String>{};
    for (final item in _bangumiItems) {
      if (item.rating.score > 0) {
        // 如果是整数则添加.0，否则保留一位小数
        final score = item.rating.score;
        final formattedScore = score == score.toInt() 
            ? '${score.toInt()}.0' 
            : score.toStringAsFixed(1);
        rateMap[item.id.toString()] = formattedScore;
      }
    }

    return RecommendationSection(
      title: '新番放送',
      moreText: '查看更多 >',
      onMoreTap: widget.onMoreTap,
      videoInfos: _convertToVideoInfos(),
      onItemTap: (videoInfo) {
        // 转换为PlayRecord用于回调
        final playRecord = PlayRecord(
          id: videoInfo.id,
          source: videoInfo.source,
          title: videoInfo.title,
          sourceName: videoInfo.sourceName,
          year: videoInfo.year,
          cover: videoInfo.cover,
          index: videoInfo.index,
          totalEpisodes: videoInfo.totalEpisodes,
          playTime: videoInfo.playTime,
          totalTime: videoInfo.totalTime,
          saveTime: videoInfo.saveTime,
          searchTitle: videoInfo.searchTitle,
        );
        widget.onBangumiTap?.call(playRecord);
      },
      onGlobalMenuAction: widget.onGlobalMenuAction,
      isLoading: _isLoading,
      hasError: _hasError,
      onRetry: _loadBangumiCalendar,
      cardCount: 2.75,
    );
  }
}
