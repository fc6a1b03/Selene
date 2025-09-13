import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/play_record.dart';
import '../services/theme_service.dart';
import '../widgets/capsule_tab_switcher.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../widgets/douban_movies_grid.dart';
import '../models/douban_movie.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  String _selectedCategory = '热门电影';
  String _selectedRegion = '全部';

  final List<String> _categories = ['全部', '热门电影', '最新电影', '豆瓣高分', '冷门佳片'];
  final List<String> _regions = ['全部', '华语', '欧美', '韩国', '日本'];

  final List<DoubanMovie> _mockMovies = const [
    DoubanMovie(
      id: '36591322',
      title: '凶器',
      poster: 'https://img1.doubanio.com/view/photo/s_ratio_poster/public/p2901458977.webp',
      rate: '7.0',
      year: '2025',
    ),
    DoubanMovie(
      id: '35611315',
      title: '小人物2',
      poster: 'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2903442824.webp',
      rate: '6.3',
      year: '2025',
    ),
    DoubanMovie(
      id: '35688544',
      title: '天国与地狱',
      poster: 'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2903858836.webp',
      rate: '6.1',
      year: '2025',
    ),
    DoubanMovie(
      id: '36353361',
      title: '知晓亦无妨',
      poster: 'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2888439245.webp',
      rate: '6.5',
      year: '2024',
    ),
    DoubanMovie(
      id: '35613883',
      title: '心如此星',
      poster: 'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2904639334.webp',
      rate: '6.5',
      year: '2024',
    ),
    DoubanMovie(
      id: '35579255',
      title: '星期四谋杀俱乐部',
      poster: 'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2904323674.webp',
      rate: '6.8',
      year: '2025',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  Future<void> _fetchMovies() async {
    DoubanMoviesGrid.showLoading();
    await Future.delayed(const Duration(seconds: 1));
    DoubanMoviesGrid.setContent(_mockMovies);
  }

  Future<void> _refreshMoviesData() async {
    await _fetchMovies();
  }

  void _onVideoTap(PlayRecord playRecord) {
    // Implement video tap logic
  }

  @override
  Widget build(BuildContext context) {
    return StyledRefreshIndicator(
      onRefresh: _refreshMoviesData,
      refreshText: '刷新电影数据...',
      primaryColor: const Color(0xFF27AE60),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilterSection(),
            const SizedBox(height: 16),
            DoubanMoviesGrid(
              category: _selectedCategory,
              region: _selectedRegion,
              onVideoTap: _onVideoTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '电影',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '来自豆瓣的精选内容',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final themeService = Provider.of<ThemeService>(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: themeService.isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterRow('分类', _categories, _selectedCategory, (newCategory) {
            setState(() {
              _selectedCategory = newCategory;
            });
            _fetchMovies();
          }),
          const SizedBox(height: 16),
          _buildFilterRow('地区', _regions, _selectedRegion, (newRegion) {
            setState(() {
              _selectedRegion = newRegion;
            });
            _fetchMovies();
          }),
        ],
      ),
    );
  }

  Widget _buildFilterRow(String title, List<String> items, String selectedItem,
      Function(String) onItemSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CapsuleTabSwitcher(
            tabs: items,
            selectedTab: selectedItem,
            onTabChanged: onItemSelected,
          ),
        ),
      ],
    );
  }
}
