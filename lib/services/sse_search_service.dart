import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/search_result.dart';
import 'user_data_service.dart';

/// SSE 搜索服务
class SSESearchService {
  http.Client? _client;
  StreamSubscription? _subscription;
  StreamController<SearchEvent>? _eventController;
  StreamController<List<SearchResult>>? _incrementalResultsController;
  StreamController<String>? _errorController;
  StreamController<SearchProgress>? _progressController;
  
  bool _isConnected = false;
  String? _currentQuery;
  final Map<String, String> _sourceErrors = {};
  String _buffer = ''; // 用于缓冲不完整的 UTF-8 字符
  int _completedSources = 0; // 跟踪完成的源数量
  int _totalSources = 0; // 总源数量
  Timer? _timeoutTimer; // 超时定时器

  /// 获取事件流
  Stream<SearchEvent> get eventStream => _eventController?.stream ?? const Stream.empty();

  /// 获取增量结果流
  Stream<List<SearchResult>> get incrementalResultsStream => _incrementalResultsController?.stream ?? const Stream.empty();

  /// 获取错误流
  Stream<String> get errorStream => _errorController?.stream ?? const Stream.empty();

  /// 获取进度流
  Stream<SearchProgress> get progressStream => _progressController?.stream ?? const Stream.empty();

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 当前搜索查询
  String? get currentQuery => _currentQuery;

  /// 开始搜索
  Future<void> startSearch(String query) async {
    if (query.trim().isEmpty) {
      throw Exception('搜索查询不能为空');
    }

    // 如果已有连接，先关闭
    if (_isConnected) {
      await stopSearch();
    }

    // 关闭之前的流控制器
    await _eventController?.close();
    await _incrementalResultsController?.close();
    await _errorController?.close();
    await _progressController?.close();

    _currentQuery = query.trim();
    _sourceErrors.clear();
    _completedSources = 0;

    try {
      // 获取服务器地址和认证信息
      final baseUrl = await UserDataService.getServerUrl();
      final cookies = await UserDataService.getCookies();

      if (baseUrl == null) {
        throw Exception('服务器地址未配置，请先登录');
      }

      if (cookies == null) {
        throw Exception('用户未登录');
      }

      // 构建 SSE URL
      final baseUri = Uri.parse(baseUrl);
      final sseUri = baseUri.replace(
        path: '/api/search/ws',
        queryParameters: {
          'q': _currentQuery!,
        },
      );
      

      // 初始化流控制器
      _eventController = StreamController<SearchEvent>.broadcast();
      _incrementalResultsController = StreamController<List<SearchResult>>.broadcast();
      _errorController = StreamController<String>.broadcast();
      _progressController = StreamController<SearchProgress>.broadcast();

      _isConnected = true;

      // 设置15秒超时定时器
      _timeoutTimer = Timer(const Duration(seconds: 15), () {
        if (_isConnected) {
          _handleTimeout();
        }
      });

      // 创建 HTTP 客户端并开始 SSE 连接
      _client = http.Client();
      final request = http.Request('GET', sseUri);
      request.headers.addAll({
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Cookie': cookies,
      });
      
      _subscription = _client!.send(request).asStream().listen(
        _handleSSEResponse,
        onError: _handleError,
        onDone: _handleDone,
      );

    } catch (e) {
      _isConnected = false;
      _errorController?.add('连接失败: ${e.toString()}');
      rethrow;
    }
  }

  /// 处理 SSE 响应
  void _handleSSEResponse(http.StreamedResponse response) async {
    
    if (response.statusCode != 200) {
      _errorController?.add('SSE 连接失败: ${response.statusCode}');
      return;
    }

    // 重置缓冲区
    _buffer = '';

    // 流式处理 SSE 数据
    await for (final chunk in response.stream) {
      try {
        // 将新数据添加到缓冲区
        _buffer += utf8.decode(chunk, allowMalformed: true);
        
        // 按行分割并处理
        final lines = _buffer.split('\n');
        
        // 保留最后一行（可能不完整）
        if (lines.isNotEmpty) {
          _buffer = lines.last;
          lines.removeLast();
        }
        
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          
          
          // SSE 格式: data: {...}
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6); // 移除 'data: ' 前缀
            _handleSSEData(jsonStr);
          }
        }
      } catch (e) {
        // 如果解码失败，尝试跳过这个块
        continue;
      }
    }
  }

  /// 处理 SSE 数据
  void _handleSSEData(String jsonStr) {
    try {
      final data = json.decode(jsonStr);
      
      final event = SearchEvent.fromJson(data as Map<String, dynamic>);
      
      _eventController?.add(event);

      switch (event.type) {
        case SearchEventType.start:
          _handleStartEvent(event as SearchStartEvent);
          break;
        case SearchEventType.sourceResult:
          _handleSourceResultEvent(event as SearchSourceResultEvent);
          break;
        case SearchEventType.sourceError:
          _handleSourceErrorEvent(event as SearchSourceErrorEvent);
          break;
        case SearchEventType.complete:
          _handleCompleteEvent(event as SearchCompleteEvent);
          break;
      }
    } catch (e) {
      _errorController?.add('消息解析失败: ${e.toString()}');
    }
  }

  /// 处理开始事件
  void _handleStartEvent(SearchStartEvent event) {
    _totalSources = event.totalSources;
    _progressController?.add(SearchProgress(
      totalSources: event.totalSources,
      completedSources: 0,
      currentSource: null,
      isComplete: false,
    ));
  }

  /// 处理搜索结果事件
  void _handleSourceResultEvent(SearchSourceResultEvent event) {
    _completedSources++;
    
    // 只发送增量结果更新，避免全量重渲染
    if (event.results.isNotEmpty) {
      _incrementalResultsController?.add(List.from(event.results));
    }

    // 更新进度（无论是否有结果都要更新）
    _progressController?.add(SearchProgress(
      totalSources: _totalSources,
      completedSources: _completedSources,
      currentSource: event.sourceName,
      isComplete: false,
    ));
  }

  /// 处理搜索错误事件
  void _handleSourceErrorEvent(SearchSourceErrorEvent event) {
    _sourceErrors[event.source] = event.error;
    
    // 错误也算源完成，累计进度
    _completedSources++;
    
    // 更新进度
    _progressController?.add(SearchProgress(
      totalSources: _totalSources,
      completedSources: _completedSources,
      currentSource: event.sourceName,
      isComplete: false,
      error: event.error,
    ));
  }

  /// 处理完成事件
  void _handleCompleteEvent(SearchCompleteEvent event) {
    // 如果完成源数小于总源数，说明有些源没有发送结果事件
    // 将完成源数设置为总源数
    if (_completedSources < _totalSources) {
      _completedSources = _totalSources;
    }
    
    // 发送最终完成状态
    _progressController?.add(SearchProgress(
      totalSources: _totalSources,
      completedSources: _completedSources,
      currentSource: null,
      isComplete: true,
    ));
    
    // 搜索完成，关闭连接
    _closeConnection();
  }

  /// 处理超时
  void _handleTimeout() {
    // 如果完成源数小于总源数，说明有些源没有发送结果事件
    // 将完成源数设置为总源数
    if (_completedSources < _totalSources) {
      _completedSources = _totalSources;
    }
    
    // 发送超时状态
    _progressController?.add(SearchProgress(
      totalSources: _totalSources,
      completedSources: _completedSources,
      currentSource: null,
      isComplete: true,
    ));
    
    _errorController?.add('搜索超时（15秒）');
    _closeConnection();
  }

  /// 关闭连接
  void _closeConnection() {
    _isConnected = false;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _client?.close();
    _client = null;
  }

  /// 处理 WebSocket 错误
  void _handleError(error) {
    _isConnected = false;
    _errorController?.add('WebSocket 错误: ${error.toString()}');
  }

  /// 处理 WebSocket 关闭
  void _handleDone() {
    _isConnected = false;
  }

  /// 停止搜索
  Future<void> stopSearch() async {
    await _subscription?.cancel();
    _subscription = null;
    
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    
    _client?.close();
    _client = null;
    
    _isConnected = false;
    _currentQuery = null;
    
    // 关闭流控制器
    await _eventController?.close();
    await _incrementalResultsController?.close();
    await _errorController?.close();
    await _progressController?.close();
    
    _eventController = null;
    _incrementalResultsController = null;
    _errorController = null;
    _progressController = null;
  }

  /// 获取源错误信息
  Map<String, String> get sourceErrors => Map.from(_sourceErrors);

  /// 释放资源
  void dispose() {
    stopSearch();
  }
}

/// 搜索进度信息
class SearchProgress {
  final int totalSources;
  final int completedSources;
  final String? currentSource;
  final bool isComplete;
  final String? error;

  SearchProgress({
    required this.totalSources,
    required this.completedSources,
    this.currentSource,
    required this.isComplete,
    this.error,
  });

  /// 获取完成百分比
  double get progressPercentage {
    if (totalSources <= 0) return 0.0;
    return (completedSources / totalSources).clamp(0.0, 1.0);
  }

  /// 是否有错误
  bool get hasError => error != null;

  /// 获取进度描述
  String get progressDescription {
    if (isComplete) {
      return '搜索完成';
    } else if (currentSource != null) {
      return '正在搜索: $currentSource';
    } else {
      return '准备搜索...';
    }
  }
}
