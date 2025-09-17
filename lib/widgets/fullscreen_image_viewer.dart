import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_settings/app_settings.dart';
import '../utils/image_url.dart';

/// 全屏图片查看器
class FullscreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String source;
  final String title;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.source,
    required this.title,
  });

  /// 显示全屏图片查看器
  static void show(
    BuildContext context, {
    required String imageUrl,
    required String source,
    required String title,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => FullscreenImageViewer(
          imageUrl: imageUrl,
          source: source,
          title: title,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late TransformationController _transformationController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// 显示保存图片选择菜单
  void _showSaveImageMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽指示器
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  '保存图片',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              // 选项列表
              ListTile(
                leading: Icon(
                  Icons.download,
                  color: Colors.white,
                ),
                title: Text(
                  '保存到相册',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _saveImageToGallery();
                },
              ),
              
              ListTile(
                leading: Icon(
                  Icons.close,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                title: Text(
                  '取消',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(),
              ),
              
              // 底部安全区域
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  /// 检查并请求存储权限
  Future<bool> _checkStoragePermission() async {
    try {
      // 使用 gal 包检查权限
      final hasAccess = await Gal.hasAccess();
      
      if (hasAccess) {
        return true;
      }
      
      // 请求权限
      final granted = await Gal.requestAccess();
      
      if (!granted && mounted) {
        // 权限被拒绝，引导用户到设置页面
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              '需要存储权限',
              style: GoogleFonts.poppins(),
            ),
            content: Text(
              '保存图片到相册需要存储权限，请在设置中允许此权限。',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  '取消',
                  style: GoogleFonts.poppins(),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await AppSettings.openAppSettings();
                },
                child: Text(
                  '去设置',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        );
      }
      
      return granted;
    } catch (e) {
      print('权限检查失败: $e');
      return false;
    }
  }

  /// 保存图片到相册
  Future<void> _saveImageToGallery() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      // 检查权限
      final hasPermission = await _checkStoragePermission();
      if (!hasPermission) {
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // 显示保存提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '正在保存图片...',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.black.withValues(alpha: 0.8),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // 获取缓存的图片数据
      final imageBytes = await _getCachedImageBytes();
      
      if (imageBytes == null) {
        throw Exception('无法获取图片数据');
      }

      // 保存到相册
      await Gal.putImageBytes(
        imageBytes,
        name: widget.title.replaceAll(RegExp(r'[^\w\s-]'), ''), // 清理文件名
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '图片已保存到相册',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '保存失败: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 获取缓存的图片数据
  Future<Uint8List?> _getCachedImageBytes() async {
    try {
      // 使用 CachedNetworkImage 的缓存机制获取图片数据
      final imageProvider = CachedNetworkImageProvider(
        widget.imageUrl,
        headers: getImageRequestHeaders(widget.imageUrl, widget.source),
      );
      
      // 获取图片数据
      final imageStream = imageProvider.resolve(ImageConfiguration.empty);
      final completer = Completer<Uint8List>();
      
      late ImageStreamListener listener;
      listener = ImageStreamListener((ImageInfo imageInfo, bool synchronousCall) {
        final image = imageInfo.image;
        image.toByteData(format: ui.ImageByteFormat.png).then((byteData) {
          if (byteData != null) {
            completer.complete(byteData.buffer.asUint8List());
          } else {
            completer.completeError('无法获取图片数据');
          }
        }).catchError((error) {
          completer.completeError(error);
        });
        imageStream.removeListener(listener);
      }, onError: (exception, stackTrace) {
        completer.completeError(exception);
        imageStream.removeListener(listener);
      });
      
      imageStream.addListener(listener);
      return await completer.future;
    } catch (e) {
      print('获取缓存图片数据失败: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 背景点击区域
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(), // 点击黑色区域关闭
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // 图片区域
          Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(), // 点击图片也关闭
              onLongPress: _showSaveImageMenu, // 长按显示保存菜单
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: FutureBuilder<String>(
                  future: getImageUrl(widget.imageUrl, widget.source),
                  builder: (context, snapshot) {
                    final String imageUrl = snapshot.data ?? widget.imageUrl;
                    final headers = getImageRequestHeaders(imageUrl, widget.source);
                    
                    return CachedNetworkImage(
                      imageUrl: imageUrl,
                      httpHeaders: headers,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '加载中...',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '图片加载失败',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}