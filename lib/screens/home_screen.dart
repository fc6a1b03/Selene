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
import 'search_screen.dart';
import '../widgets/video_menu_bottom_sheet.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import '../services/page_cache_service.dart';
import 'movie_screen.dart';
import 'tv_screen.dart';
import 'anime_screen.dart';
import 'show_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBottomNavIndex = 0;
  String _selectedTopTab = '首页';
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    // 进入首页时直接刷新播放记录和收藏夹缓存
    _refreshCacheOnHomeEnter();
  }

  /// 进入首页时刷新缓存
  Future<void> _refreshCacheOnHomeEnter() async {
    try {
      final cacheService = PageCacheService();
      
      // 异步刷新播放记录缓存
      cacheService.refreshPlayRecords(context).then((_) {
        // 刷新成功后通知继续观看组件更新UI
        if (mounted) {
          ContinueWatchingSection.refreshPlayRecords();
        }
      }).catchError((e) {
        // 静默处理错误
      });
      
      // 异步刷新收藏夹缓存
      cacheService.refreshFavorites(context).then((_) {
        // 刷新成功后通知收藏夹组件更新UI
        if (mounted) {
          FavoritesGrid.refreshFavorites();
        }
      }).catchError((e) {
        // 静默处理错误
      });

      // 异步刷新搜索历史缓存
      cacheService.refreshSearchHistory(context).catchError((e) {
        // 静默处理错误
      });
    } catch (e) {
      // 静默处理错误，不影响首页正常显示
    }
  }

  /// 刷新首页数据
  Future<void> _refreshHomeData() async {
    try {
      // 调用各个组件的刷新方法
      if (mounted) {
        // 刷新继续观看组件
        await ContinueWatchingSection.refreshPlayRecords();
        
        // 刷新收藏夹组件
        await FavoritesGrid.refreshFavorites();
        
        // 刷新热门电影组件
        await HotMoviesSection.refreshHotMovies();
        
        // 刷新热门剧集组件
        await HotTvSection.refreshHotTvShows();
        
        // 刷新新番放送组件
        await BangumiSection.refreshBangumiCalendar();
        
        // 刷新热门综艺组件
        await HotShowSection.refreshHotShows();
        
        // 强制重建页面
        setState(() {});
      }
    } catch (e) {
      // 刷新失败，静默处理
    }
  }

  /// 重新构建首页内容（用于顶部标签切换）
  Widget _buildHomeContentForTab(String tab) {
    return StyledRefreshIndicator(
      onRefresh: _refreshHomeData,
      refreshText: '刷新中...',
      primaryColor: const Color(0xFF27AE60), // 绿色主题
      child: SingleChildScrollView(
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
                      const SizedBox(height: 8),
                      // 继续观看组件
                      ContinueWatchingSection(
                        onVideoTap: _onVideoTap,
                        onGlobalMenuAction: _onGlobalMenuAction,
                      ),
                      // 热门电影组件
                      HotMoviesSection(
                        onMovieTap: _onVideoTap,
                        onMoreTap: () => _onBottomNavChanged(1), // 切换到电影页面
                        onGlobalMenuAction: (videoInfo, action) => _onGlobalMenuActionFromVideoInfo(videoInfo, action),
                      ),
                      // 热门剧集组件
                      HotTvSection(
                        onTvTap: _onVideoTap,
                        onMoreTap: () => _onBottomNavChanged(2), // 切换到剧集页面
                        onGlobalMenuAction: (videoInfo, action) => _onGlobalMenuActionFromVideoInfo(videoInfo, action),
                      ),
                      // 新番放送组件
                      BangumiSection(
                        onBangumiTap: _onVideoTap,
                        onMoreTap: () => _onBottomNavChanged(3), // 切换到动漫页面
                        onGlobalMenuAction: (videoInfo, action) {
                          // 转换为PlayRecord用于处理
                          final playRecord = PlayRecord(
                            id: videoInfo.id,
                            source: videoInfo.source,
                            title: videoInfo.title,
                            sourceName: videoInfo.sourceName,
                            year: videoInfo.year,
                            cover: videoInfo.cover,
                            index: videoInfo.index,
                            totalEpisodes: videoInfo.totalEpisodes,
                            playTime: videoInfo.playTime,
                            totalTime: videoInfo.totalTime,
                            saveTime: videoInfo.saveTime,
                            searchTitle: videoInfo.searchTitle,
                          );
                          _onGlobalMenuAction(playRecord, action);
                        },
                      ),
                      // 热门综艺组件
                      HotShowSection(
                        onShowTap: _onVideoTap,
                        onMoreTap: () => _onBottomNavChanged(4), // 切换到综艺页面
                        onGlobalMenuAction: (videoInfo, action) => _onGlobalMenuActionFromVideoInfo(videoInfo, action),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const SizedBox(height: 4), // 收藏夹内容更靠近切换按钮
                      FavoritesGrid(
                        onVideoTap: _onVideoTap,
                        onGlobalMenuAction: (VideoInfo videoInfo, VideoMenuAction action) {
                          // 将VideoInfo转换为PlayRecord用于统一处理
                          final playRecord = PlayRecord(
                            id: videoInfo.id,
                            source: videoInfo.source,
                            title: videoInfo.title,
                            sourceName: videoInfo.sourceName,
                            year: videoInfo.year,
                            cover: videoInfo.cover,
                            index: videoInfo.index,
                            totalEpisodes: videoInfo.totalEpisodes,
                            playTime: videoInfo.playTime,
                            totalTime: videoInfo.totalTime,
                            saveTime: videoInfo.saveTime,
                            searchTitle: videoInfo.searchTitle,
                          );
                          _onGlobalMenuAction(playRecord, action);
                        },
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      content: _isSearchMode
          ? _buildSearchContent()
          : _buildCurrentPage(),
      currentBottomNavIndex: _currentBottomNavIndex,
      onBottomNavChanged: _onBottomNavChanged,
      selectedTopTab: _selectedTopTab,
      onTopTabChanged: _onTopTabChanged,
      isSearchMode: _isSearchMode,
      onSearchModeChanged: _onSearchModeChanged,
      onHomeTap: _onHomeTap,
    );
  }

  /// 根据当前页面索引动态构建页面内容
  Widget _buildCurrentPage() {
    switch (_currentBottomNavIndex) {
      case 0:
        return _buildHomeContentForTab(_selectedTopTab);
      case 1:
        return const MovieScreen();
      case 2:
        return const TvScreen();
      case 3:
        return const AnimeScreen();
      case 4:
        return const ShowScreen();
      default:
        return const AnimeScreen();
    }
  }

  /// 处理底部导航栏切换
  void _onBottomNavChanged(int index) {
    // 防止重复点击同一个标签
    if (_currentBottomNavIndex == index && !_isSearchMode) {
      return;
    }
    
    setState(() {
      // 如果在搜索模式下，先退出搜索模式
      if (_isSearchMode) {
        _isSearchMode = false;
      }
      _currentBottomNavIndex = index;
    });
  }

  /// 处理顶部标签切换
  void _onTopTabChanged(String tab) {
    // 防止重复点击同一个标签
    if (_selectedTopTab == tab) {
      return;
    }
    
    setState(() {
      _selectedTopTab = tab;
    });
  }

  /// 处理搜索模式切换
  void _onSearchModeChanged(bool isSearchMode) {
    setState(() {
      _isSearchMode = isSearchMode;
    });
  }

  /// 处理点击 Selene 标题跳转到首页
  void _onHomeTap() {
    setState(() {
      // 如果在搜索模式下，先退出搜索模式
      if (_isSearchMode) {
        _isSearchMode = false;
      }
      // 切换到首页
      _currentBottomNavIndex = 0;
      // 切换到首页标签
      _selectedTopTab = '首页';
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

  /// 处理来自VideoInfo的全局菜单操作
  void _onGlobalMenuActionFromVideoInfo(VideoInfo videoInfo, VideoMenuAction action) {
    // 将VideoInfo转换为PlayRecord用于统一处理
    final playRecord = PlayRecord(
      id: videoInfo.id,
      source: videoInfo.source,
      title: videoInfo.title,
      sourceName: videoInfo.sourceName,
      year: videoInfo.year,
      cover: videoInfo.cover,
      index: videoInfo.index,
      totalEpisodes: videoInfo.totalEpisodes,
      playTime: videoInfo.playTime,
      totalTime: videoInfo.totalTime,
      saveTime: videoInfo.saveTime,
      searchTitle: videoInfo.searchTitle,
    );
    _onGlobalMenuAction(playRecord, action);
  }

  /// 处理视频菜单操作
  void _onGlobalMenuAction(PlayRecord playRecord, VideoMenuAction action) {
    switch (action) {
      case VideoMenuAction.play:
        // 播放视频
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '播放: ${playRecord.title}',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        break;
      case VideoMenuAction.favorite:
        // 收藏
        _handleFavorite(playRecord);
        break;
      case VideoMenuAction.unfavorite:
        // 取消收藏
        _handleUnfavorite(playRecord);
        break;
      case VideoMenuAction.deleteRecord:
        // 删除记录
        _deletePlayRecord(playRecord);
        break;
      case VideoMenuAction.doubanDetail:
        // 豆瓣详情 - 已在组件内部处理URL跳转
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '正在打开豆瓣详情: ${playRecord.title}',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF3498DB),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        break;
      case VideoMenuAction.bangumiDetail:
        // Bangumi详情 - 已在组件内部处理URL跳转
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '正在打开 Bangumi 详情: ${playRecord.title}',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF3498DB),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        break;
    }
  }

  /// 处理搜索结果视频卡片点击
  void _onSearchVideoTap(VideoInfo videoInfo) {
    // TODO: 实现搜索结果视频播放逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '点击了搜索结果: ${videoInfo.title}',
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

  /// 构建搜索内容
  Widget _buildSearchContent() {
    return SearchScreen(
      onVideoTap: _onSearchVideoTap,
    );
  }

  /// 从继续观看UI中移除播放记录
  void _removePlayRecordFromUI(PlayRecord playRecord) {
    // 调用继续观看组件的静态移除方法
    ContinueWatchingSection.removePlayRecordFromUI(
      playRecord.source, 
      playRecord.id
    );
  }

  /// 删除播放记录
  Future<void> _deletePlayRecord(PlayRecord playRecord) async {
    try {
      // 先从UI中移除记录
      _removePlayRecordFromUI(playRecord);
      
      // 使用统一的删除方法（包含缓存操作和API调用）
      final cacheService = PageCacheService();
      final result = await cacheService.deletePlayRecord(
        playRecord.source,
        playRecord.id,
        context,
      );
      
      if (!result.success) {
        throw Exception(result.errorMessage ?? '删除失败');
      }
    } catch (e) {
      // 删除失败时显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '删除失败: ${e.toString()}',
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
    } finally {
      // 异步刷新播放记录缓存
      if (mounted) {
        _refreshPlayRecordsCache();
      }
    }
  }

  /// 异步刷新播放记录缓存
  Future<void> _refreshPlayRecordsCache() async {
    try {
      final cacheService = PageCacheService();
      await cacheService.refreshPlayRecords(context);
    } catch (e) {
      // 刷新缓存失败，静默处理
    }
  }

  /// 处理收藏
  Future<void> _handleFavorite(PlayRecord playRecord) async {
    try {
      // 构建收藏数据
      final favoriteData = {
        'cover': playRecord.cover,
        'save_time': DateTime.now().millisecondsSinceEpoch,
        'source_name': playRecord.sourceName,
        'title': playRecord.title,
        'total_episodes': playRecord.totalEpisodes,
        'year': playRecord.year,
      };

      // 使用统一的收藏方法（包含缓存操作和API调用）
      final cacheService = PageCacheService();
      final result = await cacheService.addFavorite(playRecord.source, playRecord.id, favoriteData, context);

      if (result.success) {
        // 通知UI刷新收藏状态
        if (mounted) {
          setState(() {});
        }
      } else {
        // 显示错误提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.errorMessage ?? '收藏失败',
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
        _refreshFavorites();
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '收藏失败: ${e.toString()}',
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
      _refreshFavorites();
    }
  }

  /// 处理取消收藏
  Future<void> _handleUnfavorite(PlayRecord playRecord) async {
    try {
      // 先立即从UI中移除该项目
      FavoritesGrid.removeFavoriteFromUI(playRecord.source, playRecord.id);
      
      // 通知继续观看组件刷新收藏状态
      if (mounted) {
        setState(() {});
      }
      
      // 使用统一的取消收藏方法（包含缓存操作和API调用）
      final cacheService = PageCacheService();
      final result = await cacheService.removeFavorite(playRecord.source, playRecord.id, context);

      if (!result.success) {
        // 显示错误提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.errorMessage ?? '取消收藏失败',
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
        // API失败时重新刷新缓存以恢复数据
        _refreshFavorites();
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '取消收藏失败: ${e.toString()}',
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
      // 异常时重新刷新缓存以恢复数据
      _refreshFavorites();
    }
  }

  /// 异步刷新收藏夹数据
  Future<void> _refreshFavorites() async {
    try {
      // 刷新收藏夹缓存数据
      await PageCacheService().refreshFavorites(context);
      
      // 通知收藏夹组件刷新UI
      FavoritesGrid.refreshFavorites();
    } catch (e) {
      // 错误处理，静默处理
    }
  }

}
