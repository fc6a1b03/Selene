import 'package:flutter/material.dart';
import '../models/favorite_item.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import 'page_cache_service.dart';

/// 收藏服务 - 使用重构后的 PageCacheService
class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  final PageCacheService _cacheService = PageCacheService();

  /// 检查播放记录是否已收藏
  Future<bool> isFavorited(PlayRecord playRecord, BuildContext context) async {
    return await _cacheService.isPlayRecordFavorited(playRecord, context);
  }

  /// 检查视频信息是否已收藏
  Future<bool> isFavoritedByVideoInfo(VideoInfo videoInfo, BuildContext context) async {
    return await _cacheService.isFavorited(videoInfo.source, videoInfo.id, context);
  }

  /// 检查指定 source+id 是否已收藏
  Future<bool> isFavoritedByKey(String source, String id, BuildContext context) async {
    return await _cacheService.isFavorited(source, id, context);
  }

  /// 同步检查收藏状态（使用缓存）
  bool isFavoritedSync(PlayRecord playRecord) {
    return _cacheService.isPlayRecordFavoritedSync(playRecord);
  }

  /// 同步检查视频信息收藏状态（使用缓存）
  bool isFavoritedSyncByVideoInfo(VideoInfo videoInfo) {
    return _cacheService.isFavoritedSync(videoInfo.source, videoInfo.id);
  }

  /// 添加收藏
  Future<bool> addFavorite(String source, String id, Map<String, dynamic> favoriteData, BuildContext context) async {
    final result = await _cacheService.addFavorite(source, id, favoriteData, context);
    return result.success;
  }

  /// 取消收藏
  Future<bool> removeFavorite(String source, String id, BuildContext context) async {
    final result = await _cacheService.removeFavorite(source, id, context);
    return result.success;
  }

  /// 获取收藏夹
  Future<List<FavoriteItem>?> getFavorites(BuildContext context) async {
    final result = await _cacheService.getFavorites(context);
    return result.success ? result.data : null;
  }

  /// 刷新收藏夹
  Future<List<FavoriteItem>?> refreshFavorites(BuildContext context) async {
    final result = await _cacheService.refreshFavorites(context);
    return result.success ? result.data : null;
  }
}
