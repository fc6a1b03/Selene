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

  // 预加载所有页面，使用IndexedStack保持状态
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  void _initializePages() {
    _pages = [
      const SizedBox.shrink(), // 首页内容由 _buildHomeContentForTab 动态生成
      const MoviesScreen(),
      const SeriesScreen(),
      const AnimeScreen(),
      const VarietyScreen(),
    ];
  }

  /// 重新构建首页内容（用于顶部标签切换）
  Widget _buildHomeContentForTab(String tab) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 顶部导航栏
          TopTabSwitcher(
            selectedTab: tab,
            onTabChanged: _onTopTabChanged,
          ),
          // 根据选中的标签显示不同内容
          tab == '首页'
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
                      onMoreTap: () => _onBottomNavChanged(1), // 切换到电影页面
                    ),
                    // 热门剧集组件
                    HotTvSection(
                      onTvTap: _onVideoTap,
                      onMoreTap: () => _onBottomNavChanged(2), // 切换到剧集页面
                    ),
                    // 新番放送组件
                    BangumiSection(
                      onBangumiTap: _onVideoTap,
                      onMoreTap: () => _onBottomNavChanged(3), // 切换到动漫页面
                    ),
                    // 热门综艺组件
                    HotShowSection(
                      onShowTap: _onVideoTap,
                      onMoreTap: () => _onBottomNavChanged(4), // 切换到综艺页面
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

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      content: _currentBottomNavIndex == 0 
          ? _buildHomeContentForTab(_selectedTopTab)
          : IndexedStack(
              index: _currentBottomNavIndex,
              children: _pages,
            ),
      currentBottomNavIndex: _currentBottomNavIndex,
      onBottomNavChanged: _onBottomNavChanged,
      selectedTopTab: _selectedTopTab,
      onTopTabChanged: _onTopTabChanged,
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
