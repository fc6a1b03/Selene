import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/bangumi.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import 'recommendation_section.dart';

/// 新番放送组件
class BangumiSection extends StatefulWidget {
  final Function(PlayRecord)? onBangumiTap;

  const BangumiSection({
    super.key,
    this.onBangumiTap,
  });

  @override
  State<BangumiSection> createState() => _BangumiSectionState();
}

class _BangumiSectionState extends State<BangumiSection> {
  List<BangumiItem> _bangumiItems = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadBangumiCalendar();
  }

  /// 获取当前星期几
  int _getCurrentWeekday() {
    final now = DateTime.now();
    // 返回1-7，1为星期一，7为星期日
    return now.weekday;
  }

  /// 加载新番放送数据
  Future<void> _loadBangumiCalendar() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      const apiUrl = 'https://api.bgm.tv/calendar';
      final headers = {
        'User-Agent': 'senshinya/selene/1.0.0 (Android) (http://github.com/senshinya/selene)',
        'Accept': 'application/json',
      };

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          // 解析JSON响应
          final List<dynamic> responseData = json.decode(response.body);
          
          // 解析所有星期数据
          final List<BangumiCalendarResponse> calendarData = responseData
              .map((item) => BangumiCalendarResponse.fromJson(item as Map<String, dynamic>))
              .toList();
          
          // 获取当前星期几的数据
          final currentWeekday = _getCurrentWeekday();
          BangumiCalendarResponse? currentDayData;
          
          for (final dayData in calendarData) {
            if (dayData.weekday.id == currentWeekday) {
              currentDayData = dayData;
              break;
            }
          }

          if (currentDayData != null) {
            setState(() {
              _bangumiItems = currentDayData!.items;
              _isLoading = false;
            });
          } else {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          }
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
      onMoreTap: () {
        // TODO: 实现跳转到新番列表页面
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
        widget.onBangumiTap?.call(playRecord);
      },
      isLoading: _isLoading,
      hasError: _hasError,
      onRetry: _loadBangumiCalendar,
      cardCount: 2.75,
    );
  }
}
