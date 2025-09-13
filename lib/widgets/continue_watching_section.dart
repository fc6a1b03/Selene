import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import '../services/api_service.dart';
import '../services/page_cache_service.dart';
import '../services/theme_service.dart';
import 'video_card.dart';
import 'video_menu_bottom_sheet.dart';
import 'shimmer_effect.dart';

/// 继续观看组件
class ContinueWatchingSection extends StatefulWidget {
  final Function(PlayRecord)? onVideoTap;
  final VoidCallback? onClear;
  final Function(PlayRecord, VideoMenuAction)? onGlobalMenuAction;

  const ContinueWatchingSection({
    super.key,
    this.onVideoTap,
    this.onClear,
    this.onGlobalMenuAction,
  });

  @override
  State<ContinueWatchingSection> createState() => _ContinueWatchingSectionState();

  /// 静态方法：从外部移除播放记录
  static void removePlayRecordFromUI(String source, String id) {
    _ContinueWatchingSectionState._currentInstance?.removePlayRecordFromUI(source, id);
  }

  /// 静态方法：刷新播放记录
  static Future<void> refreshPlayRecords() async {
    await _ContinueWatchingSectionState._currentInstance?.refreshPlayRecords();
  }
}

class _ContinueWatchingSectionState extends State<ContinueWatchingSection>
    with TickerProviderStateMixin {
  List<PlayRecord> _playRecords = [];
  bool _isLoading = true;
  bool _hasError = false;
  final PageCacheService _cacheService = PageCacheService();
  
  // 静态变量存储当前实例
  static _ContinueWatchingSectionState? _currentInstance;

  @override
  void initState() {
    super.initState();
    
    // 设置当前实例
    _currentInstance = this;
    
    // 延迟执行异步操作，确保 initState 完成后再访问 context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPlayRecords();
      }
    });
  }

  @override
  void dispose() {
    // 清除当前实例引用
    if (_currentInstance == this) {
      _currentInstance = null;
    }
    super.dispose();
  }

  /// 加载播放记录
  Future<void> _loadPlayRecords() async {
    if (!mounted) return;
    
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
      }

      // 先尝试从缓存获取数据
      final cachedRecords = _cacheService.getCache<List<PlayRecord>>('play_records');
      
      if (cachedRecords != null) {
        // 有缓存数据，立即显示
        if (mounted) {
          setState(() {
            _playRecords = cachedRecords;
            _isLoading = false;
          });
        }
        
        // 预加载图片
        if (mounted) {
          _preloadImages(cachedRecords);
        }
        
        // 异步获取最新数据
        _refreshDataInBackground();
      } else {
        // 没有缓存，从API获取
        final result = await _cacheService.getPlayRecords(context);

        if (mounted) {
          if (result.success && result.data != null) {
            setState(() {
              _playRecords = result.data!;
              _isLoading = false;
            });
            
            // 预加载图片
            _preloadImages(result.data!);
          } else {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }


  /// 后台刷新数据
  Future<void> _refreshDataInBackground() async {
    if (!mounted) return;
    
    try {
      // 只刷新播放记录数据
      await _cacheService.refreshPlayRecords(context);
      
      // 刷新成功后，从缓存获取最新数据
      if (mounted) {
        final cachedRecords = _cacheService.getCache<List<PlayRecord>>('play_records');
        if (cachedRecords != null) {
          // 只有当新数据与当前数据不同时才更新UI
          if (_playRecords.length != cachedRecords.length || 
              !_isSamePlayRecords(_playRecords, cachedRecords)) {
            if (mounted) {
              setState(() {
                _playRecords = cachedRecords;
              });
              
              // 预加载新图片
              _preloadImages(cachedRecords);
            }
          }
        }
      }
    } catch (e) {
      // 后台刷新失败，静默处理，保持原有数据
    }
  }

  /// 比较两个播放记录列表是否相同
  bool _isSamePlayRecords(List<PlayRecord> list1, List<PlayRecord> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id || 
          list1[i].source != list2[i].source ||
          list1[i].saveTime != list2[i].saveTime) {
        return false;
      }
    }
    return true;
  }

  /// 预加载图片
  void _preloadImages(List<PlayRecord> records) {
    if (!mounted) return;
    
    // 只预加载前几个图片，避免过度预加载
    final int preloadCount = math.min(records.length, 5);
    for (int i = 0; i < preloadCount; i++) {
      if (!mounted) break;
      
      final record = records[i];
      final imageUrl = _getImageUrl(record.cover, record.source);
      if (imageUrl.isNotEmpty) {
        precacheImage(NetworkImage(imageUrl), context);
      }
    }
  }

  /// 获取处理后的图片URL
  String _getImageUrl(String originalUrl, String? source) {
    if (source == 'douban' && originalUrl.isNotEmpty) {
      // 将豆瓣图片域名替换为新的域名
      return originalUrl.replaceAll(
        RegExp(r'https?://[^/]+\.doubanio\.com'),
        'https://img.doubanio.cmliussss.net'
      );
    }
    return originalUrl;
  }

  /// 显示清空确认弹窗
  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return AlertDialog(
              backgroundColor: themeService.isDarkMode 
                  ? const Color(0xFF1e1e1e)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFe74c3c).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFe74c3c),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              // 标题
              Text(
                '清空播放记录',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeService.isDarkMode 
                      ? const Color(0xFFffffff)
                      : const Color(0xFF2c3e50),
                ),
              ),
              const SizedBox(height: 12),
              // 描述
              Text(
                '确定要清空所有播放记录吗？此操作无法撤销。',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: themeService.isDarkMode 
                      ? const Color(0xFFb0b0b0)
                      : const Color(0xFF7f8c8d),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // 按钮
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '取消',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: themeService.isDarkMode 
                              ? const Color(0xFFb0b0b0)
                              : const Color(0xFF7f8c8d),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _clearPlayRecords();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFe74c3c),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '清空',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  /// 清空播放记录
  Future<void> _clearPlayRecords() async {
    try {
      final response = await ApiService.delete(
        '/api/playrecords',
        context: context,
      );

      if (response.success) {
        setState(() {
          _playRecords.clear();
        });
        // 显示成功提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '播放记录已清空',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF27ae60),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        // 显示错误提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message ?? '清空失败',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFe74c3c),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '清空失败: ${e.toString()}',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFe74c3c),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果没有数据且不在加载中，隐藏组件
    if (!_isLoading && _playRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和清空按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<ThemeService>(
                  builder: (context, themeService, child) {
                    return Text(
                      '继续观看',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: themeService.isDarkMode 
                            ? const Color(0xFFffffff)
                            : const Color(0xFF2c3e50),
                      ),
                    );
                  },
                ),
                if (_playRecords.isNotEmpty)
                  TextButton(
                    onPressed: _showClearConfirmation,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '清空',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF7f8c8d),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 内容区域
          if (_isLoading)
            _buildLoadingState()
          else if (_hasError)
            _buildErrorState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // 计算卡片宽度，确保能显示2.75个卡片
                final double screenWidth = constraints.maxWidth;
                const double padding = 32.0; // 左右padding (16 * 2)
                const double spacing = 12.0; // 卡片间距
                final double availableWidth = screenWidth - padding;
                // 确保最小宽度，防止负宽度约束
                const double minCardWidth = 120.0; // 最小卡片宽度
                final double calculatedCardWidth = (availableWidth - (spacing * 1.75)) / 2.75;
                final double cardWidth = math.max(calculatedCardWidth, minCardWidth);
                final double cardHeight = (cardWidth * 1.5) + 50; // 缓存高度计算
                
                return SizedBox(
                  height: cardHeight, // 使用缓存的高度
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _playRecords.length,
                    // 优化性能：添加itemExtent和缓存范围
                    itemExtent: cardWidth + spacing,
                    cacheExtent: (cardWidth + spacing) * 3, // 缓存3个item的范围
                    itemBuilder: (context, index) {
                      final playRecord = _playRecords[index];
                      return Container(
                        width: cardWidth,
                        margin: EdgeInsets.only(
                          right: index < _playRecords.length - 1 ? spacing : 0,
                        ),
                        child: VideoCard(
                          videoInfo: VideoInfo.fromPlayRecord(playRecord),
                          onTap: () => widget.onVideoTap?.call(playRecord),
                          from: 'playrecord',
                          cardWidth: cardWidth, // 使用动态计算的宽度
                          onGlobalMenuAction: (action) => widget.onGlobalMenuAction?.call(playRecord, action),
                          isFavorited: _cacheService.isFavoritedSync(playRecord.source, playRecord.id), // 同步检测收藏状态
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算卡片宽度，确保能显示2.75个卡片
        final double screenWidth = constraints.maxWidth;
        const double padding = 32.0; // 左右padding (16 * 2)
        const double spacing = 12.0; // 卡片间距
        final double availableWidth = screenWidth - padding;
        // 确保最小宽度，防止负宽度约束
        const double minCardWidth = 120.0; // 最小卡片宽度
        final double calculatedCardWidth = (availableWidth - (spacing * 1.75)) / 2.75;
        final double cardWidth = math.max(calculatedCardWidth, minCardWidth);
        final double cardHeight = (cardWidth * 1.5) + 50; // 缓存高度计算
        
        return Container(
          height: cardHeight, // 使用缓存的高度
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3, // 显示3个骨架卡片，最后一个只显示一半
            itemBuilder: (context, index) {
              return Container(
                width: cardWidth,
                margin: EdgeInsets.only(
                  right: index < 2 ? spacing : 0,
                ),
                child: _buildSkeletonCard(cardWidth),
              );
            },
          ),
        );
      },
    );
  }

  /// 构建骨架卡片
  Widget _buildSkeletonCard(double width) {
    final double height = width * 1.4; // 保持与VideoCard相同的比例
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 封面骨架
        ShimmerEffect(
          width: width,
          height: height,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 6),
        // 标题骨架
        Center(
          child: ShimmerEffect(
            width: width * 0.8,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        // 源名称骨架
        Center(
          child: ShimmerEffect(
            width: width * 0.6,
            height: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '加载播放记录失败',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadPlayRecords,
              child: Text(
                '重试',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF2c3e50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 刷新播放记录列表（供外部调用）
  Future<void> refreshPlayRecords() async {
    if (!mounted) return;
    
    try {
      // 强制从API获取最新数据并更新缓存
      await _cacheService.refreshPlayRecords(context);
      
      // 刷新成功后，从缓存获取最新数据
      if (mounted) {
        final cachedRecords = _cacheService.getCache<List<PlayRecord>>('play_records');
        if (cachedRecords != null) {
          setState(() {
            _playRecords = cachedRecords;
          });
          
          // 预加载新图片
          _preloadImages(cachedRecords);
        }
      }
    } catch (e) {
      // 刷新失败，静默处理
    }
  }

  /// 从UI中移除指定的播放记录（供外部调用）
  void removePlayRecordFromUI(String source, String id) {
    if (!mounted) return;
    
    setState(() {
      _playRecords.removeWhere((record) => 
        record.source == source && record.id == id
      );
    });
  }


}
