import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/bangumi.dart';
import 'api_service.dart';
import 'douban_cache_service.dart';

/// Bangumi 数据服务（函数级缓存，一天过期）
class BangumiService {
  static final DoubanCacheService _cache = DoubanCacheService();
  static bool _initialized = false;

  static Future<void> _initCache() async {
    if (!_initialized) {
      await _cache.init();
      _initialized = true;
    }
  }

  /// 获取当天的新番放送（根据当前星期几）
  static Future<ApiResponse<List<BangumiItem>>> getTodayCalendar(
    BuildContext context,
  ) async {
    final weekday = DateTime.now().weekday; // 1..7
    return getCalendarByWeekday(context, weekday);
  }

  /// 获取指定星期的新番放送
  static Future<ApiResponse<List<BangumiItem>>> getCalendarByWeekday(
    BuildContext context,
    int weekday, // 1..7 (Monday..Sunday)
  ) async {
    await _initCache();

    // 接口级缓存：缓存原始 API 数组，固定键，不含参数
    const cacheKey = 'bangumi_calendar_raw_v1';

    // 先尝试读取原始数组缓存
    try {
      final cachedRaw = await _cache.get<List<dynamic>>(
        cacheKey,
        (raw) => raw as List<dynamic>,
      );
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        final calendar = cachedRaw
            .map((item) => BangumiCalendarResponse.fromJson(item as Map<String, dynamic>))
            .toList();
        BangumiCalendarResponse? targetDay;
        for (final day in calendar) {
          if (day.weekday.id == weekday) {
            targetDay = day;
            break;
          }
        }
        final items = targetDay?.items ?? <BangumiItem>[];
        return ApiResponse.success(items);
      }
    } catch (_) {}

    // 未命中缓存，请求接口
    try {
      const apiUrl = 'https://api.bgm.tv/calendar';
      final headers = {
        'User-Agent': 'senshinya/selene/1.0.0 (Android) (http://github.com/senshinya/selene)',
        'Accept': 'application/json',
      };

      final response = await http
          .get(Uri.parse(apiUrl), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        // 解析所有星期数据
        final List<BangumiCalendarResponse> calendarData = responseData
            .map((item) => BangumiCalendarResponse.fromJson(item as Map<String, dynamic>))
            .toList();

        BangumiCalendarResponse? targetDay;
        for (final day in calendarData) {
          if (day.weekday.id == weekday) {
            targetDay = day;
            break;
          }
        }

        final items = targetDay?.items ?? <BangumiItem>[];

        // 写入接口级缓存：原始数组
        try {
          await _cache.set(
            cacheKey,
            responseData,
            const Duration(days: 1),
          );
        } catch (_) {}

        return ApiResponse.success(items, statusCode: response.statusCode);
      } else {
        return ApiResponse.error(
          '获取 Bangumi 日历失败: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Bangumi 数据请求异常: ${e.toString()}');
    }
  }
}


