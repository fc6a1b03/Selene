import 'package:flutter/material.dart';
import '../models/douban_movie.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import '../services/page_cache_service.dart';
import 'recommendation_section.dart';

/// 热门剧集组件
class HotTvSection extends StatefulWidget {
  final Function(PlayRecord)? onTvTap;
  final VoidCallback? onMoreTap;

  const HotTvSection({
    super.key,
    this.onTvTap,
    this.onMoreTap,
  });

  @override
  State<HotTvSection> createState() => _HotTvSectionState();
}

class _HotTvSectionState extends State<HotTvSection> {
  List<DoubanMovie> _tvShows = [];
  bool _isLoading = true;
  bool _hasError = false;
  final PageCacheService _cacheService = PageCacheService();

  @override
  void initState() {
    super.initState();
    _loadHotTvShows();
  }

  /// 加载热门剧集
  Future<void> _loadHotTvShows() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // 使用缓存服务获取数据
      final tvShows = await _cacheService.getHotTvShows(context);

      if (tvShows != null) {
        setState(() {
          _tvShows = tvShows;
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
    return _tvShows.map((tvShow) => tvShow.toVideoInfo()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RecommendationSection(
      title: '热门剧集',
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
        widget.onTvTap?.call(playRecord);
      },
      isLoading: _isLoading,
      hasError: _hasError,
      onRetry: _loadHotTvShows,
      cardCount: 2.75,
    );
  }
}
