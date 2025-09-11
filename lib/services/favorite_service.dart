import 'package:flutter/material.dart';
import '../models/favorite_item.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import 'page_cache_service.dart';

/// 收藏服务
class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  final PageCacheService _cacheService = PageCacheService();

  /// 检查播放记录是否已收藏
  Future<bool> isFavorited(PlayRecord playRecord, BuildContext context) async {
    try {
      final favorites = await _cacheService.getFavorites(context);
      if (favorites == null || favorites.isEmpty) return false;
      
      // 根据 source+id 检查是否在收藏列表中
      final key = '${playRecord.source}+${playRecord.id}';
      return favorites.any((favorite) => '${favorite.source}+${favorite.id}' == key);
    } catch (e) {
      return false;
    }
  }

  /// 检查视频信息是否已收藏
  Future<bool> isFavoritedByVideoInfo(VideoInfo videoInfo, BuildContext context) async {
    try {
      final favorites = await _cacheService.getFavorites(context);
      if (favorites == null || favorites.isEmpty) return false;
      
      // 根据 source+id 检查是否在收藏列表中
      final key = '${videoInfo.source}+${videoInfo.id}';
      return favorites.any((favorite) => '${favorite.source}+${favorite.id}' == key);
    } catch (e) {
      return false;
    }
  }

  /// 检查指定 source+id 是否已收藏
  Future<bool> isFavoritedByKey(String source, String id, BuildContext context) async {
    try {
      final favorites = await _cacheService.getFavorites(context);
      if (favorites == null || favorites.isEmpty) return false;
      
      // 根据 source+id 检查是否在收藏列表中
      final key = '$source+$id';
      return favorites.any((favorite) => '${favorite.source}+${favorite.id}' == key);
    } catch (e) {
      return false;
    }
  }

  /// 同步检查收藏状态（使用缓存）
  bool isFavoritedSync(PlayRecord playRecord) {
    try {
      final favorites = _cacheService.getCache<List<FavoriteItem>>('favorites');
      if (favorites == null || favorites.isEmpty) return false;
      
      // 根据 source+id 检查是否在收藏列表中
      final key = '${playRecord.source}+${playRecord.id}';
      return favorites.any((favorite) => '${favorite.source}+${favorite.id}' == key);
    } catch (e) {
      return false;
    }
  }

  /// 同步检查视频信息收藏状态（使用缓存）
  bool isFavoritedSyncByVideoInfo(VideoInfo videoInfo) {
    try {
      final favorites = _cacheService.getCache<List<FavoriteItem>>('favorites');
      if (favorites == null || favorites.isEmpty) return false;
      
      // 根据 source+id 检查是否在收藏列表中
      final key = '${videoInfo.source}+${videoInfo.id}';
      return favorites.any((favorite) => '${favorite.source}+${favorite.id}' == key);
    } catch (e) {
      return false;
    }
  }
}
