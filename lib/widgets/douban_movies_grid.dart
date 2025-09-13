import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/douban_movie.dart';
import '../models/play_record.dart';
import '../services/theme_service.dart';
import 'video_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'video_menu_bottom_sheet.dart';
import '../models/video_info.dart';
import 'shimmer_effect.dart';

class DoubanMoviesGrid extends StatefulWidget {
  final String category;
  final String region;
  final Function(PlayRecord) onVideoTap;
  final Function(VideoInfo, VideoMenuAction)? onGlobalMenuAction;

  const DoubanMoviesGrid({
    super.key,
    required this.category,
    required this.region,
    required this.onVideoTap,
    this.onGlobalMenuAction,
  });

  static void setContent(List<DoubanMovie> movies) {
    _DoubanMoviesGridState._currentInstance?._setContent(movies);
  }

  static void appendContent(List<DoubanMovie> movies) {
    _DoubanMoviesGridState._currentInstance?._appendContent(movies);
  }

  static void showLoading() {
    _DoubanMoviesGridState._currentInstance?._showLoading();
  }

  static void setError(String message) {
    _DoubanMoviesGridState._currentInstance?._setError(message);
  }

  @override
  State<DoubanMoviesGrid> createState() => _DoubanMoviesGridState();
}

class _DoubanMoviesGridState extends State<DoubanMoviesGrid>
    with TickerProviderStateMixin {
  List<DoubanMovie> _movies = [];
  bool _isLoading = true;
  String? _errorMessage;

  static _DoubanMoviesGridState? _currentInstance;

  @override
  void initState() {
    super.initState();
    _currentInstance = this;
  }

  @override
  void dispose() {
    if (_currentInstance == this) {
      _currentInstance = null;
    }
    super.dispose();
  }

  void _setContent(List<DoubanMovie> movies) {
    if (!mounted) return;
    setState(() {
      _movies = movies;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  void _appendContent(List<DoubanMovie> movies) {
    if (!mounted) return;
    setState(() {
      _movies.addAll(movies);
    });
  }

  void _showLoading() {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_movies.isEmpty) {
      return _buildEmptyState();
    }

    return _buildMoviesGrid();
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final double padding = 16.0;
        final double spacing = 12.0;
        final double availableWidth = screenWidth - (padding * 2) - (spacing * 2);
        final double minItemWidth = 80.0;
        final double calculatedItemWidth = availableWidth / 3;
        final double itemWidth = math.max(calculatedItemWidth, minItemWidth);
        final double itemHeight = itemWidth * 2.0;
        
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: itemWidth / itemHeight,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 6,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return _buildSkeletonCard(itemWidth);
          },
        );
      },
    );
  }

  /// 构建骨架卡片
  Widget _buildSkeletonCard(double width) {
    final double height = width * 1.5;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 封面骨架
        ShimmerEffect(
          width: width,
          height: height,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 4),
        // 标题骨架
        Center(
          child: ShimmerEffect(
            width: width * 0.8,
            height: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Color(0xFFbdc3c7),
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.movie_filter_outlined,
            size: 80,
            color: Color(0xFFbdc3c7),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无电影',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7f8c8d),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '当前分类下没有电影',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF95a5a6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final double padding = 16.0;
        final double spacing = 12.0;
        final double availableWidth = screenWidth - (padding * 2) - (spacing * 2);
        final double minItemWidth = 80.0;
        final double calculatedItemWidth = availableWidth / 3;
        final double itemWidth = math.max(calculatedItemWidth, minItemWidth);
        final double itemHeight = itemWidth * 2.0;
        
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: itemWidth / itemHeight,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 6,
          ),
          itemCount: _movies.length,
          itemBuilder: (context, index) {
            final movie = _movies[index];
            final videoInfo = movie.toVideoInfo();
            
            return VideoCard(
              videoInfo: videoInfo,
              onTap: () => widget.onVideoTap(movie.toPlayRecord()),
              from: 'douban',
              cardWidth: itemWidth,
              onGlobalMenuAction: widget.onGlobalMenuAction != null ? (action) => widget.onGlobalMenuAction!(videoInfo, action) : null,
              isFavorited: false, 
            );
          },
        );
      },
    );
  }
}
