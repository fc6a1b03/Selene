import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/douban_movie.dart';
import '../models/play_record.dart';
import '../models/bangumi.dart';
import '../models/favorite_item.dart';
import 'api_service.dart';
import 'douban_service.dart';

/// 页面缓存服务 - 单例模式
class PageCacheService {
  static final PageCacheService _instance = PageCacheService._internal();
  factory PageCacheService() => _instance;
  PageCacheService._internal();

  // 缓存数据
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // 缓存过期时间（5分钟）
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// 检查缓存是否有效
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// 获取缓存数据
  T? getCache<T>(String key) {
    if (_isCacheValid(key)) {
      return _cache[key] as T?;
    }
    return null;
  }

  /// 设置缓存数据
  void setCache<T>(String key, T data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// 清除指定缓存
  void clearCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// 清除所有缓存
  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// 获取播放记录
  Future<List<PlayRecord>?> getPlayRecords(BuildContext context) async {
    const cacheKey = 'play_records';
    
    // 先检查缓存
    final cachedData = getCache<List<PlayRecord>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    // 缓存未命中，从API获取
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        '/api/playrecords',
        context: context,
      );

      if (response.success && response.data != null) {
        final records = <PlayRecord>[];
        
        response.data!.forEach((id, data) {
          try {
            records.add(PlayRecord.fromJson(id, data));
          } catch (e) {
            // 忽略解析失败的记录
          }
        });

        // 按save_time降序排列
        records.sort((a, b) => b.saveTime.compareTo(a.saveTime));

        // 缓存数据
        setCache(cacheKey, records);
        return records;
      }
    } catch (e) {
      // 错误处理
    }
    
    return null;
  }

  /// 刷新播放记录（强制从API获取最新数据）
  Future<List<PlayRecord>?> refreshPlayRecords(BuildContext context) async {
    const cacheKey = 'play_records';
    
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        '/api/playrecords',
        context: context,
      );

      if (response.success && response.data != null) {
        final records = <PlayRecord>[];
        
        response.data!.forEach((id, data) {
          try {
            records.add(PlayRecord.fromJson(id, data));
          } catch (e) {
            // 忽略解析失败的记录
          }
        });

        // 按save_time降序排列
        records.sort((a, b) => b.saveTime.compareTo(a.saveTime));

        // 更新缓存数据
        setCache(cacheKey, records);
        return records;
      }
    } catch (e) {
      // 错误处理
    }
    
    return null;
  }

  /// 获取收藏夹
  Future<List<FavoriteItem>?> getFavorites(BuildContext context) async {
    const cacheKey = 'favorites';
    
    // 先检查缓存
    final cachedData = getCache<List<FavoriteItem>>(cacheKey);
    if (cachedData != null) {
      // 过滤掉 origin=live 的数据
      return cachedData.where((item) => item.origin != 'live').toList();
    }

    // 缓存未命中，从API获取
    try {
      final response = await ApiService.getFavorites(context);

      if (response.success && response.data != null) {
        // 过滤掉 origin=live 的数据
        final filteredData = response.data!.where((item) => item.origin != 'live').toList();
        // 缓存过滤后的数据
        setCache(cacheKey, filteredData);
        return filteredData;
      }
    } catch (e) {
      // 错误处理
    }
    
    return null;
  }

  /// 刷新收藏夹（强制从API获取最新数据）
  Future<List<FavoriteItem>?> refreshFavorites(BuildContext context) async {
    const cacheKey = 'favorites';
    
    try {
      final response = await ApiService.getFavorites(context);

      if (response.success && response.data != null) {
        // 过滤掉 origin=live 的数据
        final filteredData = response.data!.where((item) => item.origin != 'live').toList();
        // 更新缓存数据
        setCache(cacheKey, filteredData);
        return filteredData;
      }
    } catch (e) {
      // 错误处理
    }
    
    return null;
  }

  /// 获取热门电影
  Future<List<DoubanMovie>?> getHotMovies(BuildContext context) async {
    const cacheKey = 'hot_movies';
    
    // 先检查缓存
    final cachedData = getCache<List<DoubanMovie>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    // 缓存未命中，从API获取
    try {
      final response = await DoubanService.getHotMovies(context);

      if (response.success && response.data != null) {
        // 缓存数据
        setCache(cacheKey, response.data!);
        return response.data!;
      }
    } catch (e) {
      // 错误处理
    }
    
    return null;
  }

  /// 获取热门剧集
  Future<List<DoubanMovie>?> getHotTvShows(BuildContext context) async {
    const cacheKey = 'hot_tv_shows';
    
    // 先检查缓存
    final cachedData = getCache<List<DoubanMovie>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    // 缓存未命中，从API获取
    try {
      final response = await DoubanService.getHotTvShows(context);

      if (response.success && response.data != null) {
        // 缓存数据
        setCache(cacheKey, response.data!);
        return response.data!;
      }
    } catch (e) {
      // 错误处理
    }
    
    return null;
  }

  /// 获取新番放送数据
  Future<List<BangumiItem>?> getBangumiCalendar(BuildContext context) async {
    const cacheKey = 'bangumi_calendar';
    
    // 先检查缓存
    final cachedData = getCache<List<BangumiItem>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    // 缓存未命中，从API获取
    try {
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
        final List<dynamic> responseData = json.decode(response.body);
        
        // 解析所有星期数据
        final List<BangumiCalendarResponse> calendarData = responseData
            .map((item) => BangumiCalendarResponse.fromJson(item as Map<String, dynamic>))
            .toList();
        
        // 获取当前星期几的数据
        final now = DateTime.now();
        final currentWeekday = now.weekday;
        BangumiCalendarResponse? currentDayData;
        
        for (final dayData in calendarData) {
          if (dayData.weekday.id == currentWeekday) {
            currentDayData = dayData;
            break;
          }
        }

        if (currentDayData != null) {
          // 缓存数据
          setCache(cacheKey, currentDayData.items);
          return currentDayData.items;
        }
      }
    } catch (e) {
      // 错误处理
    }
    
    return null;
  }

  /// 获取热门综艺数据
  Future<List<DoubanMovie>?> getHotShows(BuildContext context) async {
    const cacheKey = 'hot_shows';
    
    // 先检查缓存
    final cachedData = getCache<List<DoubanMovie>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    // 缓存未命中，从API获取
    try {
      final response = await DoubanService.getHotShows(context);

      if (response.success && response.data != null) {
        // 缓存数据
        setCache(cacheKey, response.data!);
        return response.data!;
      }
    } catch (e) {
      // 错误处理
    }
    
    return null;
  }

  /// 获取搜索历史
  Future<List<String>?> getSearchHistory(BuildContext context) async {
    const cacheKey = 'search_history';
    
    // 先检查缓存
    final cachedData = getCache<List<String>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    // 缓存未命中，从API获取
    try {
      final response = await ApiService.getSearchHistory(context);

      if (response.success && response.data != null) {
        // 缓存数据
        setCache(cacheKey, response.data!);
        return response.data!;
      }
    } catch (e) {
      // 错误处理
    }
    
    return null;
  }

  /// 刷新搜索历史（强制从API获取最新数据）
  Future<List<String>?> refreshSearchHistory(BuildContext context) async {
    const cacheKey = 'search_history';
    
    try {
      final response = await ApiService.getSearchHistory(context);

      if (response.success && response.data != null) {
        // 更新缓存数据
        setCache(cacheKey, response.data!);
        return response.data!;
      }
    } catch (e) {
      // 错误处理
    }
    
    return null;
  }
}
