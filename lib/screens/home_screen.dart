import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/continue_watching_section.dart';
import '../widgets/hot_movies_section.dart';
import '../widgets/hot_tv_section.dart';
import '../widgets/hot_show_section.dart';
import '../widgets/bangumi_section.dart';
import '../widgets/main_layout.dart';
import '../widgets/top_tab_switcher.dart';
import '../widgets/favorites_grid.dart';
import '../models/play_record.dart';
import 'movies_screen.dart';
import 'series_screen.dart';
import 'anime_screen.dart';
import 'variety_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBottomNavIndex = 0;
  String _selectedTopTab = '首页';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      content: _buildMainContent(),
      currentBottomNavIndex: _currentBottomNavIndex,
      onBottomNavChanged: _onBottomNavChanged,
      selectedTopTab: _selectedTopTab,
      onTopTabChanged: _onTopTabChanged,
    );
  }


  Widget _buildMainContent() {
    // 根据底部导航栏选择显示不同的页面内容
    switch (_currentBottomNavIndex) {
      case 0: // 首页
        return _buildHomeContent();
      case 1: // 电影
        return const MoviesScreen();
      case 2: // 剧集
        return const SeriesScreen();
      case 3: // 动漫
        return const AnimeScreen();
      case 4: // 综艺
        return const VarietyScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 顶部导航栏
          TopTabSwitcher(
            selectedTab: _selectedTopTab,
            onTabChanged: _onTopTabChanged,
          ),
          // 根据选中的标签显示不同内容
          _selectedTopTab == '首页'
              ? Column(
                  children: [
                    const SizedBox(height: 20),
                    // 继续观看组件
                    ContinueWatchingSection(
                      onVideoTap: _onVideoTap,
                    ),
                    // 热门电影组件
                    HotMoviesSection(
                      onMovieTap: _onVideoTap,
                    ),
                    // 热门剧集组件
                    HotTvSection(
                      onTvTap: _onVideoTap,
                    ),
                    // 新番放送组件
                    BangumiSection(
                      onBangumiTap: _onVideoTap,
                    ),
                    // 热门综艺组件
                    HotShowSection(
                      onShowTap: _onVideoTap,
                    ),
                  ],
                )
              : Column(
                  children: [
                    const SizedBox(height: 8), // 收藏夹内容更靠近切换按钮
                    FavoritesGrid(
                      onVideoTap: _onVideoTap,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  /// 处理底部导航栏切换
  void _onBottomNavChanged(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });
  }

  /// 处理顶部标签切换
  void _onTopTabChanged(String tab) {
    setState(() {
      _selectedTopTab = tab;
    });
  }


  /// 处理视频卡片点击
  void _onVideoTap(PlayRecord playRecord) {
    // TODO: 实现视频播放逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '点击了: ${playRecord.title}',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2c3e50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

}
