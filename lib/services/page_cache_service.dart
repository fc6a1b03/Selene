import 'package:flutter/material.dart';
import '../models/douban_movie.dart';
import '../models/play_record.dart';
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
      // 有缓存数据，直接返回
      return DataOperationResult.success(cachedData);
    }

    // 缓存未命中，直接走接口并保存到缓存
    return await getPlayRecordsDirect(context);
  }

  /// 直接走接口并保存到缓存
  Future<DataOperationResult<List<PlayRecord>>> getPlayRecordsDirect(BuildContext context) async {
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
  Future<void> refreshPlayRecords(BuildContext context) async {
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
      }
    } catch (e) {
      // 静默处理错误，不影响主流程
    }
  }

  @override
  Future<DataOperationResult<void>> deletePlayRecord(String source, String id, BuildContext context) async {
    // 优先操作缓存
    _removePlayRecordFromCache(source, id);
    
    try {
      final response = await ApiService.deletePlayRecord(source, id, context);
      if (response.success) {
        return DataOperationResult.success(null);
      } else {
        return DataOperationResult.error(response.message ?? '删除播放记录失败');
      }
    } catch (e) {
      return DataOperationResult.error('删除播放记录异常: ${e.toString()}');
    }
  }


  void _removePlayRecordFromCache(String source, String id) {
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
  void refreshPlayRecordsInBackground(BuildContext context) {
    // 按需调用时手动刷新；默认不做异步刷新
  }

  // ==================== FavoriteOperationInterface 实现 ====================
  
  @override
  Future<DataOperationResult<List<FavoriteItem>>> getFavorites(BuildContext context) async {
    const cacheKey = 'favorites';
    
    // 先检查缓存
    final cachedData = getCache<List<FavoriteItem>>(cacheKey);
    if (cachedData != null) {
      // 有缓存数据，直接返回
      // 过滤掉 origin=live 的数据
      final filteredData = cachedData.where((item) => item.origin != 'live').toList();
      return DataOperationResult.success(filteredData);
    }

    // 缓存未命中，直接走接口并保存到缓存
    return await getFavoritesDirect(context);
  }

  /// 直接走接口并保存到缓存
  Future<DataOperationResult<List<FavoriteItem>>> getFavoritesDirect(BuildContext context) async {
    const cacheKey = 'favorites';
    
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
  Future<void> refreshFavorites(BuildContext context) async {
    const cacheKey = 'favorites';
    
    try {
      final response = await ApiService.getFavorites(context);

      if (response.success && response.data != null) {
        // 过滤掉 origin=live 的数据
        final filteredData = response.data!.where((item) => item.origin != 'live').toList();
        // 更新缓存数据
        setCache(cacheKey, filteredData);
      }
    } catch (e) {
      // 静默处理错误，不影响主流程
    }
  }

  @override
  Future<DataOperationResult<void>> addFavorite(String source, String id, Map<String, dynamic> favoriteData, BuildContext context) async {
    // 优先操作缓存
    _addFavoriteToCache(source, id, favoriteData);
    
    try {
      final response = await ApiService.favorite(source, id, favoriteData, context);
      if (response.success) {
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
    // 优先操作缓存
    _removeFavoriteFromCache(source, id);
    
    try {
      final response = await ApiService.unfavorite(source, id, context);
      if (response.success) {
        return DataOperationResult.success(null);
      } else {
        return DataOperationResult.error(response.message ?? '取消收藏失败');
      }
    } catch (e) {
      return DataOperationResult.error('取消收藏异常: ${e.toString()}');
    }
  }


  @override
  bool isFavoritedSync(String source, String id) {
    try {
      final favorites = _getCachedFavorites();
      if (favorites == null || favorites.isEmpty) return false;
      
      // 根据 source+id 检查是否在收藏列表中
      final key = '$source+$id';
      return favorites.any((favorite) => '${favorite.source}+${favorite.id}' == key);
    } catch (e) {
      return false;
    }
  }

  void _removeFavoriteFromCache(String source, String id) {
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

  void _addFavoriteToCache(String source, String id, Map<String, dynamic> favoriteData) {
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

  List<FavoriteItem>? _getCachedFavorites() {
    return getCache<List<FavoriteItem>>('favorites');
  }

  @override
  void refreshFavoritesInBackground(BuildContext context) {
    // 按需调用时手动刷新；默认不做异步刷新
  }

  // ==================== SearchRecordOperationInterface 实现 ====================
  
  @override
  Future<DataOperationResult<List<String>>> getSearchHistory(BuildContext context) async {
    const cacheKey = 'search_history';
    
    // 先检查缓存
    final cachedData = getCache<List<String>>(cacheKey);
    if (cachedData != null) {
      // 有缓存数据，直接返回
      return DataOperationResult.success(cachedData);
    }

    // 缓存未命中，直接走接口并保存到缓存
    return await getSearchHistoryDirect(context);
  }

  /// 直接走接口并保存到缓存
  Future<DataOperationResult<List<String>>> getSearchHistoryDirect(BuildContext context) async {
    const cacheKey = 'search_history';
    
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
  Future<void> refreshSearchHistory(BuildContext context) async {
    const cacheKey = 'search_history';
    
    try {
      final response = await ApiService.getSearchHistory(context);

      if (response.success && response.data != null) {
        // 更新缓存数据
        setCache(cacheKey, response.data!);
      }
    } catch (e) {
      // 静默处理错误，不影响主流程
    }
  }

  @override
  Future<DataOperationResult<void>> addSearchHistory(String query, BuildContext context) async {
    // 优先操作缓存
    const cacheKey = 'search_history';
    final cachedData = getCache<List<String>>(cacheKey);
    
    if (cachedData != null) {
      // 检查是否已存在相同的搜索词（区分大小写）
      final existingIndex = cachedData.indexWhere((item) => item == query);
      
      if (existingIndex == -1) {
        // 不存在，添加到列表开头
        final updatedHistory = [query, ...cachedData];
        setCache(cacheKey, updatedHistory);
      } else {
        // 已存在，移动到列表开头（保持原始大小写）
        final existingItem = cachedData[existingIndex];
        final updatedHistory = [existingItem, ...cachedData.where((item) => item != query).toList()];
        setCache(cacheKey, updatedHistory);
      }
    } else {
      // 没有缓存数据，创建新的历史记录
      setCache(cacheKey, [query]);
    }
    
    try {
      final response = await ApiService.addSearchHistory(query, context);
      if (response.success) {
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
    // 优先操作缓存
    const cacheKey = 'search_history';
    final cachedData = getCache<List<String>>(cacheKey);
    
    if (cachedData != null) {
      // 创建新的列表，排除要删除的搜索词
      final updatedHistory = cachedData.where((item) => item != query).toList();
      setCache(cacheKey, updatedHistory);
    }
    
    try {
      final response = await ApiService.deleteSearchHistory(query, context);
      if (response.success) {
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
    // 优先操作缓存
    clearCache('search_history');
    
    try {
      final response = await ApiService.clearSearchHistory(context);
      if (response.success) {
        return DataOperationResult.success(null);
      } else {
        return DataOperationResult.error(response.message ?? '清空搜索历史失败');
      }
    } catch (e) {
      return DataOperationResult.error('清空搜索历史异常: ${e.toString()}');
    }
  }


  @override
  void refreshSearchHistoryInBackground(BuildContext context) {
    // 按需调用时手动刷新；默认不做异步刷新
  }


  // ==================== 其他缓存方法 ====================

  /// 获取热门电影（优先走缓存并异步刷新）
  Future<List<DoubanMovie>?> getHotMovies(BuildContext context) async {
    const cacheKey = 'hot_movies';
    
    // 先检查缓存
    final cachedData = getCache<List<DoubanMovie>>(cacheKey);
    if (cachedData != null) {
      // 有缓存数据，直接返回
      return cachedData;
    }

    // 缓存未命中，直接走接口并保存到缓存
    return await getHotMoviesDirect(context);
  }

  /// 直接走接口并保存到缓存
  Future<List<DoubanMovie>?> getHotMoviesDirect(BuildContext context) async {
    const cacheKey = 'hot_movies';
    
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

  /// 异步刷新热门电影缓存
  void refreshHotMoviesInBackground(BuildContext context) {
    // 移除异步刷新行为
  }

  /// 获取热门剧集（优先走缓存并异步刷新）
  Future<List<DoubanMovie>?> getHotTvShows(BuildContext context) async {
    const cacheKey = 'hot_tv_shows';
    
    // 先检查缓存
    final cachedData = getCache<List<DoubanMovie>>(cacheKey);
    if (cachedData != null) {
      // 有缓存数据，直接返回
      return cachedData;
    }

    // 缓存未命中，直接走接口并保存到缓存
    return await getHotTvShowsDirect(context);
  }

  /// 直接走接口并保存到缓存
  Future<List<DoubanMovie>?> getHotTvShowsDirect(BuildContext context) async {
    const cacheKey = 'hot_tv_shows';
    
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

  /// 异步刷新热门剧集缓存
  void refreshHotTvShowsInBackground(BuildContext context) {
    // 移除异步刷新行为
  }

  // 移除 Bangumi 的页面级缓存逻辑，改由 BangumiService 负责

  /// 获取热门综艺数据（优先走缓存并异步刷新）
  Future<List<DoubanMovie>?> getHotShows(BuildContext context) async {
    const cacheKey = 'hot_shows';
    
    // 先检查缓存
    final cachedData = getCache<List<DoubanMovie>>(cacheKey);
    if (cachedData != null) {
      // 有缓存数据，直接返回
      return cachedData;
    }

    // 缓存未命中，直接走接口并保存到缓存
    return await getHotShowsDirect(context);
  }

  /// 直接走接口并保存到缓存
  Future<List<DoubanMovie>?> getHotShowsDirect(BuildContext context) async {
    const cacheKey = 'hot_shows';
    
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

  /// 异步刷新热门综艺缓存
  void refreshHotShowsInBackground(BuildContext context) {
    // 移除异步刷新行为
  }
}