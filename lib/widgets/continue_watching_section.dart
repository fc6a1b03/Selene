import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/play_record.dart';
import '../services/api_service.dart';
import 'video_card.dart';

/// 继续观看组件
class ContinueWatchingSection extends StatefulWidget {
  final Function(PlayRecord)? onVideoTap;
  final VoidCallback? onClear;

  const ContinueWatchingSection({
    super.key,
    this.onVideoTap,
    this.onClear,
  });

  @override
  State<ContinueWatchingSection> createState() => _ContinueWatchingSectionState();
}

class _ContinueWatchingSectionState extends State<ContinueWatchingSection>
    with TickerProviderStateMixin {
  List<PlayRecord> _playRecords = [];
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    _shimmerController.repeat();
    _loadPlayRecords();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  /// 加载播放记录
  Future<void> _loadPlayRecords() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final response = await ApiService.get<Map<String, dynamic>>(
        '/api/playrecords',
        context: context,
      );

      if (response.success && response.data != null) {
        final records = <PlayRecord>[];
        
        // 将Map转换为PlayRecord列表
        response.data!.forEach((id, data) {
          try {
            records.add(PlayRecord.fromJson(id, data));
          } catch (e) {
            // 忽略解析失败的记录
            print('解析播放记录失败: $e');
          }
        });

        // 按save_time降序排列
        records.sort((a, b) => b.saveTime.compareTo(a.saveTime));

        setState(() {
          _playRecords = records;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
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
                Text(
                  '继续观看',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2c3e50),
                  ),
                ),
                if (_playRecords.isNotEmpty)
                  TextButton(
                    onPressed: _clearPlayRecords,
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
                // 计算卡片宽度，确保能显示至少3个卡片
                final double screenWidth = constraints.maxWidth;
                final double padding = 32.0; // 左右padding (16 * 2)
                final double spacing = 12.0; // 卡片间距
                final double availableWidth = screenWidth - padding;
                final double cardWidth = (availableWidth - (spacing * 2)) / 3; // 确保3个卡片能放下
                
                return SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _playRecords.length,
                    itemBuilder: (context, index) {
                      final playRecord = _playRecords[index];
                      return Container(
                        margin: EdgeInsets.only(
                          right: index < _playRecords.length - 1 ? spacing : 0,
                        ),
                        child: VideoCard(
                          playRecord: playRecord,
                          onTap: () => widget.onVideoTap?.call(playRecord),
                          from: 'playrecord',
                          source: playRecord.source,
                          id: playRecord.id,
                          cardWidth: cardWidth, // 使用动态计算的宽度
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
        // 计算卡片宽度，确保能显示至少3个卡片
        final double screenWidth = constraints.maxWidth;
        final double padding = 32.0; // 左右padding (16 * 2)
        final double spacing = 12.0; // 卡片间距
        final double availableWidth = screenWidth - padding;
        final double cardWidth = (availableWidth - (spacing * 2)) / 3; // 确保3个卡片能放下
        
        return Container(
          height: 240,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3, // 显示3个骨架卡片
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 封面骨架
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildShimmerEffect(),
        ),
        const SizedBox(height: 6),
        // 标题骨架
        Container(
          height: 14,
          width: width * 0.8,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: _buildShimmerEffect(),
        ),
        const SizedBox(height: 4),
        // 源名称骨架
        Container(
          height: 10,
          width: width * 0.6,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: _buildShimmerEffect(),
        ),
      ],
    );
  }

  /// 构建闪烁效果
  Widget _buildShimmerEffect() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey[300]!,
            Colors.grey[100]!,
            Colors.grey[300]!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.grey[300]!,
                  Colors.grey[100]!,
                  Colors.grey[300]!,
                ],
                stops: [
                  0.0,
                  _shimmerAnimation.value,
                  1.0,
                ],
              ),
            ),
          );
        },
      ),
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
}
