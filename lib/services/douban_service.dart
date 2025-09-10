import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/douban_movie.dart';
import 'api_service.dart';

/// 豆瓣数据请求参数
class DoubanRequestParams {
  final String kind;
  final String category;
  final String type;
  final int pageLimit;
  final int pageStart;

  const DoubanRequestParams({
    required this.kind,
    required this.category,
    required this.type,
    this.pageLimit = 20,
    this.pageStart = 0,
  });

  /// 构建查询参数
  Map<String, String> toQueryParams() {
    return {
      'kind': kind,
      'category': category,
      'type': type,
      'pageLimit': pageLimit.toString(),
      'pageStart': pageStart.toString(),
    };
  }
}

/// 豆瓣数据请求服务
class DoubanService {
  /// 获取豆瓣分类数据
  /// 
  /// 参数说明：
  /// - kind: 类型 (movie, tv)
  /// - category: 分类 (热门, tv, show 等)
  /// - type: 子类型 (全部, tv, show 等)
  /// - pageLimit: 每页数量，默认20
  /// - pageStart: 起始页码，默认0
  static Future<ApiResponse<List<DoubanMovie>>> getCategoryData(
    BuildContext context, {
    required String kind,
    required String category,
    required String type,
    int pageLimit = 20,
    int pageStart = 0,
  }) async {
    // 构建新的API URL
    final apiUrl = 'https://m.douban.cmliussss.net/rexxar/api/v2/subject/recent_hot/$kind?start=$pageStart&limit=$pageLimit&category=$category&type=$type';
    

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
          'Referer': 'https://movie.douban.com/',
          'Accept': 'application/json, text/plain, */*',
        },
      ).timeout(const Duration(seconds: 30));


      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          final doubanResponse = DoubanResponse.fromJson(data);
          
          
          return ApiResponse.success(doubanResponse.items, statusCode: response.statusCode);
        } catch (parseError) {
          return ApiResponse.error('豆瓣数据解析失败: ${parseError.toString()}');
        }
      } else {
        return ApiResponse.error(
          '获取豆瓣数据失败: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('豆瓣数据请求异常: ${e.toString()}');
    }
  }

  /// 获取热门电影数据
  static Future<ApiResponse<List<DoubanMovie>>> getHotMovies(
    BuildContext context, {
    int pageLimit = 20,
    int pageStart = 0,
  }) async {
    return getCategoryData(
      context,
      kind: 'movie',
      category: '热门',
      type: '全部',
      pageLimit: pageLimit,
      pageStart: pageStart,
    );
  }

  /// 获取热门剧集数据
  static Future<ApiResponse<List<DoubanMovie>>> getHotTvShows(
    BuildContext context, {
    int pageLimit = 20,
    int pageStart = 0,
  }) async {
    return getCategoryData(
      context,
      kind: 'tv',
      category: 'tv',
      type: 'tv',
      pageLimit: pageLimit,
      pageStart: pageStart,
    );
  }

  /// 获取热门综艺数据
  static Future<ApiResponse<List<DoubanMovie>>> getHotShows(
    BuildContext context, {
    int pageLimit = 20,
    int pageStart = 0,
  }) async {
    return getCategoryData(
      context,
      kind: 'tv',
      category: 'show',
      type: 'show',
      pageLimit: pageLimit,
      pageStart: pageStart,
    );
  }
}
