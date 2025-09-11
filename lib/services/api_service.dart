import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'user_data_service.dart';
import '../screens/login_screen.dart';
import '../models/favorite_item.dart';

/// API响应结果类
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {int? statusCode}) {
    return ApiResponse<T>(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

/// 通用API请求服务
class ApiService {
  static const Duration _timeout = Duration(seconds: 30);
  
  /// 获取基础URL
  static Future<String?> _getBaseUrl() async {
    return await UserDataService.getServerUrl();
  }

  /// 获取认证cookies
  static Future<String?> _getCookies() async {
    return await UserDataService.getCookies();
  }

  /// 构建完整URL
  static Future<String> _buildUrl(String endpoint) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) {
      throw Exception('服务器地址未配置，请先登录');
    }
    
    // 确保baseUrl不以/结尾，endpoint以/开头
    String cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    String cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    
    return '$cleanBaseUrl$cleanEndpoint';
  }

  /// 构建请求头
  static Future<Map<String, String>> _buildHeaders({
    Map<String, String>? additionalHeaders,
    bool includeAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // 添加认证cookies
    if (includeAuth) {
      final cookies = await _getCookies();
      if (cookies != null && cookies.isNotEmpty) {
        headers['Cookie'] = cookies;
      }
    }

    // 添加额外头部
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// 处理响应
  static Future<ApiResponse<T>> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  ) async {
    // 处理401未授权
    if (response.statusCode == 401) {
      // 清除用户数据
      await UserDataService.clearUserData();
      
      // 跳转到登录页
      if (context != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
      
      return ApiResponse.error(
        '登录已过期，请重新登录',
        statusCode: 401,
      );
    }

    // 处理其他错误状态码
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String errorMessage = '请求失败';
      try {
        final errorData = json.decode(response.body);
        errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
      } catch (e) {
        // 如果解析失败，使用默认错误信息
        switch (response.statusCode) {
          case 400:
            errorMessage = '请求参数错误';
            break;
          case 403:
            errorMessage = '没有权限访问';
            break;
          case 404:
            errorMessage = '请求的资源不存在';
            break;
          case 500:
            errorMessage = '服务器内部错误';
            break;
          default:
            errorMessage = '网络请求失败 (${response.statusCode})';
        }
      }
      
      return ApiResponse.error(
        errorMessage,
        statusCode: response.statusCode,
      );
    }

    // 处理成功响应
    try {
      final responseData = json.decode(response.body);
      
      if (fromJson != null) {
        final data = fromJson(responseData);
        return ApiResponse.success(data, statusCode: response.statusCode);
      } else {
        return ApiResponse.success(responseData as T, statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error(
        '响应数据解析失败: ${e.toString()}',
        statusCode: response.statusCode,
      );
    }
  }

  /// GET请求
  static Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  }) async {
    try {
      String url = await _buildUrl(endpoint);
      
      // 添加查询参数
      if (queryParameters != null && queryParameters.isNotEmpty) {
        final uri = Uri.parse(url);
        final newUri = uri.replace(queryParameters: queryParameters);
        url = newUri.toString();
      }

      final requestHeaders = await _buildHeaders(additionalHeaders: headers);
      
      final response = await http.get(
        Uri.parse(url),
        headers: requestHeaders,
      ).timeout(_timeout);

      return await _handleResponse(response, fromJson, context);
    } catch (e) {
      return ApiResponse.error('网络请求异常: ${e.toString()}');
    }
  }

  /// POST请求
  static Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  }) async {
    try {
      final url = await _buildUrl(endpoint);
      final requestHeaders = await _buildHeaders(additionalHeaders: headers);
      
      final response = await http.post(
        Uri.parse(url),
        headers: requestHeaders,
        body: body != null ? json.encode(body) : null,
      ).timeout(_timeout);

      return await _handleResponse(response, fromJson, context);
    } catch (e) {
      return ApiResponse.error('网络请求异常: ${e.toString()}');
    }
  }

  /// PUT请求
  static Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  }) async {
    try {
      final url = await _buildUrl(endpoint);
      final requestHeaders = await _buildHeaders(additionalHeaders: headers);
      
      final response = await http.put(
        Uri.parse(url),
        headers: requestHeaders,
        body: body != null ? json.encode(body) : null,
      ).timeout(_timeout);

      return await _handleResponse(response, fromJson, context);
    } catch (e) {
      return ApiResponse.error('网络请求异常: ${e.toString()}');
    }
  }

  /// DELETE请求
  static Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  }) async {
    try {
      final url = await _buildUrl(endpoint);
      final requestHeaders = await _buildHeaders(additionalHeaders: headers);
      
      final response = await http.delete(
        Uri.parse(url),
        headers: requestHeaders,
      ).timeout(_timeout);

      return await _handleResponse(response, fromJson, context);
    } catch (e) {
      return ApiResponse.error('网络请求异常: ${e.toString()}');
    }
  }

  /// 上传文件请求
  static Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    String filePath, {
    Map<String, String>? fields,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  }) async {
    try {
      final url = await _buildUrl(endpoint);
      final requestHeaders = await _buildHeaders(
        additionalHeaders: headers,
        includeAuth: true,
      );
      
      // 移除Content-Type，让http包自动设置multipart的Content-Type
      requestHeaders.remove('Content-Type');
      
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(requestHeaders);
      
      // 添加文件
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      // 添加其他字段
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      return await _handleResponse(response, fromJson, context);
    } catch (e) {
      return ApiResponse.error('文件上传异常: ${e.toString()}');
    }
  }

  /// 获取收藏夹列表
  static Future<ApiResponse<List<FavoriteItem>>> getFavorites(BuildContext context) async {
    try {
      final baseUrl = await _getBaseUrl();
      if (baseUrl == null) {
        return ApiResponse.error('服务器地址未配置');
      }

      final cookies = await _getCookies();
      if (cookies == null) {
        return ApiResponse.error('用户未登录');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/favorites'),
        headers: {
          'Accept': 'application/json',
          'Cookie': cookies,
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<FavoriteItem> favorites = [];
        
        // 将Map转换为List并按save_time降序排序
        data.forEach((id, itemData) {
          favorites.add(FavoriteItem.fromJson(id, itemData));
        });
        
        // 按save_time降序排序
        favorites.sort((a, b) => b.saveTime.compareTo(a.saveTime));
        
        return ApiResponse.success(favorites, statusCode: response.statusCode);
      } else if (response.statusCode == 401) {
        // 未授权，跳转到登录页面
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return ApiResponse.error('登录已过期，请重新登录', statusCode: response.statusCode);
      } else {
        return ApiResponse.error('获取收藏夹失败: ${response.statusCode}', statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('获取收藏夹异常: ${e.toString()}');
    }
  }

  /// 获取搜索历史
  static Future<ApiResponse<List<String>>> getSearchHistory(BuildContext context) async {
    try {
      final response = await get<List<String>>(
        '/api/searchhistory',
        context: context,
        fromJson: (data) => (data as List).cast<String>(),
      );
      
      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!, statusCode: response.statusCode);
      } else {
        return ApiResponse.error(response.message ?? '获取搜索历史失败');
      }
    } catch (e) {
      return ApiResponse.error('获取搜索历史异常: ${e.toString()}');
    }
  }

  /// 添加搜索历史
  static Future<ApiResponse<void>> addSearchHistory(String query, BuildContext context) async {
    try {
      final response = await post<void>(
        '/api/searchhistory',
        context: context,
        body: {'keyword': query},
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('添加搜索历史异常: ${e.toString()}');
    }
  }

  /// 清空搜索历史
  static Future<ApiResponse<void>> clearSearchHistory(BuildContext context) async {
    try {
      final response = await delete<void>(
        '/api/searchhistory',
        context: context,
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('清空搜索历史异常: ${e.toString()}');
    }
  }

  /// 删除单个搜索历史
  static Future<ApiResponse<void>> deleteSearchHistory(String query, BuildContext context) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final response = await delete<void>(
        '/api/searchhistory?keyword=$encodedQuery',
        context: context,
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('删除搜索历史异常: ${e.toString()}');
    }
  }

  /// 删除播放记录
  static Future<ApiResponse<void>> deletePlayRecord(String source, String id, BuildContext context) async {
    try {
      final key = '$source+$id';
      final encodedKey = Uri.encodeComponent(key);
      final response = await delete<void>(
        '/api/playrecords?key=$encodedKey',
        context: context,
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('删除播放记录异常: ${e.toString()}');
    }
  }

  /// 添加收藏
  static Future<ApiResponse<void>> favorite(String source, String id, Map<String, dynamic> favoriteData, BuildContext context) async {
    try {
      final key = '$source+$id';
      final body = {
        'key': key,
        'favorite': favoriteData,
      };
      
      final response = await post<void>(
        '/api/favorites',
        body: body,
        context: context,
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('收藏异常: ${e.toString()}');
    }
  }

  /// 取消收藏
  static Future<ApiResponse<void>> unfavorite(String source, String id, BuildContext context) async {
    try {
      final key = '$source+$id';
      final encodedKey = Uri.encodeComponent(key);
      final response = await delete<void>(
        '/api/favorites?key=$encodedKey',
        context: context,
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('取消收藏异常: ${e.toString()}');
    }
  }

  /// 检查网络连接状态
  static Future<bool> checkConnection() async {
    try {
      final baseUrl = await _getBaseUrl();
      if (baseUrl == null) return false;
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 自动登录方法
  static Future<ApiResponse<String>> autoLogin() async {
    try {
      // 获取用户数据
      final serverUrl = await UserDataService.getServerUrl();
      final username = await UserDataService.getUsername();
      final password = await UserDataService.getPassword();
      
      if (serverUrl == null || username == null || password == null) {
        return ApiResponse.error('缺少登录信息');
      }
      
      // 处理 URL
      String baseUrl = serverUrl.trim();
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      String loginUrl = '$baseUrl/api/login';
      
      // 发送登录请求
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        // 解析并保存 cookies
        String cookies = _parseCookies(response);
        
        // 更新 cookies
        await UserDataService.saveUserData(
          serverUrl: baseUrl,
          username: username,
          password: password,
          cookies: cookies,
        );
        
        return ApiResponse.success('自动登录成功', statusCode: response.statusCode);
      } else {
        return ApiResponse.error(
          '自动登录失败: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('自动登录异常: ${e.toString()}');
    }
  }

  /// 解析 Set-Cookie 头部
  static String _parseCookies(http.Response response) {
    List<String> cookies = [];
    
    // 获取所有 Set-Cookie 头部
    final setCookieHeaders = response.headers['set-cookie'];
    if (setCookieHeaders != null) {
      // HTTP 头部通常是 String 类型
      final cookieParts = setCookieHeaders.split(';');
      if (cookieParts.isNotEmpty) {
        cookies.add(cookieParts[0].trim());
      }
    }
    
    return cookies.join('; ');
  }
}
