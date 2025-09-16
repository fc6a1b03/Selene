import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/play_record.dart';
import '../services/theme_service.dart';
import '../widgets/capsule_tab_switcher.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../widgets/douban_movies_grid.dart';
import '../services/douban_service.dart';
import '../models/douban_movie.dart';
import '../models/video_info.dart';
import '../widgets/video_menu_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/pulsing_dots_indicator.dart';

class SelectorOption {
  final String label;
  final String value;

  const SelectorOption({required this.label, required this.value});
}

class ShowScreen extends StatefulWidget {
  const ShowScreen({super.key});

  @override
  State<ShowScreen> createState() => _ShowScreenState();
}

class _ShowScreenState extends State<ShowScreen> {
  // 综艺一级选择器选项
  final List<SelectorOption> _showPrimaryOptions = const [
    SelectorOption(label: '全部', value: '全部'),
    SelectorOption(label: '最近热门', value: '最近热门'),
  ];

  // 综艺二级选择器选项（最近热门模式下的类型选项）
  final List<SelectorOption> _showSecondaryOptions = const [
    SelectorOption(label: '全部', value: 'show'),
    SelectorOption(label: '国内', value: 'show_domestic'),
    SelectorOption(label: '国外', value: 'show_foreign'),
  ];

  // 新的筛选选项 - 类型（全部模式下）
  final List<SelectorOption> _showTypeOptions = const [
    SelectorOption(label: '全部', value: 'all'),
    SelectorOption(label: '真人秀', value: 'reality'),
    SelectorOption(label: '脱口秀', value: 'talkshow'),
    SelectorOption(label: '音乐', value: 'music'),
    SelectorOption(label: '歌舞', value: 'musical'),
  ];

  // 地区选项（与 TV 一致）
  final List<SelectorOption> _showRegionOptions = const [
    SelectorOption(label: '全部', value: 'all'),
    SelectorOption(label: '华语', value: 'chinese'),
    SelectorOption(label: '欧美', value: 'western'),
    SelectorOption(label: '国外', value: 'foreign'),
    SelectorOption(label: '韩国', value: 'korean'),
    SelectorOption(label: '日本', value: 'japanese'),
    SelectorOption(label: '中国大陆', value: 'mainland_china'),
    SelectorOption(label: '中国香港', value: 'hong_kong'),
    SelectorOption(label: '美国', value: 'usa'),
    SelectorOption(label: '英国', value: 'uk'),
    SelectorOption(label: '泰国', value: 'thailand'),
    SelectorOption(label: '中国台湾', value: 'taiwan'),
    SelectorOption(label: '意大利', value: 'italy'),
    SelectorOption(label: '法国', value: 'france'),
    SelectorOption(label: '德国', value: 'germany'),
    SelectorOption(label: '西班牙', value: 'spain'),
    SelectorOption(label: '俄罗斯', value: 'russia'),
    SelectorOption(label: '瑞典', value: 'sweden'),
    SelectorOption(label: '巴西', value: 'brazil'),
    SelectorOption(label: '丹麦', value: 'denmark'),
    SelectorOption(label: '印度', value: 'india'),
    SelectorOption(label: '加拿大', value: 'canada'),
    SelectorOption(label: '爱尔兰', value: 'ireland'),
    SelectorOption(label: '澳大利亚', value: 'australia'),
  ];

  // 年代选项（与 TV 一致）
  final List<SelectorOption> _showYearOptions = const [
    SelectorOption(label: '全部', value: 'all'),
    SelectorOption(label: '2020年代', value: '2020s'),
    SelectorOption(label: '2025', value: '2025'),
    SelectorOption(label: '2024', value: '2024'),
    SelectorOption(label: '2023', value: '2023'),
    SelectorOption(label: '2022', value: '2022'),
    SelectorOption(label: '2021', value: '2021'),
    SelectorOption(label: '2020', value: '2020'),
    SelectorOption(label: '2019', value: '2019'),
    SelectorOption(label: '2010年代', value: '2010s'),
    SelectorOption(label: '2000年代', value: '2000s'),
    SelectorOption(label: '90年代', value: '1990s'),
    SelectorOption(label: '80年代', value: '1980s'),
    SelectorOption(label: '70年代', value: '1970s'),
    SelectorOption(label: '60年代', value: '1960s'),
    SelectorOption(label: '更早', value: 'earlier'),
  ];

  // 平台选项（与 TV 一致）
  final List<SelectorOption> _showPlatformOptions = const [
    SelectorOption(label: '全部', value: 'all'),
    SelectorOption(label: '腾讯视频', value: 'tencent'),
    SelectorOption(label: '爱奇艺', value: 'iqiyi'),
    SelectorOption(label: '优酷', value: 'youku'),
    SelectorOption(label: '湖南卫视', value: 'hunan_tv'),
    SelectorOption(label: 'Netflix', value: 'netflix'),
    SelectorOption(label: 'HBO', value: 'hbo'),
    SelectorOption(label: 'BBC', value: 'bbc'),
    SelectorOption(label: 'NHK', value: 'nhk'),
    SelectorOption(label: 'CBS', value: 'cbs'),
    SelectorOption(label: 'NBC', value: 'nbc'),
    SelectorOption(label: 'tvN', value: 'tvn'),
  ];

  // 排序选项（与 TV 一致）
  final List<SelectorOption> _showSortOptions = const [
    SelectorOption(label: '综合排序', value: 'T'),
    SelectorOption(label: '近期热度', value: 'U'),
    SelectorOption(label: '首播时间', value: 'R'),
    SelectorOption(label: '高分优先', value: 'S'),
  ];

  String _selectedCategoryValue = '最近热门'; // 默认选中最近热门
  String _selectedRegionValue = 'show'; // 二级筛选默认选中全部

  // 新版筛选状态
  String _selectedShowType = 'all';
  String _selectedShowRegion = 'all';
  String _selectedShowYear = 'all';
  String _selectedShowPlatform = 'all';
  String _selectedShowSort = 'T';

  final ScrollController _scrollController = ScrollController();
  final List<DoubanMovie> _shows = [];
  int _page = 0;
  final int _pageLimit = 25;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  /// 获取当前筛选状态
  String _getCurrentFilterState() {
    return '$_selectedCategoryValue|$_selectedRegionValue|$_selectedShowType|$_selectedShowRegion|$_selectedShowYear|$_selectedShowPlatform|$_selectedShowSort';
  }

  @override
  void initState() {
    super.initState();
    _fetchShows(isRefresh: true);
    _scrollController.addListener(() {
      _handleScroll();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 处理滚动事件，支持内容不足一屏时的加载更多
  void _handleScroll() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      
      // 如果内容不足以滚动（maxScrollExtent <= 0），直接尝试加载更多
      if (position.maxScrollExtent <= 0) {
        // 检查是否有更多数据且当前不在加载中
        if (_hasMore && !_isLoading && !_isLoadingMore && _shows.isNotEmpty) {
          _loadMoreShows();
        }
        return;
      }
      
      // 正常滚动情况：当滚动到距离底部50像素内时触发加载
      const double threshold = 50.0;
      if (position.pixels >= position.maxScrollExtent - threshold) {
        _loadMoreShows();
      }
    }
  }

  /// 检查内容是否不足一屏，如果是则自动加载更多
  void _checkAndLoadMoreIfNeeded() {
    if (!_scrollController.hasClients || !_hasMore || _isLoading || _isLoadingMore) {
      return;
    }
    
    final position = _scrollController.position;
    
    // 如果内容不足以滚动，说明没有填满屏幕，自动加载更多
    if (position.maxScrollExtent <= 0 && _shows.isNotEmpty) {
      _loadMoreShows();
    }
  }

  Future<void> _fetchShows({bool isRefresh = false}) async {
    // 记录发起请求时的筛选状态
    final requestFilterState = _getCurrentFilterState();

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _shows.clear();
        _page = 0;
        _hasMore = true;
      }
      _errorMessage = null;
    });

    if (_selectedCategoryValue == '全部') {
      // 将界面选项转换为豆瓣API参数
      String categoryValue = _selectedShowType;
      String regionValue = _selectedShowRegion;
      String yearValue = _selectedShowYear;
      String platformValue = _selectedShowPlatform;
      
      // 转换地区参数为中文标签
      if (regionValue != 'all') {
        regionValue = _showRegionOptions
            .firstWhere((e) => e.value == regionValue)
            .label;
      }
      
      // 转换年代参数为中文标签
      if (yearValue != 'all') {
        yearValue = _showYearOptions
            .firstWhere((e) => e.value == yearValue)
            .label;
      }
      
      // 转换类型参数为中文标签
      if (categoryValue != 'all') {
        categoryValue = _showTypeOptions
            .firstWhere((e) => e.value == categoryValue)
            .label;
      }
      // 转换平台参数为中文标签
      if (platformValue != 'all') {
        platformValue = _showPlatformOptions
            .firstWhere((e) => e.value == platformValue)
            .label;
      }
      
      final params = DoubanRecommendsParams(
        kind: 'tv',
        category: categoryValue,
        format: '综艺',
        region: regionValue,
        year: yearValue,
        platform: platformValue,
        sort: _selectedShowSort,
        pageLimit: _pageLimit,
        page: _page,
      );
      
      final result = await DoubanService.fetchDoubanRecommends(
        context,
        params,
      );
      if (mounted) {
        // 检查当前筛选状态是否仍然与发起请求时一致
        if (requestFilterState != _getCurrentFilterState()) {
          // 筛选状态已改变，忽略这个过期的响应
          return;
        }
        
        setState(() {
          if (result.success && result.data != null) {
            _shows.addAll(result.data!);
            _page++;
            // 只有当返回的数据为空时才停止分页
            if (result.data!.isEmpty) {
              _hasMore = false;
            }
          } else {
            _errorMessage = result.message ?? '加载失败';
          }
          _isLoading = false;
        });
        
        // 如果是刷新且内容不足一屏，尝试自动加载更多
        if (isRefresh && result.success && result.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndLoadMoreIfNeeded();
          });
        }
      }
    } else {
      final result = await DoubanService.getCategoryData(
        context,
        kind: 'tv',
        category: 'show',
        type: _selectedRegionValue,
        page: _page,
        pageLimit: _pageLimit,
      );

      if (mounted) {
        // 检查当前筛选状态是否仍然与发起请求时一致
        if (requestFilterState != _getCurrentFilterState()) {
          // 筛选状态已改变，忽略这个过期的响应
          return;
        }
        
        setState(() {
          if (result.success && result.data != null) {
            _shows.addAll(result.data!);
            _page++;
            // 只有当返回的数据为空时才停止分页
            if (result.data!.isEmpty) {
              _hasMore = false;
            }
          } else {
            _errorMessage = result.message ?? '加载失败';
          }
          _isLoading = false;
        });
        
        // 如果是刷新且内容不足一屏，尝试自动加载更多
        if (isRefresh && result.success && result.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndLoadMoreIfNeeded();
          });
        }
      }
    }
  }

  Future<void> _loadMoreShows() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    // 记录发起请求时的筛选状态
    final requestFilterState = _getCurrentFilterState();

    setState(() {
      _isLoadingMore = true;
    });

    if (_selectedCategoryValue == '全部') {
      // 将界面选项转换为豆瓣API参数
      String categoryValue = _selectedShowType;
      String regionValue = _selectedShowRegion;
      String yearValue = _selectedShowYear;
      String platformValue = _selectedShowPlatform;
      
      // 转换地区参数为中文标签
      if (regionValue != 'all') {
        regionValue = _showRegionOptions
            .firstWhere((e) => e.value == regionValue)
            .label;
      }
      
      // 转换年代参数为中文标签
      if (yearValue != 'all') {
        yearValue = _showYearOptions
            .firstWhere((e) => e.value == yearValue)
            .label;
      }
      
      // 转换类型参数为中文标签
      if (categoryValue != 'all') {
        categoryValue = _showTypeOptions
            .firstWhere((e) => e.value == categoryValue)
            .label;
      }
      // 转换平台参数为中文标签
      if (platformValue != 'all') {
        platformValue = _showPlatformOptions
            .firstWhere((e) => e.value == platformValue)
            .label;
      }
      
      final params = DoubanRecommendsParams(
        kind: 'tv',
        category: categoryValue,
        format: '综艺',
        region: regionValue,
        year: yearValue,
        platform: platformValue,
        sort: _selectedShowSort,
        pageLimit: _pageLimit,
        page: _page,
      );
      
      final result = await DoubanService.fetchDoubanRecommends(
        context,
        params,
      );
      if (mounted) {
        // 检查当前筛选状态是否仍然与发起请求时一致
        if (requestFilterState != _getCurrentFilterState()) {
          // 筛选状态已改变，忽略这个过期的响应
          return;
        }
        
        setState(() {
          if (result.success && result.data != null) {
            _shows.addAll(result.data!);
            _page++;
            // 只有当返回的数据为空时才停止分页
            if (result.data!.isEmpty) {
              _hasMore = false;
            }
          } else {
            // Can show a toast or a small error indicator at the bottom
          }
          _isLoadingMore = false;
        });
      }
    } else {
      final result = await DoubanService.getCategoryData(
        context,
        kind: 'tv',
        category: 'show',
        type: _selectedRegionValue,
        page: _page,
        pageLimit: _pageLimit,
      );

      if (mounted) {
        // 检查当前筛选状态是否仍然与发起请求时一致
        if (requestFilterState != _getCurrentFilterState()) {
          // 筛选状态已改变，忽略这个过期的响应
          return;
        }
        
        setState(() {
          if (result.success && result.data != null) {
            _shows.addAll(result.data!);
            _page++;
            // 只有当返回的数据为空时才停止分页
            if (result.data!.isEmpty) {
              _hasMore = false;
            }
          } else {
            // Can show a toast or a small error indicator at the bottom
          }
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refreshShowsData() async {
    await _fetchShows(isRefresh: true);
  }

  void _onVideoTap(PlayRecord playRecord) {
    // Implement video tap logic
  }

  void _handleMenuAction(VideoInfo videoInfo, VideoMenuAction action) {
    switch (action) {
      case VideoMenuAction.play:
        _onVideoTap(PlayRecord(
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
        ));
        break;
      case VideoMenuAction.doubanDetail:
        _launchURL('https://movie.douban.com/subject/${videoInfo.id}/');
        break;
      default:
        break;
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyledRefreshIndicator(
      onRefresh: _refreshShowsData,
      refreshText: '刷新综艺数据...',
      primaryColor: const Color(0xFF27AE60),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilterSection(),
            const SizedBox(height: 16),
            DoubanMoviesGrid(
              movies: _shows,
              isLoading: _isLoading && _shows.isEmpty,
              errorMessage: _errorMessage,
              onVideoTap: _onVideoTap,
              onGlobalMenuAction: (videoInfo, action) {
                _handleMenuAction(videoInfo, action);
              },
              contentType: 'show',
            ),
            // 底部指示器 - 加载更多或到底提示
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: PulsingDotsIndicator(),
              )
            else if (!_hasMore && _shows.isNotEmpty && !_isLoading)
              _buildEndOfListIndicator()
            else
              const SizedBox(height: 50), // 占位符保持间距
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
                    '综艺',
                    style: GoogleFonts.poppins(
              fontSize: 28,
                      fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 20, // 固定高度确保一致性
            child: Text(
              '来自豆瓣的精选内容',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final themeService = Provider.of<ThemeService>(context);
    return Container(
      width: double.infinity, // 设置为100%宽度
      margin: const EdgeInsets.all(16), // 恢复原来的margin设置
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // 恢复原来的padding设置
                    decoration: BoxDecoration(
        color: themeService.isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
          _buildFilterRow(
            '分类',
            _showPrimaryOptions,
            _selectedCategoryValue,
            (newValue) {
              setState(() {
                _selectedCategoryValue = newValue;
                // 重置二级筛选为默认值
                _selectedRegionValue = 'show'; // 胶囊筛选默认值
                _selectedShowType = 'all'; // 多级筛选默认值
                _selectedShowRegion = 'all';
                _selectedShowYear = 'all';
                _selectedShowPlatform = 'all';
                _selectedShowSort = 'T';
              });
              _fetchShows(isRefresh: true);
            },
          ),
                          const SizedBox(height: 16),
          // 使用固定高度的容器来避免高度跳跃
          SizedBox(
            height: 66, // 增加高度以避免Column底部溢出
            child: _selectedCategoryValue == '全部'
                ? _buildAdvancedFilterSection()
                : _buildSimpleFilterSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                          Text(
          '筛选',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill('类型', _showTypeOptions, _selectedShowType, (v) {
                  setState(() => _selectedShowType = v);
                  _fetchShows(isRefresh: true);
                }),
                _buildFilterPill('地区', _showRegionOptions, _selectedShowRegion, (v) {
                  setState(() => _selectedShowRegion = v);
                  _fetchShows(isRefresh: true);
                }),
                _buildFilterPill('年代', _showYearOptions, _selectedShowYear, (v) {
                  setState(() => _selectedShowYear = v);
                  _fetchShows(isRefresh: true);
                }),
                _buildFilterPill('平台', _showPlatformOptions, _selectedShowPlatform, (v) {
                  setState(() => _selectedShowPlatform = v);
                  _fetchShows(isRefresh: true);
                }),
                _buildFilterPill('排序', _showSortOptions, _selectedShowSort, (v) {
                  setState(() => _selectedShowSort = v);
                  _fetchShows(isRefresh: true);
                }),
                        ],
                      ),
                    ),
                  ),
                ],
    );
  }

  Widget _buildSimpleFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '类型',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 6), // 减少间距，与高级筛选保持一致
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CapsuleTabSwitcher(
            tabs: _showSecondaryOptions.map((e) => e.label).toList(),
            selectedTab: _showSecondaryOptions.firstWhere((e) => e.value == _selectedRegionValue).label,
            onTabChanged: (newLabel) {
              final newValue = _showSecondaryOptions.firstWhere((e) => e.label == newLabel).value;
              setState(() {
                _selectedRegionValue = newValue;
              });
              _fetchShows(isRefresh: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String title, List<SelectorOption> options,
      String selectedValue, ValueChanged<String> onSelected) {
    final selectedOption = options.firstWhere((e) => e.value == selectedValue,
        orElse: () => options.first);
    bool isDefault = selectedValue == 'all' ||
        (title == '排序' && selectedValue == 'T');

    return GestureDetector(
      onTap: () {
        _showFilterOptions(context, title, options, selectedValue, onSelected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              isDefault ? title : selectedOption.label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDefault
                    ? Theme.of(context).textTheme.bodySmall?.color
                    : const Color(0xFF27AE60),
                fontWeight: isDefault ? FontWeight.normal : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isDefault
                  ? Theme.of(context).textTheme.bodySmall?.color
                  : const Color(0xFF27AE60),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions(
      BuildContext context,
      String title,
      List<SelectorOption> options,
      String selectedValue,
      ValueChanged<String> onSelected) {
    // 计算需要的行数
    final rowCount = (options.length / 4).ceil();
    // 计算GridView的高度：行数 * (item高度 + 间距) + padding
    final gridHeight = rowCount * (40.0 + 10.0) - 10.0 + 32.0; // 32.0是上下padding
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(title, style: Theme.of(context).textTheme.titleLarge),
              ),
              Container(
                height: gridHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option.value == selectedValue;
                    return InkWell(
                      onTap: () {
                        onSelected(option.value);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF27AE60)
                              : Theme.of(context).chipTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          option.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16), // 底部间距
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterRow(
    String title,
    List<SelectorOption> items,
    String selectedValue,
    Function(String) onItemSelected,
  ) {
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
            tabs: items.map((e) => e.label).toList(),
            selectedTab: items.firstWhere((e) => e.value == selectedValue).label,
            onTabChanged: (newLabel) {
              final newValue = items.firstWhere((e) => e.label == newLabel).value;
              onItemSelected(newValue);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEndOfListIndicator() {
    final themeService = Provider.of<ThemeService>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // 减少顶部padding，保持底部padding与加载指示器一致
      child: Column(
        children: [
          Container(
            width: 60,
            height: 2,
            decoration: BoxDecoration(
              color: themeService.isDarkMode
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '已经到底啦~',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: themeService.isDarkMode
                  ? Colors.white.withOpacity(0.6)
                  : Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '共 ${_shows.length} 个综艺',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: themeService.isDarkMode
                  ? Colors.white.withOpacity(0.4)
                  : Colors.grey[500],
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
