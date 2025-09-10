import 'package:flutter/material.dart';
import '../models/douban_movie.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import '../services/api_service.dart';
import 'recommendation_section.dart';

/// 热门综艺组件
class HotShowSection extends StatefulWidget {
  final Function(PlayRecord)? onShowTap;

  const HotShowSection({
    super.key,
    this.onShowTap,
  });

  @override
  State<HotShowSection> createState() => _HotShowSectionState();
}

class _HotShowSectionState extends State<HotShowSection> {
  List<DoubanMovie> _shows = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadHotShows();
  }

  /// 加载热门综艺
  Future<void> _loadHotShows() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      const apiUrl = '/api/douban/categories?category=show&kind=tv&pageLimit=20&pageStart=0&type=show';

      final response = await ApiService.get<Map<String, dynamic>>(
        apiUrl,
        context: context,
      );

      if (response.success && response.data != null) {
        try {
          final doubanResponse = DoubanResponse.fromJson(response.data!);
          
          setState(() {
            _shows = doubanResponse.list;
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
    return _shows.map((show) => show.toVideoInfo()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RecommendationSection(
      title: '热门综艺',
      moreText: '查看更多 >',
      onMoreTap: () {
        // TODO: 实现跳转到综艺列表页面
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
        widget.onShowTap?.call(playRecord);
      },
      isLoading: _isLoading,
      hasError: _hasError,
      onRetry: _loadHotShows,
      cardCount: 2.75,
    );
  }
}
