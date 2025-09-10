import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/favorite_item.dart';
import '../widgets/video_card.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import '../services/api_service.dart';

class FavoritesGrid extends StatefulWidget {
  final Function(PlayRecord) onVideoTap;

  const FavoritesGrid({
    super.key,
    required this.onVideoTap,
  });

  @override
  State<FavoritesGrid> createState() => _FavoritesGridState();
}

class _FavoritesGridState extends State<FavoritesGrid>
    with TickerProviderStateMixin {
  List<FavoriteItem> _favorites = [];
  List<PlayRecord> _playRecords = [];
  bool _isLoading = true;
  String? _errorMessage;
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
    _loadData();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 同时加载收藏夹和播放记录
      await Future.wait([
        _loadFavorites(),
        _loadPlayRecords(),
      ]);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final response = await ApiService.getFavorites(context);
      
      if (response.success && response.data != null) {
        // 过滤掉origin为"live"的项目
        final filteredFavorites = response.data!
            .where((favorite) => favorite.origin != 'live')
            .toList();
        
        setState(() {
          _favorites = filteredFavorites;
        });
      } else {
        throw Exception(response.message ?? '获取收藏夹失败');
      }
    } catch (e) {
      throw Exception('获取收藏夹失败: $e');
    }
  }

  Future<void> _loadPlayRecords() async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        '/api/playrecords',
        context: context,
      );

      if (response.success && response.data != null) {
        final records = <PlayRecord>[];
        
        // 将Map转换为PlayRecord列表
        response.data!.forEach((key, data) {
          try {
            records.add(PlayRecord.fromJson(key, data));
          } catch (e) {
            // 忽略解析失败的记录
          }
        });

        // 按save_time降序排列
        records.sort((a, b) => b.saveTime.compareTo(a.saveTime));

        setState(() {
          _playRecords = records;
        });
      } else {
        throw Exception(response.message ?? '获取播放记录失败');
      }
    } catch (e) {
      throw Exception('获取播放记录失败: $e');
    }
  }

  PlayRecord _favoriteToPlayRecord(FavoriteItem favorite) {
    // 查找匹配的播放记录
    try {
      final matchingPlayRecord = _playRecords.firstWhere(
        (record) => record.source == favorite.source && record.id == favorite.id,
      );
      // 如果有匹配的播放记录，使用播放记录的数据
      return matchingPlayRecord;
    } catch (e) {
      // 如果没有匹配的播放记录，使用收藏夹的默认数据
      return PlayRecord(
        id: favorite.id,
        source: favorite.source,
        title: favorite.title,
        cover: favorite.cover,
        year: favorite.year,
        sourceName: favorite.sourceName,
        totalEpisodes: favorite.totalEpisodes,
        index: 1, // 默认从第1集开始
        playTime: 0, // 未播放
        totalTime: 0, // 未知总时长
        saveTime: favorite.saveTime,
        searchTitle: favorite.title, // 使用标题作为搜索标题
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_favorites.isEmpty) {
      return _buildEmptyState();
    }

    return _buildFavoritesGrid();
  }

  Widget _buildLoadingState() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF27ae60),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 计算每列的宽度，确保严格三列布局
          final double screenWidth = constraints.maxWidth;
          final double padding = 16.0; // 左右padding
          final double spacing = 12.0; // 列间距
          final double availableWidth = screenWidth - (padding * 2) - (spacing * 2); // 减去padding和间距
          final double itemWidth = availableWidth / 3; // 每列宽度
          final double itemHeight = itemWidth * 1.9; // 进一步增加高度比例，确保有足够空间避免溢出
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 严格3列布局
              childAspectRatio: itemWidth / itemHeight, // 精确计算宽高比
              crossAxisSpacing: spacing, // 列间距
              mainAxisSpacing: 20, // 增加行间距
            ),
            itemCount: 6, // 显示6个骨架卡片
            itemBuilder: (context, index) {
              return _buildSkeletonCard(itemWidth);
            },
          );
        },
      ),
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
        const SizedBox(height: 4),
        // 标题骨架
        Container(
          height: 12,
          width: width * 0.8,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: _buildShimmerEffect(),
        ),
        const SizedBox(height: 2),
        // 源名称骨架
        Container(
          height: 8,
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
    return AnimatedBuilder(
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
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: const Color(0xFFbdc3c7),
          ),
          const SizedBox(height: 24),
          Text(
            '加载失败',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7f8c8d),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? '未知错误',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF95a5a6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadFavorites,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27ae60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '重试',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: const Color(0xFFbdc3c7),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无收藏内容',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7f8c8d),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '您收藏的视频将显示在这里',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF95a5a6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesGrid() {
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: const Color(0xFF27ae60),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 计算每列的宽度，确保严格三列布局
          final double screenWidth = constraints.maxWidth;
          final double padding = 16.0; // 左右padding
          final double spacing = 12.0; // 列间距
          final double availableWidth = screenWidth - (padding * 2) - (spacing * 2); // 减去padding和间距
          final double itemWidth = availableWidth / 3; // 每列宽度
          final double itemHeight = itemWidth * 1.9; // 进一步增加高度比例，确保有足够空间避免溢出
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 严格3列布局
              childAspectRatio: itemWidth / itemHeight, // 精确计算宽高比
              crossAxisSpacing: spacing, // 列间距
              mainAxisSpacing: 20, // 增加行间距
            ),
            itemCount: _favorites.length,
            itemBuilder: (context, index) {
              final favorite = _favorites[index];
              final playRecord = _favoriteToPlayRecord(favorite);
              
              // 检查是否有匹配的播放记录
              final hasPlayRecord = _playRecords.any(
                (record) => record.source == favorite.source && record.id == favorite.id,
              );
              
              return VideoCard(
                videoInfo: VideoInfo.fromPlayRecord(playRecord),
                onTap: () => widget.onVideoTap(playRecord),
                from: hasPlayRecord ? 'playrecord' : 'favorite',
                cardWidth: itemWidth, // 传递计算出的宽度
              );
            },
          );
        },
      ),
    );
  }
}
