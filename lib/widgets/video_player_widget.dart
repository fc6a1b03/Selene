import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
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
  ChewieController? _chewieController;
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
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: true,
            looping: false,
            allowFullScreen: true,
            allowMuting: true,
            allowPlaybackSpeedChanging: true,
            showOptions: true,
            showControlsOnInitialize: true,
            customControls: CustomChewieControls(
              onBackPressed: widget.onBackPressed,
              onFullscreenChange: _handleFullscreenChange,
            ),
          );
          
          setState(() {
            _isInitialized = true;
          });
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
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: _isInitialized && _chewieController != null
          ? Chewie(controller: _chewieController!)
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

class CustomChewieControls extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final Function(bool) onFullscreenChange;

  const CustomChewieControls({
    super.key,
    this.onBackPressed,
    required this.onFullscreenChange,
  });

  @override
  State<CustomChewieControls> createState() => _CustomChewieControlsState();
}

class _CustomChewieControlsState extends State<CustomChewieControls> {
  Timer? _hideTimer;
  bool _controlsVisible = true;
  Size? _screenSize; // 缓存屏幕尺寸
  ChewieController? _chewieController;
  bool _lastPlayingState = false; // 记录上次的播放状态，避免重复触发

  bool _isLongPressing = false;
  double _originalPlaybackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在didChangeDependencies中安全地获取屏幕尺寸
    _screenSize = MediaQuery.of(context).size;
    
    // 获取 ChewieController
    final chewieController = ChewieController.of(context);
    _chewieController = chewieController;
    // 监听视频播放状态变化
    _chewieController!.videoPlayerController.addListener(_onVideoStateChanged);
  }

  void _onVideoStateChanged() {
    // 检查widget是否仍然mounted
    if (!mounted) return;
    
    final isPlaying = _chewieController?.videoPlayerController.value.isPlaying ?? false;
    
    // 只在播放状态真正改变时才处理，避免频繁触发
    if (isPlaying != _lastPlayingState) {
      _lastPlayingState = isPlaying;
      
      // 长按期间不处理自动隐藏逻辑
      if (_isLongPressing) return;
      
      if (isPlaying) {
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
  }

  void _onLongPressStart(LongPressStartDetails details) {
    final chewieController = _chewieController;
    if (chewieController == null || !chewieController.videoPlayerController.value.isPlaying) {
      return;
    }

    // 停止自动隐藏定时器
    _hideTimer?.cancel();

    setState(() {
      _isLongPressing = true;
      _originalPlaybackSpeed = chewieController.videoPlayerController.value.playbackSpeed;
      chewieController.videoPlayerController.setPlaybackSpeed(3.0);
      _controlsVisible = true;
    });
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    final chewieController = _chewieController;
    if (chewieController == null || !_isLongPressing) {
      return;
    }

    setState(() {
      _isLongPressing = false;
      chewieController.videoPlayerController.setPlaybackSpeed(_originalPlaybackSpeed);
      _controlsVisible = true;
    });
    
    // 长按结束后重新启动自动隐藏定时器
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _chewieController?.videoPlayerController.removeListener(_onVideoStateChanged);
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    // 只在视频播放时启动自动隐藏定时器
    if (_chewieController != null && _chewieController!.videoPlayerController.value.isPlaying) {
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
    // 强制触发一次UI更新
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
      // 强制触发一次UI更新
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
    _chewieController?.exitFullScreen();
    
    // 通知父组件全屏状态变化
    widget.onFullscreenChange(false);
  }

  @override
  Widget build(BuildContext context) {
    final chewieController = ChewieController.of(context);
    final isFullscreen = chewieController.isFullScreen;
    
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: () {
        if (_isLongPressing) {
          _onLongPressEnd(const LongPressEndDetails());
        }
      },
      child: Stack(
        children: [
          // 全屏点击区域 - 始终存在，用于显示/隐藏控件
          // 排除进度条区域，避免点击冲突
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0, // 非全屏时排除底部50px区域（进度条+按钮区域）
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
              top: isFullscreen ? 8 : 4,
              left: isFullscreen ? 16.0 : 8.0,
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
                  child: Icon(
                    Icons.arrow_back, 
                    color: Colors.white,
                    size: isFullscreen ? 24 : 20,
                  ),
                ),
              ),
            ),
          // 居中播放按钮
          if (_controlsVisible)
            Positioned(
              top: isFullscreen && _screenSize != null
                  ? _screenSize!.height / 2 - 32 // 全屏时使用屏幕中心
                  : 0, // 非全屏时从顶部开始
              bottom: isFullscreen
                  ? null // 全屏时不设置bottom
                  : 0, // 非全屏时从底部开始，配合top=0实现垂直居中
              left: 0,
              right: 0,
              child: Center(
                child: _isLongPressing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '3x',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.fast_forward,
                            color: Colors.white,
                            size: isFullscreen ? 64 : 48,
                          ),
                        ],
                      )
                    : GestureDetector(
                        onTap: () {
                          _onUserInteraction();
                          if (chewieController
                              .videoPlayerController.value.isPlaying) {
                            chewieController.pause();
                          } else {
                            chewieController.play();
                          }
                        },
                        child: AnimatedBuilder(
                          animation: chewieController.videoPlayerController,
                          builder: (context, child) {
                            return Icon(
                              chewieController
                                      .videoPlayerController.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: isFullscreen ? 64 : 48,
                            );
                          },
                        ),
                      ),
              ),
            ),
          // 进度条
          if (_controlsVisible)
            Positioned(
              bottom: isFullscreen ? 58.0 : 42.0,
              left: 0,
              right: 0,
              child: Container(
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: MaterialVideoProgressBar(
                  chewieController.videoPlayerController,
                  barHeight: 6,
                  handleHeight: 6,
                  colors: ChewieProgressColors(
                    playedColor: Colors.red,
                    handleColor: Colors.red,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    bufferedColor: Colors.transparent,
                  ),
                  onDragStart: _onSeekStart,
                  onDragEnd: _onSeekEnd,
                  onDragUpdate: () {
                    // 拖拽过程中保持控件可见并重置定时器
                    if (!_controlsVisible) {
                      setState(() {
                        _controlsVisible = true;
                      });
                    }
                    // 拖拽过程中重置定时器，避免在拖拽时自动隐藏
                    _hideTimer?.cancel();
                  },
                ),
              ),
            ),
          // 底部控件
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
                      left: isFullscreen ? 16.0 : 8.0,
                      right: isFullscreen ? 16.0 : 8.0,
                      top: isFullscreen ? 0.0 : 0.0,
                      bottom: isFullscreen ? 8.0 : 10.0,
                    ),
                    child: Row(
                      children: [
                        // 播放按钮
                        GestureDetector(
                          onTap: () {
                            _onUserInteraction();
                            if (chewieController.videoPlayerController.value.isPlaying) {
                              chewieController.pause();
                            } else {
                              chewieController.play();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: AnimatedBuilder(
                              animation: chewieController.videoPlayerController,
                              builder: (context, child) {
                                return Icon(
                                  chewieController.videoPlayerController.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: isFullscreen ? 28 : 24,
                                );
                              },
                            ),
                          ),
                        ),
                        // 下一集按钮
                        Transform.translate(
                          offset: const Offset(-8, 0),
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
                        Expanded(
                          child: _buildPositionIndicator(chewieController),
                        ),
                        // 设置按钮
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: isFullscreen ? 22 : 20,
                          ),
                          onPressed: () {
                            _onUserInteraction();
                            // Handle settings
                          },
                        ),
                        // 全屏按钮
                        GestureDetector(
                          onTap: () {
                            _onUserInteraction();
                            if (isFullscreen) {
                              _exitFullscreenWithOrientationChange();
                            } else {
                              chewieController.enterFullScreen();
                              widget.onFullscreenChange(true);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                              color: Colors.white,
                              size: isFullscreen ? 28 : 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildPositionIndicator(ChewieController chewieController) {
    final videoPlayerController = chewieController.videoPlayerController;
    
    return AnimatedBuilder(
      animation: videoPlayerController,
      builder: (context, child) {
        final currentPosition = videoPlayerController.value.position;
        final totalDuration = videoPlayerController.value.duration;
        
        return Text(
          '${_formatDuration(currentPosition)} / ${_formatDuration(totalDuration)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}