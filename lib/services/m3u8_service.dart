import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// M3U8 流质量信息
class M3U8Quality {
  final String resolution; // 分辨率 如 "1920x1080"
  final String url; // 流地址
  final List<String> segmentUrls; // 视频片段URL列表

  M3U8Quality({
    required this.resolution,
    required this.url,
    this.segmentUrls = const [],
  });

  @override
  String toString() {
    return 'M3U8Quality{resolution: $resolution, url: $url}';
  }
}

/// 网络测速结果
class SpeedTestResult {
  final double downloadSpeed; // 下载速度 MB/s
  final int latency; // 延迟 ms
  final bool isSuccess; // 是否成功
  final String error; // 错误信息

  SpeedTestResult({
    required this.downloadSpeed,
    required this.latency,
    this.isSuccess = true,
    this.error = '',
  });

  /// 格式化速度显示
  String get formattedSpeed {
    if (downloadSpeed < 1) {
      return '${(downloadSpeed * 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${downloadSpeed.toStringAsFixed(1)} MB/s';
    }
  }

  @override
  String toString() {
    return 'SpeedTestResult{downloadSpeed: $downloadSpeed MB/s, latency: $latency ms, isSuccess: $isSuccess, error: $error}';
  }
}

/// M3U8 解析和测速服务
class M3U8Service {
  final Dio _dio = Dio();

  M3U8Service() {
    // 配置 Dio
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Accept': '*/*',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    };
  }


  /// 并发获取流的核心信息：分辨率、下载速度、延迟
  Future<Map<String, dynamic>> getStreamInfo(String streamUrl) async {
    try {
      // 获取片段列表
      final segments = await _getSegmentUrls(streamUrl);
      
      if (segments.isEmpty) {
        return {
          'resolution': '未知',
          'downloadSpeed': 0.0,
          'latency': 0,
          'success': false,
          'error': '未找到视频片段',
        };
      }
      
      // 并发执行三个任务
      final futures = await Future.wait([
        _getResolutionFromM3U8(streamUrl),
        _measureLatency(segments.first),
        _measureDownloadSpeed(segments),
      ]);
      
      final resolution = futures[0] as String;
      final latency = futures[1] as int;
      final downloadSpeed = futures[2] as double;
      
      return {
        'resolution': resolution,
        'downloadSpeed': downloadSpeed,
        'latency': latency,
        'success': true,
        'error': '',
      };
      
    } catch (e) {
      return {
        'resolution': '未知',
        'downloadSpeed': 0.0,
        'latency': 0,
        'success': false,
        'error': e.toString(),
      };
    }
  }



  /// 获取M3U8流的片段URL列表
  Future<List<String>> _getSegmentUrls(String m3u8Url) async {
    try {
      final response = await _dio.get(m3u8Url);
      final content = response.data as String;
      return _parseSegmentsFromContent(content, m3u8Url);
    } catch (e) {
      return [];
    }
  }

  /// 从M3U8内容中解析片段URL
  List<String> _parseSegmentsFromContent(String content, String baseUrl) {
    final lines = content.split('\n').map((line) => line.trim()).toList();
    final segments = <String>[];
    
    for (final line in lines) {
      // 跳过注释和空行
      if (line.startsWith('#') || line.isEmpty) {
        continue;
      }
      
      // 这应该是一个片段URL
      final absoluteUrl = _resolveUrl(line, baseUrl);
      segments.add(absoluteUrl);
    }
    
    return segments;
  }

  /// 解析相对 URL 为绝对 URL
  String _resolveUrl(String url, String baseUrl) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    final baseUri = Uri.parse(baseUrl);
    if (url.startsWith('/')) {
      // 绝对路径
      return '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}$url';
    } else {
      // 相对路径
      final basePath = baseUri.path.substring(0, baseUri.path.lastIndexOf('/') + 1);
      return '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}$basePath$url';
    }
  }

  /// 测量网络延迟（RTT - Round Trip Time）
  Future<int> _measureLatency(String url) async {
    try {
      // 创建临时的 Dio 实例用于延迟测量
      final tempDio = Dio();
      tempDio.options.connectTimeout = const Duration(seconds: 5);
      tempDio.options.receiveTimeout = const Duration(seconds: 5);
      tempDio.options.headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': '*/*',
      };
      
      // 使用 HEAD 请求测量延迟，减少数据传输
      final stopwatch = Stopwatch()..start();
      
      try {
        await tempDio.head(url);
        stopwatch.stop();
        final latency = stopwatch.elapsedMilliseconds;
        return latency;
      } on DioException catch (dioError) {
        // 对于 DioException，检查是否收到了服务器响应
        if (dioError.response != null) {
          // 有响应，说明网络连接成功，只是状态码不是 2xx
          stopwatch.stop();
          final latency = stopwatch.elapsedMilliseconds;
          return latency;
        } else {
          // 没有响应，说明连接失败
          return -1;
        }
      }
      
    } catch (e) {
      return -1; // 返回 -1 表示测量失败
    }
  }


  /// 从 M3U8 文件获取分辨率
  Future<String> _getResolutionFromM3U8(String m3u8Url) async {
    try {
      final response = await _dio.get(m3u8Url);
      final content = response.data as String;
      final lines = content.split('\n').map((line) => line.trim()).toList();
      
      for (final line in lines) {
        if (line.startsWith('#EXT-X-STREAM-INF:')) {
          final params = <String, String>{};
          final parts = line.substring('#EXT-X-STREAM-INF:'.length).split(',');
          
          for (final part in parts) {
            final keyValue = part.split('=');
            if (keyValue.length == 2) {
              params[keyValue[0].trim()] = keyValue[1].trim();
            }
          }
          
          if (params.containsKey('RESOLUTION')) {
            return params['RESOLUTION']!;
          }
        }
      }
      
      return '未知';
    } catch (e) {
      return '未知';
    }
  }

  /// 测量下载速度
  Future<double> _measureDownloadSpeed(List<String> segments) async {
    try {
      // 使用前3个片段进行测速
      final segmentsToTest = segments.take(3).toList();
      
      final stopwatch = Stopwatch()..start();
      int totalBytes = 0;
      int successfulDownloads = 0;
      
      // 并发下载片段
      final futures = segmentsToTest.map((segmentUrl) async {
        try {
          final response = await _dio.get(
            segmentUrl,
            options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: const Duration(seconds: 5),
            ),
          );
          
          final bytes = (response.data as Uint8List).length;
          totalBytes += bytes;
          successfulDownloads++;
        } catch (e) {
          // 忽略下载失败的片段
        }
      });
      
      await Future.wait(futures);
      stopwatch.stop();
      
      if (successfulDownloads == 0 || totalBytes == 0) {
        return 0.0;
      }
      
      // 计算下载速度 (MB/s)
      final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000.0;
      final downloadSpeed = (totalBytes / 1024 / 1024) / elapsedSeconds;
      
      return downloadSpeed;
    } catch (e) {
      return 0.0;
    }
  }

  /// 释放资源
  void dispose() {
    _dio.close();
  }
}

