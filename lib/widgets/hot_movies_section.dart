import 'package:flutter/material.dart';
import '../models/douban_movie.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import '../services/api_service.dart';
import 'recommendation_section.dart';

/// 热门电影组件
class HotMoviesSection extends StatefulWidget {
  final Function(PlayRecord)? onMovieTap;

  const HotMoviesSection({
    super.key,
    this.onMovieTap,
  });

  @override
  State<HotMoviesSection> createState() => _HotMoviesSectionState();
}

class _HotMoviesSectionState extends State<HotMoviesSection> {
  List<DoubanMovie> _movies = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadHotMovies();
  }

  /// 加载热门电影
  Future<void> _loadHotMovies() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      const apiUrl = '/api/douban/categories?category=热门&kind=movie&pageLimit=20&pageStart=0&type=全部';

      final response = await ApiService.get<Map<String, dynamic>>(
        apiUrl,
        context: context,
      );

      if (response.success && response.data != null) {
        try {
          final doubanResponse = DoubanResponse.fromJson(response.data!);
          
          setState(() {
            _movies = doubanResponse.list;
            _isLoading = false;
          });
        } catch (parseError) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
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
  Widget build(BuildContext context) {
    return RecommendationSection(
      title: '热门电影',
      moreText: '查看更多 >',
      onMoreTap: () {
        // TODO: 实现跳转到电影列表页面
      },
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
      isLoading: _isLoading,
      hasError: _hasError,
      onRetry: _loadHotMovies,
      cardCount: 2.75,
    );
  }
}
