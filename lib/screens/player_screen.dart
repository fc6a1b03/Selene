import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/video_player_widget.dart';

class PlayerScreen extends StatefulWidget {
  final String? source;
  final String? id;
  final String title;
  final String? year;
  final String? stitle;
  final String? stype;
  final String? prefer;

  const PlayerScreen({
    super.key,
    this.source,
    this.id,
    required this.title,
    this.year,
    this.stitle,
    this.stype,
    this.prefer,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late SystemUiOverlayStyle _originalStyle;
  bool _isInitialized = false;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    // 设置初始屏幕方向为竖屏
    _setPortraitOrientation();
  }

  // 设置竖屏方向
  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // 根据视频宽高比决定屏幕方向
  void _setOrientationBasedOnVideo() {
    // 简化版本：全屏时使用横屏，非全屏时使用竖屏
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      _setPortraitOrientation();
    }
  }

  // 处理全屏状态变化
  void _handleFullscreenChange(bool isFullscreen) {
    if (_isFullscreen != isFullscreen) {
      setState(() {
        _isFullscreen = isFullscreen;
      });
      
      // 延迟执行屏幕方向设置，确保状态更新完成
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isFullscreen) {
          // 全屏时根据视频宽高比决定方向
          _setOrientationBasedOnVideo();
        } else {
          // 非全屏时强制竖屏
          _setPortraitOrientation();
        }
      });
    }
  }

  // 处理返回按钮点击
  void _onBackPressed() {
    Navigator.of(context).pop();
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // 保存当前的系统UI样式
      final theme = Theme.of(context);
      final isDarkMode = theme.brightness == Brightness.dark;
      _originalStyle = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      );
      _isInitialized = true;
    }
    // 监听屏幕尺寸变化，确保全屏状态正确更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final screenSize = MediaQuery.of(context).size;
          final isCurrentlyFullscreen = screenSize.width > screenSize.height && 
                                      screenSize.width / screenSize.height > 1.5;
          if (_isFullscreen != isCurrentlyFullscreen) {
            _handleFullscreenChange(isCurrentlyFullscreen);
          }
        } catch (e) {
          // 如果无法访问MediaQuery，忽略此次更新
          debugPrint('Cannot access MediaQuery in didChangeDependencies: $e');
        }
      }
    });
  }


  @override
  void dispose() {
    // 恢复原始的系统UI样式
    SystemChrome.setSystemUIOverlayStyle(_originalStyle);
    // 恢复屏幕方向为自动
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: isDarkMode ? Colors.black : theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        // 其余代码保持不变
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            Container(
              height: MediaQuery.maybeOf(context)?.padding.top ?? 0,
              color: Colors.black,
            ),
            VideoPlayerWidget(
              videoUrl: 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
              aspectRatio: 16 / 9,
              onBackPressed: _onBackPressed,
              onFullscreenChange: _handleFullscreenChange,
            ),
            Expanded(
              child: Container(
                color: theme.scaffoldBackgroundColor,
                child: Center(
                  child: Text(
                    '${widget.title} (${widget.year})',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

