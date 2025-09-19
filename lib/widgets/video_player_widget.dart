import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_video_controls/universal_video_controls.dart';
import 'package:universal_video_controls_video_player/universal_video_controls_video_player.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final double aspectRatio;
  final VoidCallback? onBackPressed;
  final Function(bool)? onFullscreenChange;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.aspectRatio = 16 / 9,
    this.onBackPressed,
    this.onFullscreenChange,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _isInitialized = false;
  VideoPlayerController? _videoController;
  VideoPlayerControlsWrapper? _controller;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    // 延迟初始化控制器，避免在 initState 中访问 context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeController();
    });
  }

  void _initializeController() async {
    if (mounted) {
      try {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
        );
        
        await _videoController!.initialize();
        
        if (mounted) {
          setState(() {
            _controller = VideoPlayerControlsWrapper(_videoController!);
            _isInitialized = true;
          });
          _videoController!.play();
        }
      } catch (e) {
        debugPrint('Error initializing video player: $e');
      }
    }
  }

  // 处理全屏状态变化
  void _handleFullscreenChange(bool isFullscreen) {
    if (_isFullscreen != isFullscreen) {
      setState(() {
        _isFullscreen = isFullscreen;
      });
      
      // 通知父组件全屏状态变化
      widget.onFullscreenChange?.call(isFullscreen);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: _isInitialized && _controller != null
          ? VideoControls(
              player: _controller!,
              controls: (state) => CustomVideoControls(
                state: state,
                videoController: _videoController!,
                onFullscreenChange: _handleFullscreenChange,
                onBackPressed: widget.onBackPressed,
              ),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

class CustomVideoControls extends StatefulWidget {
  final VideoControlsState state;
  final VideoPlayerController videoController;
  final Function(bool) onFullscreenChange;
  final VoidCallback? onBackPressed;

  const CustomVideoControls({
    super.key, 
    required this.state,
    required this.videoController,
    required this.onFullscreenChange,
    this.onBackPressed,
  });

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
  Timer? _hideTimer;
  bool _controlsVisible = true;
  Size? _screenSize; // 缓存屏幕尺寸

  @override
  void initState() {
    super.initState();
    _startHideTimer();
    // 监听视频播放状态变化
    widget.videoController.addListener(_onVideoStateChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在didChangeDependencies中安全地获取屏幕尺寸
    _screenSize = MediaQuery.of(context).size;
  }

  void _onVideoStateChanged() {
    // 检查widget是否仍然mounted
    if (!mounted) return;
    
    // 根据播放状态管理自动隐藏定时器
    if (widget.videoController.value.isPlaying) {
      // 视频开始播放时，如果控件可见则启动定时器
      if (_controlsVisible) {
        _startHideTimer();
      }
    } else {
      // 视频暂停时，停止定时器并显示控件
      _hideTimer?.cancel();
      if (!_controlsVisible) {
        setState(() {
          _controlsVisible = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.videoController.removeListener(_onVideoStateChanged);
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    // 只在视频播放时启动自动隐藏定时器
    if (widget.videoController.value.isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _controlsVisible = false;
          });
        }
      });
    }
  }

  void _onUserInteraction() {
    // 用户交互时始终显示控件并重置定时器
    setState(() {
      _controlsVisible = true;
    });
    _startHideTimer();
    // 强制触发一次UI更新，确保StreamBuilder重新获取最新数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onBlankAreaTap() {
    // 检查widget是否仍然mounted
    if (!mounted) return;
    
    // 点击空白区域时切换控件显示状态
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    
    if (_controlsVisible) {
      _startHideTimer();
      // 强制触发一次UI更新，确保StreamBuilder重新获取最新数据
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      _hideTimer?.cancel();
    }
  }

  void _onSeekStart() {
    if (!mounted) return;
    setState(() {
      _controlsVisible = true;
    });
    _hideTimer?.cancel();
    // 拖拽开始也是用户交互，需要重置定时器
    _startHideTimer();
  }

  void _onSeekEnd() {
    _startHideTimer();
  }

  // 先切换屏幕方向再退出全屏
  Future<void> _exitFullscreenWithOrientationChange() async {
    // 检查widget是否仍然mounted
    if (!mounted) return;
    
    // 先切换到竖屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // 等待屏幕方向切换完成
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 再次检查widget是否仍然mounted
    if (!mounted) return;
    
    // 然后退出全屏
    await widget.state.exitFullscreen();
    
    // 通知父组件全屏状态变化
    widget.onFullscreenChange(false);
  }

  @override
  Widget build(BuildContext context) {
    // 安全地获取全屏状态
    bool isFullscreen = false;
    try {
      isFullscreen = widget.state.isFullscreen();
    } catch (e) {
      // 如果无法获取全屏状态，默认为非全屏
      debugPrint('Cannot get fullscreen state: $e');
    }
    
    return Stack(
      children: [
        // 全屏点击区域 - 始终存在，用于显示/隐藏控件和长按三倍速
        // 排除进度条区域，避免点击冲突
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0, // 全屏时只排除进度条上方10px区域
          child: GestureDetector(
            onTap: _onBlankAreaTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        // 全屏渐变效果
        if (_controlsVisible)
          Positioned.fill(
            child: GestureDetector(
              onTap: _onBlankAreaTap,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5), // 顶部黑色
                      Colors.transparent, // 中间无色
                      Colors.black.withOpacity(0.1), // 底部黑色
                    ],
                    stops: const [0.0, 0.5, 1.0], // 控制渐变位置
                  ),
                ),
              ),
            ),
          ),
        // 返回按钮
        if (_controlsVisible)
          Positioned(
            top: isFullscreen ? 16 : 0,
            left: isFullscreen ? 16.0 : 2.0,
            child: GestureDetector(
              onTap: () async {
                _onUserInteraction();
                // 如果处于全屏状态，则先切换屏幕方向再退出全屏
                if (isFullscreen) {
                  await _exitFullscreenWithOrientationChange();
                } else {
                  // 否则调用父组件的返回回调
                  widget.onBackPressed?.call();
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        // 居中播放按钮 - 使用MaterialDesktopPlayOrPauseButton
        if (_controlsVisible)
          Positioned(
            top: isFullscreen && _screenSize != null
                ? _screenSize!.height / 2 - 32  // 全屏时使用屏幕中心
                : 0,  // 非全屏时从顶部开始
            bottom: isFullscreen 
                ? null  // 全屏时不设置bottom
                : 0,  // 非全屏时从底部开始，配合top=0实现垂直居中
            left: 0,
            right: 0,
            child: Center(  // 统一使用Center包装
              child: MaterialDesktopPlayOrPauseButton(
                iconSize: isFullscreen ? 64 : 48,
              ),
            ),
          ),
        // 进度条 - 使用Material Design桌面控件
        if (_controlsVisible)
          Positioned(
            bottom: isFullscreen ? 42.0 : 24.0, // 全屏时向下移动32像素
            left: 0,
            right: 0,
            child: MaterialDesktopSeekBar(
              onSeekStart: _onSeekStart,
              onSeekEnd: _onSeekEnd,
            ),
          ),
        // 底部控件 - 使用Material Design桌面控件
        if (_controlsVisible)
          Positioned(
            bottom: isFullscreen ? 0 : -12,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                // 阻止点击事件冒泡到空白区域
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: isFullscreen ? 16.0 : 0.0,
                    right: isFullscreen ? 16.0 : 8.0,
                    top: isFullscreen ? 0.0 : 0.0,
                    bottom: isFullscreen ? 8.0 : 8.0,
                  ),
                  child: Row(
                    children: [
                      // 播放按钮 - 使用MaterialDesktopPlayOrPauseButton
                      MaterialDesktopPlayOrPauseButton(
                        iconSize: isFullscreen ? 28 : 24,
                      ),
                      // 下一集按钮
                      Transform.translate(
                        offset: Offset(-8, 0), // 向左移动8像素，让下一集按钮更接近播放按钮
                        child: IconButton(
                          icon: Icon(
                            Icons.skip_next,
                            color: Colors.white,
                            size: isFullscreen ? 28 : 24,
                          ),
                          onPressed: () {
                            _onUserInteraction();
                            // Handle next episode
                          },
                        ),
                      ),
                      // 位置指示器
                      MaterialDesktopPositionIndicator(),
                      const Spacer(),
                      // 设置按钮
                      IconButton(
                        icon: Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: isFullscreen ? 28 : 24,
                        ),
                        onPressed: () {
                          _onUserInteraction();
                          // Handle settings
                        },
                      ),
                      // 全屏按钮 - 使用MaterialDesktopFullscreenButton
                      MaterialDesktopFullscreenButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
