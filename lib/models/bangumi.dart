import 'play_record.dart';
import 'video_info.dart';

/// Bangumi 评分数据模型
class BangumiRating {
  final int total;
  final Map<String, int> count;
  final double score;

  const BangumiRating({
    required this.total,
    required this.count,
    required this.score,
  });

  factory BangumiRating.fromJson(Map<String, dynamic> json) {
    return BangumiRating(
      total: json['total'] ?? 0,
      count: Map<String, int>.from(json['count'] ?? {}),
      score: (json['score'] ?? 0.0).toDouble(),
    );
  }
}

/// Bangumi 图片数据模型
class BangumiImages {
  final String large;
  final String common;
  final String medium;
  final String small;
  final String grid;

  const BangumiImages({
    required this.large,
    required this.common,
    required this.medium,
    required this.small,
    required this.grid,
  });

  factory BangumiImages.fromJson(Map<String, dynamic> json) {
    return BangumiImages(
      large: json['large']?.toString() ?? '',
      common: json['common']?.toString() ?? '',
      medium: json['medium']?.toString() ?? '',
      small: json['small']?.toString() ?? '',
      grid: json['grid']?.toString() ?? '',
    );
  }

  /// 获取最佳图片URL，优先使用large，其次使用common
  String get bestImageUrl {
    if (large.isNotEmpty) {
      return large;
    } else if (common.isNotEmpty) {
      return common;
    } else if (medium.isNotEmpty) {
      return medium;
    } else if (small.isNotEmpty) {
      return small;
    } else if (grid.isNotEmpty) {
      return grid;
    }
    return '';
  }
}

/// Bangumi 收藏数据模型
class BangumiCollection {
  final int doing;

  const BangumiCollection({
    required this.doing,
  });

  factory BangumiCollection.fromJson(Map<String, dynamic> json) {
    return BangumiCollection(
      doing: json['doing'] ?? 0,
    );
  }
}

/// Bangumi 星期数据模型
class BangumiWeekday {
  final String en;
  final String cn;
  final String ja;
  final int id;

  const BangumiWeekday({
    required this.en,
    required this.cn,
    required this.ja,
    required this.id,
  });

  factory BangumiWeekday.fromJson(Map<String, dynamic> json) {
    return BangumiWeekday(
      en: json['en']?.toString() ?? '',
      cn: json['cn']?.toString() ?? '',
      ja: json['ja']?.toString() ?? '',
      id: json['id'] ?? 0,
    );
  }
}

/// Bangumi 项目数据模型
class BangumiItem {
  final int id;
  final String url;
  final int type;
  final String name;
  final String? nameCn;
  final String summary;
  final String airDate;
  final int airWeekday;
  final BangumiRating rating;
  final int rank;
  final BangumiImages images;
  final BangumiCollection collection;

  const BangumiItem({
    required this.id,
    required this.url,
    required this.type,
    required this.name,
    this.nameCn,
    required this.summary,
    required this.airDate,
    required this.airWeekday,
    required this.rating,
    required this.rank,
    required this.images,
    required this.collection,
  });

  factory BangumiItem.fromJson(Map<String, dynamic> json) {
    return BangumiItem(
      id: json['id'] ?? 0,
      url: json['url']?.toString() ?? '',
      type: json['type'] ?? 0,
      name: json['name']?.toString() ?? '',
      nameCn: json['name_cn']?.toString(),
      summary: json['summary']?.toString() ?? '',
      airDate: json['air_date']?.toString() ?? '',
      airWeekday: json['air_weekday'] ?? 0,
      rating: BangumiRating.fromJson(json['rating'] ?? {}),
      rank: json['rank'] ?? 0,
      images: BangumiImages.fromJson(json['images'] ?? {}),
      collection: BangumiCollection.fromJson(json['collection'] ?? {}),
    );
  }

  /// 转换为PlayRecord格式，用于播放记录
  PlayRecord toPlayRecord() {
    return PlayRecord(
      id: id.toString(),
      source: 'bangumi',
      title: nameCn?.isNotEmpty == true ? nameCn! : name,
      sourceName: 'Bangumi',
      year: airDate.split('-').first,
      cover: images.bestImageUrl,
      index: 1,
      totalEpisodes: 1,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: nameCn?.isNotEmpty == true ? nameCn! : name,
    );
  }

  /// 转换为VideoInfo格式，用于VideoCard显示
  VideoInfo toVideoInfo() {
    return VideoInfo(
      id: id.toString(),
      source: 'bangumi',
      title: nameCn?.isNotEmpty == true ? nameCn! : name,
      sourceName: 'Bangumi',
      year: airDate.split('-').first,
      cover: images.bestImageUrl,
      index: 1,
      totalEpisodes: 1,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: nameCn?.isNotEmpty == true ? nameCn! : name,
      bangumiId: id,
      rate: rating.score > 0 ? rating.score.toStringAsFixed(1) : null,
    );
  }
}

/// Bangumi 日历响应数据模型
class BangumiCalendarResponse {
  final BangumiWeekday weekday;
  final List<BangumiItem> items;

  const BangumiCalendarResponse({
    required this.weekday,
    required this.items,
  });

  factory BangumiCalendarResponse.fromJson(Map<String, dynamic> json) {
    return BangumiCalendarResponse(
      weekday: BangumiWeekday.fromJson(json['weekday'] ?? {}),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => BangumiItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
