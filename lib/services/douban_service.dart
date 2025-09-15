import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/douban_movie.dart';
import 'api_service.dart';

/// 豆瓣推荐数据请求参数
class DoubanRecommendsParams {
  final String kind;
  final String category;
  final String format;
  final String region;
  final String year;
  final String platform;
  final String sort;
  final String label;
  final int pageLimit;
  final int page;

  const DoubanRecommendsParams({
    required this.kind,
    this.category = 'all',
    this.format = 'all',
    this.region = 'all',
    this.year = 'all',
    this.platform = 'all',
    this.sort = 'T',
    this.label = 'all',
    this.pageLimit = 20,
    this.page = 0,
  });
}

/// 豆瓣数据请求参数（保持向后兼容）
class DoubanRequestParams {
  final String kind;
  final String category;
  final String type;
  final int pageLimit;
  final int page;

  const DoubanRequestParams({
    required this.kind,
    required this.category,
    required this.type,
    this.pageLimit = 20,
    this.page = 0,
  });

  /// 构建查询参数
  Map<String, String> toQueryParams() {
    return {
      'kind': kind,
      'category': category,
      'type': type,
      'pageLimit': pageLimit.toString(),
      'page': page.toString(),
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
  /// - page: 起始页码，默认0
  static Future<ApiResponse<List<DoubanMovie>>> getCategoryData(
    BuildContext context, {
    required String kind,
    required String category,
    required String type,
    int pageLimit = 20,
    int page = 0,
  }) async {
    // 构建新的API URL
    final apiUrl = 'https://m.douban.cmliussss.net/rexxar/api/v2/subject/recent_hot/$kind?start=${page * pageLimit}&limit=$pageLimit&category=$category&type=$type';
    
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
    int page = 0,
  }) async {
    return getCategoryData(
      context,
      kind: 'movie',
      category: '热门',
      type: '全部',
      pageLimit: pageLimit,
      page: page,
    );
  }

  /// 获取热门剧集数据
  static Future<ApiResponse<List<DoubanMovie>>> getHotTvShows(
    BuildContext context, {
    int pageLimit = 20,
    int page = 0,
  }) async {
    return getCategoryData(
      context,
      kind: 'tv',
      category: 'tv',
      type: 'tv',
      pageLimit: pageLimit,
      page: page,
    );
  }

  /// 获取热门综艺数据
  static Future<ApiResponse<List<DoubanMovie>>> getHotShows(
    BuildContext context, {
    int pageLimit = 20,
    int page = 0,
  }) async {
    return getCategoryData(
      context,
      kind: 'tv',
      category: 'show',
      type: 'show',
      pageLimit: pageLimit,
      page: page,
    );
  }

  /// 获取豆瓣推荐数据（新版筛选逻辑）
  static Future<ApiResponse<List<DoubanMovie>>> fetchDoubanRecommends(
    BuildContext context,
    DoubanRecommendsParams params, {
    String proxyUrl = '',
    bool useTencentCDN = false,
    bool useAliCDN = false,
  }) async {
    // 处理筛选参数，将 'all' 转换为空字符串
    String category = params.category == 'all' ? '' : params.category;
    String format = params.format == 'all' ? '' : params.format;
    String region = params.region == 'all' ? '' : params.region;
    String year = params.year == 'all' ? '' : params.year;
    String platform = params.platform == 'all' ? '' : params.platform;
    String label = params.label == 'all' ? '' : params.label;
    String sort = params.sort == 'T' ? '' : params.sort;

    // 构建 selected_categories
    Map<String, dynamic> selectedCategories = {'类型': category};
    if (format.isNotEmpty) {
      selectedCategories['形式'] = format;
    }
    if (region.isNotEmpty) {
      selectedCategories['地区'] = region;
    }

    // 构建 tags 数组
    List<String> tags = [];
    if (category.isNotEmpty) {
      tags.add(category);
    }
    if (category.isEmpty && format.isNotEmpty) {
      tags.add(format);
    }
    if (label.isNotEmpty) {
      tags.add(label);
    }
    if (region.isNotEmpty) {
      tags.add(region);
    }
    if (year.isNotEmpty) {
      tags.add(year);
    }
    if (platform.isNotEmpty) {
      tags.add(platform);
    }

    // 构建API URL
    final baseUrl = 'https://m.douban.cmliussss.net/rexxar/api/v2/${params.kind}/recommend';
    
    // 构建查询参数
    final queryParams = <String, String>{
      'refresh': '0',
      'start': (params.page * params.pageLimit).toString(),
      'count': params.pageLimit.toString(),
      'selected_categories': json.encode(selectedCategories),
      'uncollect': 'false',
      'score_range': '0,10',
      'tags': tags.join(','),
    };
    
    if (sort.isNotEmpty) {
      queryParams['sort'] = sort;
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    final target = uri.toString();

    try {
      final response = await http.get(
        Uri.parse(target),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
          'Referer': 'https://movie.douban.com/',
          'Accept': 'application/json, text/plain, */*',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          
          // 过滤并转换数据
          final itemsData = data['items'] as List<dynamic>? ?? [];
          final filteredItems = itemsData
              .where((item) => item['type'] == 'movie' || item['type'] == 'tv')
              .map((item) => DoubanMovie.fromJson(item as Map<String, dynamic>))
              .toList();

          return ApiResponse.success(filteredItems, statusCode: response.statusCode);
        } catch (parseError) {
          return ApiResponse.error('豆瓣推荐数据解析失败: ${parseError.toString()}');
        }
      } else {
        return ApiResponse.error(
          '获取豆瓣推荐数据失败: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('豆瓣推荐数据请求异常: ${e.toString()}');
    }
  }
}
