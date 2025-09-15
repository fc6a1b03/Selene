import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/douban_movie.dart';
import '../models/play_record.dart';
import 'video_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'video_menu_bottom_sheet.dart';
import '../models/video_info.dart';
import 'shimmer_effect.dart';

class DoubanMoviesGrid extends StatelessWidget {
  final List<DoubanMovie>? movies;
  final bool isLoading;
  final String? errorMessage;
  final Function(PlayRecord) onVideoTap;
  final Function(VideoInfo, VideoMenuAction)? onGlobalMenuAction;
  final String contentType; // 'movie' 或 'tv'

  const DoubanMoviesGrid({
    super.key,
    this.movies,
    this.isLoading = false,
    this.errorMessage,
    required this.onVideoTap,
    this.onGlobalMenuAction,
    this.contentType = 'movie', // 默认为电影
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && (movies == null || movies!.isEmpty)) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (movies == null || movies!.isEmpty) {
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
            errorMessage ?? '未知错误',
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
    final bool isMovie = contentType == 'movie';
    final String contentName = isMovie ? '电影' : '剧集';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMovie ? Icons.movie_filter_outlined : Icons.tv_outlined,
            size: 80,
            color: const Color(0xFFbdc3c7),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无$contentName',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7f8c8d),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '当前分类下没有$contentName',
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
          itemCount: movies!.length,
          itemBuilder: (context, index) {
            final movie = movies![index];
            final videoInfo = movie.toVideoInfo();
            
            return VideoCard(
              videoInfo: videoInfo,
              onTap: () => onVideoTap(movie.toPlayRecord()),
              from: 'douban',
              cardWidth: itemWidth,
              onGlobalMenuAction: onGlobalMenuAction != null ? (action) => onGlobalMenuAction!(videoInfo, action) : null,
              isFavorited: false, 
            );
          },
        );
      },
    );
  }
}
