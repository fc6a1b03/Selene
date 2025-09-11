import 'package:flutter/material.dart';
import '../models/douban_movie.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import '../services/page_cache_service.dart';
import 'recommendation_section.dart';
import 'video_menu_bottom_sheet.dart';

/// 热门电影组件
class HotMoviesSection extends StatefulWidget {
  final Function(PlayRecord)? onMovieTap;
  final VoidCallback? onMoreTap;
  final Function(VideoInfo, VideoMenuAction)? onGlobalMenuAction;

  const HotMoviesSection({
    super.key,
    this.onMovieTap,
    this.onMoreTap,
    this.onGlobalMenuAction,
  });

  @override
  State<HotMoviesSection> createState() => _HotMoviesSectionState();

  /// 静态方法：刷新热门电影数据
  static Future<void> refreshHotMovies() async {
    await _HotMoviesSectionState._currentInstance?._loadHotMovies();
  }
}

class _HotMoviesSectionState extends State<HotMoviesSection> {
  List<DoubanMovie> _movies = [];
  bool _isLoading = true;
  bool _hasError = false;
  final PageCacheService _cacheService = PageCacheService();
  
  // 静态变量存储当前实例
  static _HotMoviesSectionState? _currentInstance;

  @override
  void initState() {
    super.initState();
    // 设置当前实例
    _currentInstance = this;
    _loadHotMovies();
  }

  /// 加载热门电影
  Future<void> _loadHotMovies() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // 使用缓存服务获取数据
      final movies = await _cacheService.getHotMovies(context);

      if (movies != null) {
        setState(() {
          _movies = movies;
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
    return _movies.map((movie) => movie.toVideoInfo()).toList();
  }

  @override
  void dispose() {
    // 清除当前实例引用
    if (_currentInstance == this) {
      _currentInstance = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RecommendationSection(
      title: '热门电影',
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
        widget.onMovieTap?.call(playRecord);
      },
      onGlobalMenuAction: widget.onGlobalMenuAction,
      isLoading: _isLoading,
      hasError: _hasError,
      onRetry: _loadHotMovies,
      cardCount: 2.75,
    );
  }
}
