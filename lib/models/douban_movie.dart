import 'play_record.dart';
import 'video_info.dart';

/// 豆瓣电影数据模型
class DoubanMovie {
  final String id;
  final String title;
  final String poster;
  final String? rate;
  final String year;

  const DoubanMovie({
    required this.id,
    required this.title,
    required this.poster,
    this.rate,
    required this.year,
  });

  /// 从JSON创建DoubanMovie实例
  factory DoubanMovie.fromJson(Map<String, dynamic> json) {
    return DoubanMovie(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      poster: json['poster']?.toString() ?? '',
      rate: json['rate']?.toString(),
      year: json['year']?.toString() ?? '',
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster': poster,
      'rate': rate,
      'year': year,
    };
  }

  /// 转换为PlayRecord格式，用于播放记录
  PlayRecord toPlayRecord() {
    return PlayRecord(
      id: id,
      source: 'douban',
      title: title,
      sourceName: '豆瓣',
      year: year,
      cover: poster,
      index: 1,
      totalEpisodes: 1,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: title,
    );
  }

  /// 转换为VideoInfo格式，用于VideoCard显示
  VideoInfo toVideoInfo() {
    return VideoInfo(
      id: id,
      source: 'douban',
      title: title,
      sourceName: '豆瓣',
      year: year,
      cover: poster,
      index: 1,
      totalEpisodes: 1,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: title,
      doubanId: id,
      rate: rate,
    );
  }
}

/// 豆瓣API响应模型
class DoubanResponse {
  final int code;
  final String message;
  final List<DoubanMovie> list;

  const DoubanResponse({
    required this.code,
    required this.message,
    required this.list,
  });

  /// 从JSON创建DoubanResponse实例
  factory DoubanResponse.fromJson(Map<String, dynamic> json) {
    // 直接使用根级别数据，结构为: {code, message, list}
    final code = json['code'] ?? 0;
    final message = json['message']?.toString() ?? '';
    final listData = json['list'] as List<dynamic>? ?? [];
    
    return DoubanResponse(
      code: code,
      message: message,
      list: listData.map((item) {
        return DoubanMovie.fromJson(item as Map<String, dynamic>);
      }).toList(),
    );
  }
}
