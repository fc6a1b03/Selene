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

  /// 获取缓存数据
  T? getCache<T>(String key) {
    return _cache[key] as T?;
  }

  /// 设置缓存数据
  void setCache<T>(String key, T data) {
    _cache[key] = data;
  }

  /// 清除指定缓存
  void clearCache(String key) {
    _cache.remove(key);
  }

  /// 清除所有缓存
  void clearAllCache() {
    _cache.clear();
  }

  /// 获取播放记录
  Future<List<PlayRecord>?> getPlayRecords(BuildContext context) async {
    const cacheKey = 'play_records';
    
    // 先检查缓存
    final cachedData = getCache<List<PlayRecord>>(cacheKey);
    if (cachedData != null) {
      // 有缓存数据，立即返回，同时异步刷新缓存
      _refreshPlayRecordsInBackground(context);
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
      // 有缓存数据，立即返回，同时异步刷新缓存
      _refreshFavoritesInBackground(context);
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
      // 有缓存数据，立即返回，同时异步刷新缓存
      _refreshSearchHistoryInBackground(context);
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

  /// 从缓存中删除指定的播放记录
  void removePlayRecordFromCache(String source, String id) {
    const cacheKey = 'play_records';
    final cachedData = getCache<List<PlayRecord>>(cacheKey);
    
    if (cachedData != null) {
      // 创建新的列表，排除要删除的记录
      final updatedRecords = cachedData.where((record) => 
        !(record.source == source && record.id == id)
      ).toList();
      
      // 更新缓存
      setCache(cacheKey, updatedRecords);
    }
  }

  /// 从缓存中删除指定的收藏项目
  void removeFavoriteFromCache(String source, String id) {
    const cacheKey = 'favorites';
    final cachedData = getCache<List<FavoriteItem>>(cacheKey);
    
    if (cachedData != null) {
      // 创建新的列表，排除要删除的收藏项目
      final updatedFavorites = cachedData.where((favorite) => 
        !(favorite.source == source && favorite.id == id)
      ).toList();
      
      // 更新缓存
      setCache(cacheKey, updatedFavorites);
    }
  }

  /// 向缓存中添加收藏项目
  void addFavoriteToCache(String source, String id, Map<String, dynamic> favoriteData) {
    const cacheKey = 'favorites';
    final cachedData = getCache<List<FavoriteItem>>(cacheKey);
    
    if (cachedData != null) {
      // 检查是否已存在相同的收藏项目
      final existingIndex = cachedData.indexWhere((favorite) => 
        favorite.source == source && favorite.id == id
      );
      
      if (existingIndex == -1) {
        // 不存在，创建新的收藏项目并添加到列表开头
        final newFavorite = FavoriteItem(
          id: id,
          source: source,
          title: favoriteData['title'] ?? '',
          sourceName: favoriteData['source_name'] ?? '',
          year: favoriteData['year'] ?? '',
          cover: favoriteData['cover'] ?? '',
          totalEpisodes: favoriteData['total_episodes'] ?? 0,
          saveTime: favoriteData['save_time'] ?? DateTime.now().millisecondsSinceEpoch,
          origin: '', // 默认为空，表示非直播源
        );
        
        // 添加到列表开头，保持按save_time降序排列
        final updatedFavorites = [newFavorite, ...cachedData];
        setCache(cacheKey, updatedFavorites);
      }
    }
  }

  /// 后台异步刷新播放记录
  void _refreshPlayRecordsInBackground(BuildContext context) {
    // 异步执行，不等待结果
    Future.microtask(() async {
      try {
        await refreshPlayRecords(context);
      } catch (e) {
        // 静默处理错误，不影响主流程
      }
    });
  }

  /// 后台异步刷新收藏夹
  void _refreshFavoritesInBackground(BuildContext context) {
    // 异步执行，不等待结果
    Future.microtask(() async {
      try {
        await refreshFavorites(context);
      } catch (e) {
        // 静默处理错误，不影响主流程
      }
    });
  }

  /// 添加搜索历史到缓存
  void addSearchHistoryToCache(String query) {
    const cacheKey = 'search_history';
    final cachedData = getCache<List<String>>(cacheKey);
    
    if (cachedData != null) {
      // 检查是否已存在相同的搜索词
      if (!cachedData.contains(query)) {
        // 不存在，添加到列表开头
        final updatedHistory = [query, ...cachedData];
        // 限制历史记录数量为10条
        final limitedHistory = updatedHistory.take(10).toList();
        setCache(cacheKey, limitedHistory);
      } else {
        // 已存在，移动到列表开头
        final updatedHistory = [query, ...cachedData.where((item) => item != query).toList()];
        setCache(cacheKey, updatedHistory);
      }
    } else {
      // 没有缓存数据，创建新的历史记录
      setCache(cacheKey, [query]);
    }
  }

  /// 从缓存中删除指定的搜索历史
  void removeSearchHistoryFromCache(String query) {
    const cacheKey = 'search_history';
    final cachedData = getCache<List<String>>(cacheKey);
    
    if (cachedData != null) {
      // 创建新的列表，排除要删除的搜索词
      final updatedHistory = cachedData.where((item) => item != query).toList();
      setCache(cacheKey, updatedHistory);
    }
  }

  /// 后台异步刷新搜索历史
  void _refreshSearchHistoryInBackground(BuildContext context) {
    // 异步执行，不等待结果
    Future.microtask(() async {
      try {
        await refreshSearchHistory(context);
      } catch (e) {
        // 静默处理错误，不影响主流程
      }
    });
  }
}
