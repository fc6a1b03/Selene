import 'play_record.dart';
import 'video_info.dart';

/// 豆瓣电影详情数据模型
class DoubanMovieDetails {
  final String id;
  final String title;
  final String poster;
  final String? rate;
  final String year;
  final String? summary;
  final List<String> genres;
  final List<String> directors;
  final List<String> screenwriters;
  final List<String> actors;
  final String? duration;
  final List<String> countries;
  final List<String> languages;
  final String? releaseDate;
  final String? originalTitle;
  final String? imdbId;

  const DoubanMovieDetails({
    required this.id,
    required this.title,
    required this.poster,
    this.rate,
    required this.year,
    this.summary,
    this.genres = const [],
    this.directors = const [],
    this.screenwriters = const [],
    this.actors = const [],
    this.duration,
    this.countries = const [],
    this.languages = const [],
    this.releaseDate,
    this.originalTitle,
    this.imdbId,
  });

  /// 从JSON创建DoubanMovieDetails实例
  factory DoubanMovieDetails.fromJson(Map<String, dynamic> json) {
    // 处理poster字段
    String poster = '';
    if (json['images'] != null) {
      final images = json['images'] as Map<String, dynamic>?;
      poster = images?['large']?.toString() ?? 
               images?['medium']?.toString() ?? 
               images?['small']?.toString() ?? '';
    } else if (json['pic'] != null) {
      final pic = json['pic'] as Map<String, dynamic>?;
      poster = pic?['normal']?.toString() ?? 
               pic?['large']?.toString() ?? '';
    }
    
    // 处理rating字段
    String? rate;
    if (json['rating'] != null) {
      final rating = json['rating'] as Map<String, dynamic>?;
      final value = rating?['average'] ?? rating?['value'];
      if (value != null) {
        rate = (value as num).toStringAsFixed(1);
      }
    }
    
    // 处理年份
    String year = json['year']?.toString() ?? '';
    if (year.isEmpty && json['pubdate'] != null) {
      final pubdate = json['pubdate']?.toString() ?? '';
      final yearMatch = RegExp(r'(\d{4})').firstMatch(pubdate);
      year = yearMatch?.group(1) ?? '';
    }
    
    // 处理导演列表
    List<String> directors = [];
    if (json['directors'] != null) {
      final directorsData = json['directors'] as List<dynamic>? ?? [];
      directors = directorsData.map((d) => d['name']?.toString() ?? '').toList();
    }
    
    // 处理编剧列表
    List<String> screenwriters = [];
    if (json['screenwriters'] != null) {
      final screenwritersData = json['screenwriters'] as List<dynamic>? ?? [];
      screenwriters = screenwritersData.map((w) => w['name']?.toString() ?? '').toList();
    }
    
    // 处理演员列表
    List<String> actors = [];
    if (json['casts'] != null) {
      final castsData = json['casts'] as List<dynamic>? ?? [];
      actors = castsData.map((c) => c['name']?.toString() ?? '').toList();
    }
    
    // 处理类型列表
    List<String> genres = [];
    if (json['genres'] != null) {
      genres = (json['genres'] as List<dynamic>? ?? [])
          .map((g) => g.toString())
          .toList();
    }
    
    // 处理国家列表
    List<String> countries = [];
    if (json['countries'] != null) {
      countries = (json['countries'] as List<dynamic>? ?? [])
          .map((c) => c.toString())
          .toList();
    }
    
    // 处理语言列表
    List<String> languages = [];
    if (json['languages'] != null) {
      languages = (json['languages'] as List<dynamic>? ?? [])
          .map((l) => l.toString())
          .toList();
    }
    
    return DoubanMovieDetails(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      poster: poster,
      rate: rate,
      year: year,
      summary: json['summary']?.toString(),
      genres: genres,
      directors: directors,
      screenwriters: screenwriters,
      actors: actors,
      duration: json['durations']?.isNotEmpty == true 
          ? json['durations'][0]?.toString() 
          : null,
      countries: countries,
      languages: languages,
      releaseDate: json['pubdate']?.toString(),
      originalTitle: json['original_title']?.toString(),
      imdbId: json['imdb']?.toString(),
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
      'summary': summary,
      'genres': genres,
      'directors': directors,
      'screenwriters': screenwriters,
      'actors': actors,
      'duration': duration,
      'countries': countries,
      'languages': languages,
      'releaseDate': releaseDate,
      'originalTitle': originalTitle,
      'imdbId': imdbId,
    };
  }
}

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
    // 处理poster字段，优先使用normal，其次large
    String poster = '';
    if (json['pic'] != null) {
      final pic = json['pic'] as Map<String, dynamic>?;
      poster = pic?['normal']?.toString() ?? 
               pic?['large']?.toString() ?? '';
    }
    
    // 处理rating字段
    String? rate;
    if (json['rating'] != null) {
      final rating = json['rating'] as Map<String, dynamic>?;
      final value = rating?['value'];
      if (value != null) {
        rate = (value as num).toStringAsFixed(1);
      }
    }
    
    // 处理年份，从card_subtitle中提取
    String year = '';
    if (json['card_subtitle'] != null) {
      final cardSubtitle = json['card_subtitle']?.toString() ?? '';
      final yearMatch = RegExp(r'(\d{4})').firstMatch(cardSubtitle);
      year = yearMatch?.group(1) ?? '';
    }
    
    return DoubanMovie(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      poster: poster,
      rate: rate,
      year: year,
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
  final List<DoubanMovie> items;

  const DoubanResponse({
    required this.items,
  });

  /// 从JSON创建DoubanResponse实例
  factory DoubanResponse.fromJson(Map<String, dynamic> json) {
    final itemsData = json['items'] as List<dynamic>? ?? [];
    
    return DoubanResponse(
      items: itemsData.map((item) {
        return DoubanMovie.fromJson(item as Map<String, dynamic>);
      }).toList(),
    );
  }
}
