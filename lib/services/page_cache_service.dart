import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/douban_movie.dart';
import '../models/play_record.dart';
import '../models/bangumi.dart';
import '../models/favorite_item.dart';
import 'api_service.dart';
import 'douban_service.dart';
import 'data_operation_interface.dart';

/// 页面缓存服务 - 单例模式
class PageCacheService implements PlayRecordOperationInterface, FavoriteOperationInterface, SearchRecordOperationInterface {
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

  // ==================== PlayRecordOperationInterface 实现 ====================
  
  @override
  Future<DataOperationResult<List<PlayRecord>>> getPlayRecords(BuildContext context) async {
    const cacheKey = 'play_records';
    
    // 先检查缓存
    final cachedData = getCache<List<PlayRecord>>(cacheKey);
    if (cachedData != null) {
      // 有缓存数据，立即返回，同时异步刷新缓存
      refreshPlayRecordsInBackground(context);
      return DataOperationResult.success(cachedData);
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
        return DataOperationResult.success(records);
      }
    } catch (e) {
      return DataOperationResult.error('获取播放记录失败: ${e.toString()}');
    }
    
    return DataOperationResult.error('获取播放记录失败');
  }

  @override
  Future<DataOperationResult<List<PlayRecord>>> refreshPlayRecords(BuildContext context) async {
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
        return DataOperationResult.success(records);
      }
    } catch (e) {
      return DataOperationResult.error('刷新播放记录失败: ${e.toString()}');
    }
    
    return DataOperationResult.error('刷新播放记录失败');
  }

  @override
  Future<DataOperationResult<void>> deletePlayRecord(String source, String id, BuildContext context) async {
    try {
      final response = await ApiService.deletePlayRecord(source, id, context);
      if (response.success) {
        // 从缓存中删除
        removePlayRecordFromCache(source, id);
        return DataOperationResult.success(null);
      } else {
        return DataOperationResult.error(response.message ?? '删除播放记录失败');
      }
    } catch (e) {
      return DataOperationResult.error('删除播放记录异常: ${e.toString()}');
    }
  }

  @override
  Future<bool> isPlayRecordFavorited(PlayRecord playRecord, BuildContext context) async {
    try {
      final favorites = await getFavorites(context);
      if (favorites.success && favorites.data != null && favorites.data!.isNotEmpty) {
        // 根据 source+id 检查是否在收藏列表中
        final key = '${playRecord.source}+${playRecord.id}';
        return favorites.data!.any((favorite) => '${favorite.source}+${favorite.id}' == key);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  bool isPlayRecordFavoritedSync(PlayRecord playRecord) {
    try {
      final favorites = getCachedFavorites();
      if (favorites == null || favorites.isEmpty) return false;
      
      // 根据 source+id 检查是否在收藏列表中
      final key = '${playRecord.source}+${playRecord.id}';
      return favorites.any((favorite) => '${favorite.source}+${favorite.id}' == key);
    } catch (e) {
      return false;
    }
  }

  @override
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

  @override
  List<PlayRecord>? getCachedPlayRecords() {
    return getCache<List<PlayRecord>>('play_records');
  }

  @override
  void refreshPlayRecordsInBackground(BuildContext context) {
    // 异步执行，不等待结果
    Future.microtask(() async {
      try {
        await refreshPlayRecords(context);
      } catch (e) {
        // 静默处理错误，不影响主流程
      }
    });
  }

  // ==================== FavoriteOperationInterface 实现 ====================
  
  @override
  Future<DataOperationResult<List<FavoriteItem>>> getFavorites(BuildContext context) async {
    const cacheKey = 'favorites';
    
    // 先检查缓存
    final cachedData = getCache<List<FavoriteItem>>(cacheKey);
    if (cachedData != null) {
      // 有缓存数据，立即返回，同时异步刷新缓存
      refreshFavoritesInBackground(context);
      // 过滤掉 origin=live 的数据
      final filteredData = cachedData.where((item) => item.origin != 'live').toList();
      return DataOperationResult.success(filteredData);
    }

    // 缓存未命中，从API获取
    try {
      final response = await ApiService.getFavorites(context);

      if (response.success && response.data != null) {
        // 过滤掉 origin=live 的数据
        final filteredData = response.data!.where((item) => item.origin != 'live').toList();
        // 缓存过滤后的数据
        setCache(cacheKey, filteredData);
        return DataOperationResult.success(filteredData);
      }
    } catch (e) {
      return DataOperationResult.error('获取收藏夹失败: ${e.toString()}');
    }
    
    return DataOperationResult.error('获取收藏夹失败');
  }

  @override
  Future<DataOperationResult<List<FavoriteItem>>> refreshFavorites(BuildContext context) async {
    const cacheKey = 'favorites';
    
    try {
      final response = await ApiService.getFavorites(context);

      if (response.success && response.data != null) {
        // 过滤掉 origin=live 的数据
        final filteredData = response.data!.where((item) => item.origin != 'live').toList();
        // 更新缓存数据
        setCache(cacheKey, filteredData);
        return DataOperationResult.success(filteredData);
      }
    } catch (e) {
      return DataOperationResult.error('刷新收藏夹失败: ${e.toString()}');
    }
    
    return DataOperationResult.error('刷新收藏夹失败');
  }

  @override
  Future<DataOperationResult<void>> addFavorite(String source, String id, Map<String, dynamic> favoriteData, BuildContext context) async {
    try {
      final response = await ApiService.favorite(source, id, favoriteData, context);
      if (response.success) {
        // 添加到缓存
        addFavoriteToCache(source, id, favoriteData);
        return DataOperationResult.success(null);
      } else {
        return DataOperationResult.error(response.message ?? '添加收藏失败');
      }
    } catch (e) {
      return DataOperationResult.error('添加收藏异常: ${e.toString()}');
    }
  }

  @override
  Future<DataOperationResult<void>> removeFavorite(String source, String id, BuildContext context) async {
    try {
      final response = await ApiService.unfavorite(source, id, context);
      if (response.success) {
        // 从缓存中删除
        removeFavoriteFromCache(source, id);
        return DataOperationResult.success(null);
      } else {
        return DataOperationResult.error(response.message ?? '取消收藏失败');
      }
    } catch (e) {
      return DataOperationResult.error('取消收藏异常: ${e.toString()}');
    }
  }

  @override
  Future<bool> isFavorited(String source, String id, BuildContext context) async {
    try {
      final favorites = await getFavorites(context);
      if (favorites.success && favorites.data != null && favorites.data!.isNotEmpty) {
        // 根据 source+id 检查是否在收藏列表中
        final key = '$source+$id';
        return favorites.data!.any((favorite) => '${favorite.source}+${favorite.id}' == key);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  bool isFavoritedSync(String source, String id) {
    try {
      final favorites = getCachedFavorites();
      if (favorites == null || favorites.isEmpty) return false;
      
      // 根据 source+id 检查是否在收藏列表中
      final key = '$source+$id';
      return favorites.any((favorite) => '${favorite.source}+${favorite.id}' == key);
    } catch (e) {
      return false;
    }
  }

  @override
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

  @override
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

  @override
  List<FavoriteItem>? getCachedFavorites() {
    return getCache<List<FavoriteItem>>('favorites');
  }

  @override
  void refreshFavoritesInBackground(BuildContext context) {
    // 异步执行，不等待结果
    Future.microtask(() async {
      try {
        await refreshFavorites(context);
      } catch (e) {
        // 静默处理错误，不影响主流程
      }
    });
  }

  // ==================== SearchRecordOperationInterface 实现 ====================
  
  @override
  Future<DataOperationResult<List<String>>> getSearchHistory(BuildContext context) async {
    const cacheKey = 'search_history';
    
    // 先检查缓存
    final cachedData = getCache<List<String>>(cacheKey);
    if (cachedData != null) {
      // 有缓存数据，立即返回，同时异步刷新缓存
      refreshSearchHistoryInBackground(context);
      return DataOperationResult.success(cachedData);
    }

    // 缓存未命中，从API获取
    try {
      final response = await ApiService.getSearchHistory(context);

      if (response.success && response.data != null) {
        // 缓存数据
        setCache(cacheKey, response.data!);
        return DataOperationResult.success(response.data!);
      }
    } catch (e) {
      return DataOperationResult.error('获取搜索历史失败: ${e.toString()}');
    }
    
    return DataOperationResult.error('获取搜索历史失败');
  }

  @override
  Future<DataOperationResult<List<String>>> refreshSearchHistory(BuildContext context) async {
    const cacheKey = 'search_history';
    
    try {
      final response = await ApiService.getSearchHistory(context);

      if (response.success && response.data != null) {
        // 更新缓存数据
        setCache(cacheKey, response.data!);
        return DataOperationResult.success(response.data!);
      }
    } catch (e) {
      return DataOperationResult.error('刷新搜索历史失败: ${e.toString()}');
    }
    
    return DataOperationResult.error('刷新搜索历史失败');
  }

  @override
  Future<DataOperationResult<void>> addSearchHistory(String query, BuildContext context) async {
    try {
      final response = await ApiService.addSearchHistory(query, context);
      if (response.success) {
        // 添加到缓存
        addSearchHistoryToCache(query);
        return DataOperationResult.success(null);
      } else {
        return DataOperationResult.error(response.message ?? '添加搜索历史失败');
      }
    } catch (e) {
      return DataOperationResult.error('添加搜索历史异常: ${e.toString()}');
    }
  }

  @override
  Future<DataOperationResult<void>> deleteSearchHistory(String query, BuildContext context) async {
    try {
      final response = await ApiService.deleteSearchHistory(query, context);
      if (response.success) {
        // 从缓存中删除
        removeSearchHistoryFromCache(query);
        return DataOperationResult.success(null);
      } else {
        return DataOperationResult.error(response.message ?? '删除搜索历史失败');
      }
    } catch (e) {
      return DataOperationResult.error('删除搜索历史异常: ${e.toString()}');
    }
  }

  @override
  Future<DataOperationResult<void>> clearSearchHistory(BuildContext context) async {
    try {
      final response = await ApiService.clearSearchHistory(context);
      if (response.success) {
        // 清空缓存
        clearCache('search_history');
        return DataOperationResult.success(null);
      } else {
        return DataOperationResult.error(response.message ?? '清空搜索历史失败');
      }
    } catch (e) {
      return DataOperationResult.error('清空搜索历史异常: ${e.toString()}');
    }
  }

  @override
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

  @override
  void removeSearchHistoryFromCache(String query) {
    const cacheKey = 'search_history';
    final cachedData = getCache<List<String>>(cacheKey);
    
    if (cachedData != null) {
      // 创建新的列表，排除要删除的搜索词
      final updatedHistory = cachedData.where((item) => item != query).toList();
      setCache(cacheKey, updatedHistory);
    }
  }

  @override
  List<String>? getCachedSearchHistory() {
    return getCache<List<String>>('search_history');
  }

  @override
  void refreshSearchHistoryInBackground(BuildContext context) {
    // 异步执行，不等待结果
    Future.microtask(() async {
      try {
        await refreshSearchHistory(context);
      } catch (e) {
        // 静默处理错误，不影响主流程
      }
    });
  }

  // ==================== 向后兼容方法 ====================

  /// 获取播放记录（保持向后兼容）
  Future<List<PlayRecord>?> getPlayRecordsLegacy(BuildContext context) async {
    final result = await getPlayRecords(context);
    return result.success ? result.data : null;
  }

  /// 刷新播放记录（保持向后兼容）
  Future<List<PlayRecord>?> refreshPlayRecordsLegacy(BuildContext context) async {
    final result = await refreshPlayRecords(context);
    return result.success ? result.data : null;
  }

  /// 获取收藏夹（保持向后兼容）
  Future<List<FavoriteItem>?> getFavoritesLegacy(BuildContext context) async {
    final result = await getFavorites(context);
    return result.success ? result.data : null;
  }

  /// 刷新收藏夹（保持向后兼容）
  Future<List<FavoriteItem>?> refreshFavoritesLegacy(BuildContext context) async {
    final result = await refreshFavorites(context);
    return result.success ? result.data : null;
  }

  /// 获取搜索历史（保持向后兼容）
  Future<List<String>?> getSearchHistoryLegacy(BuildContext context) async {
    final result = await getSearchHistory(context);
    return result.success ? result.data : null;
  }

  /// 刷新搜索历史（保持向后兼容）
  Future<List<String>?> refreshSearchHistoryLegacy(BuildContext context) async {
    final result = await refreshSearchHistory(context);
    return result.success ? result.data : null;
  }

  // ==================== 其他缓存方法 ====================

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
}