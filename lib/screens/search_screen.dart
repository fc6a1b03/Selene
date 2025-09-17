import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/page_cache_service.dart';
import '../services/theme_service.dart';
import '../services/sse_search_service.dart';
import '../models/search_result.dart';
import '../models/video_info.dart';
import '../widgets/video_card.dart';
import '../widgets/video_menu_bottom_sheet.dart';
import '../widgets/favorites_grid.dart';
import '../widgets/search_result_agg_grid.dart';

class SelectorOption {
  final String label;
  final String value;

  const SelectorOption({required this.label, required this.value});
}

enum SortOrder { none, asc, desc }

class SearchScreen extends StatefulWidget {
  final Function(VideoInfo)? onVideoTap;

  const SearchScreen({
    super.key,
    this.onVideoTap,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  List<String> _searchHistory = [];
  List<SearchResult> _searchResults = [];
  bool _hasSearched = false;
  bool _hasReceivedStart = false; // 是否已收到start消息
  String? _searchError;
  SearchProgress? _searchProgress;
  Timer? _updateTimer; // 用于防抖的定时器
  bool _useAggregatedView = true; // 是否使用聚合视图，默认开启

  // 筛选和排序状态
  String _selectedSource = 'all';
  String _selectedYear = 'all';
  String _selectedTitle = 'all';
  SortOrder _yearSortOrder = SortOrder.none;

  // 长按删除相关状态
  String? _deletingHistoryItem;
  AnimationController? _deleteAnimationController;
  Animation<double>? _deleteAnimation;

  late SSESearchService _searchService;
  StreamSubscription<List<SearchResult>>? _incrementalResultsSubscription;
  StreamSubscription<SearchProgress>? _progressSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<SearchEvent>? _eventSubscription;

  List<SearchResult> get _filteredSearchResults {
    List<SearchResult> results = List.from(_searchResults);

    // Source filter
    if (_selectedSource != 'all') {
      results = results.where((r) => r.sourceName == _selectedSource).toList();
    }

    // Year filter
    if (_selectedYear != 'all') {
      results = results.where((r) => r.year == _selectedYear).toList();
    }

    // Title filter
    if (_selectedTitle != 'all') {
      results = results.where((r) => r.title == _selectedTitle).toList();
    }

    // Year sort
    if (_yearSortOrder == SortOrder.desc) {
      results.sort((a, b) {
        final yearA = int.tryParse(a.year) ?? 0;
        final yearB = int.tryParse(b.year) ?? 0;
        return yearB.compareTo(yearA);
      });
    } else if (_yearSortOrder == SortOrder.asc) {
      results.sort((a, b) {
        final yearA = int.tryParse(a.year) ?? 0;
        final yearB = int.tryParse(b.year) ?? 0;
        return yearA.compareTo(yearB);
      });
    }

    return results;
  }

  @override
  void initState() {
    super.initState();
    _searchService = SSESearchService();
    _setupSearchListeners();
    _loadSearchHistory();


    // 初始化删除动画控制器
    _deleteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // 1.5秒变红动画
      vsync: this,
    );
    _deleteAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _deleteAnimationController!,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _incrementalResultsSubscription?.cancel();
    _progressSubscription?.cancel();
    _errorSubscription?.cancel();
    _eventSubscription?.cancel();
    _updateTimer?.cancel();
    _searchService.dispose();
    _deleteAnimationController?.dispose();
    super.dispose();
  }

  /// 设置搜索监听器
  void _setupSearchListeners() {
    // 取消之前的监听器
    _incrementalResultsSubscription?.cancel();
    _progressSubscription?.cancel();
    _errorSubscription?.cancel();
    _eventSubscription?.cancel();

    // 监听搜索事件
    _eventSubscription = _searchService.eventStream.listen((event) {
      if (mounted) {
        if (event is SearchStartEvent) {
          setState(() {
            _hasReceivedStart = true;
          });
        } else if (event is SearchSourceErrorEvent ||
            event is SearchSourceResultEvent) {
          // 收到源错误或源结果事件时，确保已标记为收到start消息
          setState(() {
            _hasReceivedStart = true;
          });
        }
      }
    });

    // 监听增量搜索结果
    _incrementalResultsSubscription =
        _searchService.incrementalResultsStream.listen((incrementalResults) {
      if (mounted && incrementalResults.isNotEmpty) {
        // 将增量结果添加到现有结果列表中
        _searchResults.addAll(incrementalResults);

        // 使用防抖机制，避免过于频繁的UI更新，同时确保用户交互不受影响
        _updateTimer?.cancel();
        _updateTimer = Timer(const Duration(milliseconds: 50), () {
          if (mounted) {
            // 使用 scheduleMicrotask 确保UI更新在下一个微任务中执行，不阻塞用户交互
            scheduleMicrotask(() {
              if (mounted) {
                setState(() {
                  // 触发UI更新
                });
              }
            });
          }
        });
      }
    });

    // 监听搜索进度
    _progressSubscription = _searchService.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _searchProgress = progress;
        });
      }
    });

    // 监听搜索错误
    _errorSubscription = _searchService.errorStream.listen((error) {
      if (mounted) {
        // 检查是否是连接关闭错误，如果是则忽略
        final errorString = error.toLowerCase();
        if (errorString.contains('connection closed') ||
            errorString.contains('clientexception') ||
            errorString.contains('connection terminated')) {
          // 连接被关闭，这是正常情况，不显示错误
          return;
        }

        setState(() {
          _searchError = error;
        });
      }
    });
  }

  Future<void> _loadSearchHistory() async {
    // 首先尝试从缓存加载数据
    try {
      final result = await PageCacheService().getSearchHistory(context);
      if (mounted) {
        setState(() {
          _searchHistory = result.success ? (result.data ?? []) : [];
        });
      }
    } catch (e) {
      // 缓存加载失败，设置为空
      if (mounted) {
        setState(() {
          _searchHistory = [];
        });
      }
    }
  }

  Future<void> _refreshSearchHistory() async {
    try {
      // 刷新缓存数据
      await PageCacheService().refreshSearchHistory(context);

      // 重新获取搜索历史数据
      final result = await PageCacheService().getSearchHistory(context);
      if (mounted) {
        setState(() {
          _searchHistory = result.success ? (result.data ?? []) : [];
        });
      }
    } catch (e) {
      // 错误处理，保持当前显示的内容
    }
  }

  /// 异步刷新收藏夹数据
  Future<void> _refreshFavorites() async {
    try {
      // 刷新收藏夹缓存数据
      await PageCacheService().refreshFavorites(context);
    } catch (e) {
      // 错误处理，静默处理
    }
  }

  /// 添加搜索历史（本地状态、缓存、服务器）
  void addSearchHistory(String query) {
    if (query.trim().isEmpty) return;

    final trimmedQuery = query.trim();

    // 立即添加到缓存
    PageCacheService().addSearchHistory(trimmedQuery, context);

    // 立即更新本地状态和UI
    if (mounted) {
      setState(() {
        // 检查是否已存在相同的搜索词（区分大小写）
        final existingIndex =
            _searchHistory.indexWhere((item) => item == trimmedQuery);

        if (existingIndex == -1) {
          // 不存在，添加到列表开头
          _searchHistory.insert(0, trimmedQuery);
        } else {
          // 已存在，移动到开头（保持原始大小写）
          final existingItem = _searchHistory[existingIndex];
          _searchHistory.removeAt(existingIndex);
          _searchHistory.insert(0, existingItem);
        }
      });
    }
  }

  /// 显示清空确认弹窗
  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return AlertDialog(
              backgroundColor:
                  themeService.isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
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
                    '清空搜索历史',
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
                    '确定要清空所有搜索历史吗？此操作无法撤销。',
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
                            _clearSearchHistory();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFe74c3c),
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
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
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

  /// 清空搜索历史
  Future<void> _clearSearchHistory() async {
    try {
      final result = await PageCacheService().clearSearchHistory(context);

      if (result.success) {
        // 立即清空本地状态
        if (mounted) {
          setState(() {
            _searchHistory.clear();
          });
        }
      } else {
        // 异常时异步刷新搜索历史以恢复数据
        _refreshSearchHistory();
      }
    } catch (e) {
      // 异常时异步刷新搜索历史以恢复数据
      _refreshSearchHistory();
    }
  }

  /// 开始删除动画
  void _startDeleteAnimation(String historyItem) {
    setState(() {
      _deletingHistoryItem = historyItem;
    });
    _deleteAnimationController?.forward().then((_) {
      // 动画完成后执行删除
      _deleteSearchHistory(historyItem);
    });
  }

  /// 取消删除动画
  void _cancelDeleteAnimation() {
    _deleteAnimationController?.reset();
    setState(() {
      _deletingHistoryItem = null;
    });
  }

  /// 删除单个搜索历史
  Future<void> _deleteSearchHistory(String historyItem) async {
    try {
      final result =
          await PageCacheService().deleteSearchHistory(historyItem, context);

      if (result.success) {
        // 立即从UI中移除
        if (mounted) {
          setState(() {
            _searchHistory.remove(historyItem);
            _deletingHistoryItem = null;
          });
        }
      } else {
        // API调用失败，异步刷新搜索历史以恢复数据
        _refreshSearchHistory();
      }
    } catch (e) {
      // 异常时异步刷新搜索历史以恢复数据
      _refreshSearchHistory();
    }
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _searchQuery = query.trim();
      _hasSearched = true;
      _hasReceivedStart = false; // 重置start状态
      _searchError = null;
      _searchResults.clear();
      _searchProgress = null; // 清空进度信息
      // 重置筛选和排序
      _selectedSource = 'all';
      _selectedYear = 'all';
      _selectedTitle = 'all';
      _yearSortOrder = SortOrder.none;
    });

    // 添加到搜索历史
    addSearchHistory(_searchQuery);

    // 搜索框失焦
    _searchFocusNode.unfocus();

    try {
      // 开始 SSE 搜索
      await _searchService.startSearch(_searchQuery);

      // 重新设置监听器，确保流控制器已初始化
      _setupSearchListeners();
    } catch (e) {
      if (mounted) {
        // 检查是否是连接关闭错误，如果是则忽略
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('connection closed') ||
            errorString.contains('clientexception') ||
            errorString.contains('connection terminated')) {
          // 连接被关闭，这是正常情况，不显示错误
          return;
        }

        setState(() {
          _searchError = e.toString();
        });
      }
    }
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _hasSearched = false; // 重置搜索状态，回到搜索主页
      _hasReceivedStart = false; // 重置start状态
      _searchResults.clear(); // 清空搜索结果
      _searchError = null; // 清空错误信息
      _searchProgress = null; // 清空进度信息
      // 停止当前搜索
      _searchService.stopSearch();
    });
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.isDarkMode
              ? const Color(0xFF121212)
              : const Color(0xFFf5f5f5),
          body: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // 搜索框
                      _buildSearchBox(themeService),
                      const SizedBox(height: 16),

                      if (!_hasSearched) ...[
                        // 搜索进度和结果
                        if (_searchError != null)
                          _buildSearchError(themeService),
                      ],
                    ],
                  ),
                ),
                if (!_hasSearched) ...[
                  // 搜索历史（只有在从未搜索过时显示）
                  _buildSearchHistory(themeService),
                ],
                if (_hasSearched) ...[
                  // 搜索结果区域，不添加额外padding
                  _buildSearchResults(themeService),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBox(ThemeService themeService) {
    return Container(
      decoration: BoxDecoration(
        color: themeService.isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: themeService.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: true,
        textInputAction: TextInputAction.search,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          hintText: '搜索电影、剧集、动漫...',
          hintStyle: GoogleFonts.poppins(
            color: themeService.isDarkMode
                ? const Color(0xFF666666)
                : const Color(0xFF95a5a6),
            fontSize: 16,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 清空按钮
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    color: themeService.isDarkMode
                        ? const Color(0xFFb0b0b0)
                        : const Color(0xFF7f8c8d),
                    size: 20,
                  ),
                  onPressed: _clearSearch,
                ),
              // 搜索按钮
              IconButton(
                icon: Icon(
                  LucideIcons.search,
                  color: _searchQuery.trim().isNotEmpty
                      ? const Color(0xFF27ae60) // 有内容时绿色
                      : themeService.isDarkMode
                          ? const Color(0xFFb0b0b0)
                          : const Color(0xFF7f8c8d), // 无内容时灰色
                  size: 20,
                ),
                onPressed: _searchQuery.trim().isNotEmpty
                    ? () => _performSearch(_searchQuery)
                    : null, // 无内容时禁用
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: themeService.isDarkMode
              ? const Color(0xFFffffff)
              : const Color(0xFF2c3e50),
        ),
        onSubmitted: _performSearch,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildSearchHistory(ThemeService themeService) {
    // 如果没有搜索历史，直接隐藏整个模块
    if (_searchHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '搜索历史',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeService.isDarkMode
                      ? const Color(0xFFffffff)
                      : const Color(0xFF2c3e50),
                ),
              ),
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
                    color: themeService.isDarkMode
                        ? const Color(0xFFb0b0b0)
                        : const Color(0xFF7f8c8d),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.map((history) {
            final isDeleting = _deletingHistoryItem == history;

            return GestureDetector(
              onTap: () {
                if (!isDeleting) {
                  _searchController.text = history;
                  _performSearch(history);
                }
              },
              onLongPressStart: (_) {
                if (!isDeleting) {
                  _startDeleteAnimation(history);
                }
              },
              onLongPressEnd: (_) {
                if (isDeleting) {
                  _cancelDeleteAnimation();
                }
              },
              child: AnimatedBuilder(
                animation: _deleteAnimation ?? const AlwaysStoppedAnimation(0.0),
                builder: (context, child) {
                  // 计算颜色插值
                  Color backgroundColor;
                  Color textColor;
                  Color borderColor;

                  if (isDeleting) {
                    final animationValue = _deleteAnimation?.value ?? 0.0;

                    // 背景色从正常色渐变到红色
                    backgroundColor = Color.lerp(
                      themeService.isDarkMode
                          ? const Color(0xFF1e1e1e)
                          : Colors.white,
                      const Color(0xFFe74c3c).withOpacity(0.2),
                      animationValue,
                    )!;

                    // 文字色从正常色渐变到红色
                    textColor = Color.lerp(
                      themeService.isDarkMode
                          ? const Color(0xFFffffff)
                          : const Color(0xFF2c3e50),
                      const Color(0xFFe74c3c),
                      animationValue,
                    )!;

                    // 边框色从正常色渐变到红色
                    borderColor = Color.lerp(
                      themeService.isDarkMode
                          ? const Color(0xFF333333)
                          : const Color(0xFFe9ecef),
                      const Color(0xFFe74c3c),
                      animationValue,
                    )!;
                  } else {
                    backgroundColor = themeService.isDarkMode
                        ? const Color(0xFF1e1e1e)
                        : Colors.white;
                    textColor = themeService.isDarkMode
                        ? const Color(0xFFffffff)
                        : const Color(0xFF2c3e50);
                    borderColor = themeService.isDarkMode
                        ? const Color(0xFF333333)
                        : const Color(0xFFe9ecef);
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          history,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        if (isDeleting) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: textColor,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            );
          }).toList(),
          ),
        ),
      ],
    );
  }

  /// 构建搜索错误显示
  Widget _buildSearchError(ThemeService themeService) {
    final error = _searchError;
    if (error == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFe74c3c).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFe74c3c).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFe74c3c),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFFe74c3c),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchError = null;
              });
            },
            child: Text(
              '重试',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFFe74c3c),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ThemeService themeService) {
    // 如果已搜索过，总是显示搜索结果区域
    if (_hasSearched) {
      return _buildSearchResultsList(themeService);
    }

    // 默认返回空容器
    return const SizedBox.shrink();
  }

  Widget _buildSearchResultsList(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行 - 有padding
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '搜索结果',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: themeService.isDarkMode
                          ? const Color(0xFFffffff)
                          : const Color(0xFF2c3e50),
                    ),
                  ),
                  if (_hasSearched) ...[
                    const SizedBox(width: 8),
                    if (_hasReceivedStart)
                      Text(
                        _getProgressText(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: themeService.isDarkMode
                              ? const Color(0xFFb0b0b0)
                              : const Color(0xFF7f8c8d),
                        ),
                      )
                    else
                      Transform.translate(
                        offset: const Offset(2, -2), // 向上调整2像素
                        child: const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Color(0xFF27ae60)),
                          ),
                        ),
                      ),
                  ],
                  // 聚合开关移动到标题行最右侧
                  if (_hasSearched && _searchResults.isNotEmpty) ...[
                    const Spacer(),
                    Transform.translate(
                      offset: const Offset(0, 8), // 向下调整8像素与标题对齐
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '聚合',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: themeService.isDarkMode
                                  ? const Color(0xFFffffff)
                                  : const Color(0xFF2c3e50),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.7, // 进一步缩小开关尺寸
                            child: Switch(
                              value: _useAggregatedView,
                              onChanged: (value) {
                                setState(() {
                                  _useAggregatedView = value;
                                });
                              },
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFF27ae60), // 改为绿色
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: themeService.isDarkMode
                                  ? const Color(0xFF404040)
                                  : const Color(0xFFE0E0E0),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              trackOutlineColor:
                                  WidgetStateProperty.all(Colors.transparent), // 去掉边框
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              // 筛选器行
              if (_hasSearched && _searchResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildFilterSection(themeService),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Grid区域 - 无padding，占满宽度
        _useAggregatedView
            ? SearchResultAggGrid(
                key: ValueKey('agg_${_searchResults.length}'), // 添加key以优化重渲染
                results: _filteredSearchResults,
                themeService: themeService,
                onVideoTap: widget.onVideoTap,
                onGlobalMenuAction: _onGlobalMenuAction,
                hasReceivedStart: _hasReceivedStart,
              )
            : _SearchResultsGrid(
                key: ValueKey('list_${_searchResults.length}'), // 添加key以优化重渲染
                results: _filteredSearchResults,
                themeService: themeService,
                onVideoTap: widget.onVideoTap,
                onGlobalMenuAction: _onGlobalMenuAction,
                hasReceivedStart: _hasReceivedStart,
              ),
      ],
    );
  }

  String _getProgressText() {
    if (_searchProgress != null) {
      return '${_searchProgress!.completedSources}/${_searchProgress!.totalSources}';
    }
    return '0/0';
  }

  /// 处理视频菜单操作
  void _onGlobalMenuAction(VideoInfo videoInfo, VideoMenuAction action) {
    switch (action) {
      case VideoMenuAction.play:
        // 播放视频
        if (widget.onVideoTap != null) {
          widget.onVideoTap!(videoInfo);
        }
        break;
      case VideoMenuAction.favorite:
        // 收藏
        _handleFavorite(videoInfo);
        break;
      case VideoMenuAction.unfavorite:
        // 取消收藏
        _handleUnfavorite(videoInfo);
        break;
      case VideoMenuAction.deleteRecord:
        // 搜索场景不支持删除记录
        break;
      case VideoMenuAction.doubanDetail:
        // 豆瓣详情 - 已在组件内部处理URL跳转
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '正在打开豆瓣详情: ${videoInfo.title}',
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
              '正在打开 Bangumi 详情: ${videoInfo.title}',
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

  /// 处理收藏
  Future<void> _handleFavorite(VideoInfo videoInfo) async {
    try {
      // 构建收藏数据
      final favoriteData = {
        'cover': videoInfo.cover,
        'save_time': DateTime.now().millisecondsSinceEpoch,
        'source_name': videoInfo.sourceName,
        'title': videoInfo.title,
        'total_episodes': videoInfo.totalEpisodes,
        'year': videoInfo.year,
      };

      // 使用统一的收藏方法（包含缓存操作和API调用）
      final result = await PageCacheService()
          .addFavorite(videoInfo.source, videoInfo.id, favoriteData, context);

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
  Future<void> _handleUnfavorite(VideoInfo videoInfo) async {
    try {
      // 先立即从UI中移除该项目
      FavoritesGrid.removeFavoriteFromUI(videoInfo.source, videoInfo.id);

      // 通知继续观看组件刷新收藏状态
      if (mounted) {
        setState(() {});
      }

      // 使用统一的取消收藏方法（包含缓存操作和API调用）
      final result = await PageCacheService()
          .removeFavorite(videoInfo.source, videoInfo.id, context);

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

  // 筛选器相关方法

  List<SelectorOption> get _sourceOptions {
    final sources = _searchResults.map((r) => r.sourceName).toSet().toList();
    sources.sort();
    final options =
        sources.map((s) => SelectorOption(label: s, value: s)).toList();
    return [
      const SelectorOption(label: '全部来源', value: 'all'),
      ...options,
    ];
  }

  List<SelectorOption> get _yearOptions {
    final years =
        _searchResults.map((r) => r.year).where((y) => y.isNotEmpty).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); // Sort descending
    final options =
        years.map((y) => SelectorOption(label: y, value: y)).toList();
    return [
      const SelectorOption(label: '全部年份', value: 'all'),
      ...options,
    ];
  }

  List<SelectorOption> get _titleOptions {
    final titles = _searchResults.map((r) => r.title).toSet().toList();
    titles.sort();
    final options =
        titles.map((t) => SelectorOption(label: t, value: t)).toList();
    return [
      const SelectorOption(label: '全部标题', value: 'all'),
      ...options,
    ];
  }

  Widget _buildFilterSection(ThemeService themeService) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterPill('来源', _sourceOptions, _selectedSource, (newValue) {
            setState(() {
              _selectedSource = newValue;
            });
          }),
          _buildFilterPill('标题', _titleOptions, _selectedTitle, (newValue) {
            setState(() {
              _selectedTitle = newValue;
            });
          }),
          _buildFilterPill('年份', _yearOptions, _selectedYear, (newValue) {
            setState(() {
              _selectedYear = newValue;
            });
          }),
          _buildYearSortButton(),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String title, List<SelectorOption> options,
      String selectedValue, ValueChanged<String> onSelected) {
    bool isDefault = selectedValue == 'all';

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
              title, // 始终显示原始标题，不显示选中内容
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        const horizontalPadding = 16.0;
        const spacing = 10.0;
        final itemWidth = (screenWidth - horizontalPadding * 2 - spacing * 2) / 3;

        return Container(
          width: double.infinity, // 设置宽度为100%
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    title, 
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                  minHeight: 200.0,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 8
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.start, // 左对齐
                      spacing: spacing,
                      runSpacing: spacing,
                      children: options.map((option) {
                        final isSelected = option.value == selectedValue;
                        return SizedBox(
                          width: itemWidth,
                          child: InkWell(
                            onTap: () {
                              onSelected(option.value);
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              alignment: Alignment.centerLeft, // 内容左对齐
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF27AE60)
                                    : Theme.of(context).chipTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                option.label,
                                textAlign: TextAlign.left, // 文字左对齐
                                style: TextStyle(
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYearSortButton() {
    IconData icon;
    String text;
    switch (_yearSortOrder) {
      case SortOrder.desc:
        icon = LucideIcons.arrowDown10;
        text = '年份';
        break;
      case SortOrder.asc:
        icon = LucideIcons.arrowUp10;
        text = '年份';
        break;
      case SortOrder.none:
        icon = LucideIcons.arrowDownUp;
        text = '年份';
        break;
    }

    bool isDefault = _yearSortOrder == SortOrder.none;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_yearSortOrder == SortOrder.none) {
            _yearSortOrder = SortOrder.desc;
          } else if (_yearSortOrder == SortOrder.desc) {
            _yearSortOrder = SortOrder.asc;
          } else {
            _yearSortOrder = SortOrder.none;
          }
        });
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
              text,
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
              icon,
              size: 16,
              color: isDefault
                  ? Theme.of(context).textTheme.bodySmall?.color
                  : const Color(0xFF27AE60),
            ),
          ],
        ),
      ),
    );
  }
}

/// 搜索结果网格组件
class _SearchResultsGrid extends StatefulWidget {
  final List<SearchResult> results;
  final ThemeService themeService;
  final Function(VideoInfo)? onVideoTap;
  final Function(VideoInfo, VideoMenuAction)? onGlobalMenuAction;
  final bool hasReceivedStart;

  const _SearchResultsGrid({
    super.key,
    required this.results,
    required this.themeService,
    this.onVideoTap,
    this.onGlobalMenuAction,
    required this.hasReceivedStart,
  });

  @override
  State<_SearchResultsGrid> createState() => _SearchResultsGridState();
}

class _SearchResultsGridState extends State<_SearchResultsGrid>
    with AutomaticKeepAliveClientMixin {
  final PageCacheService _cacheService = PageCacheService();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以支持 AutomaticKeepAliveClientMixin

    if (widget.results.isEmpty && widget.hasReceivedStart) {
      return _buildEmptyState();
    }

    if (widget.results.isEmpty && !widget.hasReceivedStart) {
      return const SizedBox.shrink(); // 搜索开始但未收到start消息时，不显示任何内容
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算每列的宽度，确保严格三列布局
        final double screenWidth = constraints.maxWidth;
        final double padding = 16.0; // 左右padding
        final double spacing = 12.0; // 列间距
        final double availableWidth =
            screenWidth - (padding * 2) - (spacing * 2); // 减去padding和间距
        // 确保最小宽度，防止负宽度约束
        final double minItemWidth = 80.0; // 最小项目宽度
        final double calculatedItemWidth = availableWidth / 3;
        final double itemWidth = math.max(calculatedItemWidth, minItemWidth);
        final double itemHeight = itemWidth * 2.0; // 增加高度比例，确保有足够空间避免溢出

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 严格3列布局
            childAspectRatio: itemWidth / itemHeight, // 精确计算宽高比
            crossAxisSpacing: spacing, // 列间距
            mainAxisSpacing: 16, // 行间距 - 与收藏grid保持一致
          ),
          itemCount: widget.results.length,
          itemBuilder: (context, index) {
            final result = widget.results[index];
            final videoInfo = result.toVideoInfo();

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: VideoCard(
                key: ValueKey(
                    '${result.id}_${result.source}'), // 为每个卡片添加唯一key
                videoInfo: videoInfo,
                onTap: widget.onVideoTap != null
                    ? () => widget.onVideoTap!(videoInfo)
                    : null,
                from: 'search',
                cardWidth: itemWidth, // 传递计算出的宽度
                onGlobalMenuAction: widget.onGlobalMenuAction != null
                    ? (action) => widget.onGlobalMenuAction!(videoInfo, action)
                    : null,
                isFavorited: _cacheService.isFavoritedSync(
                    videoInfo.source, videoInfo.id), // 同步检查收藏状态
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 80,
            color: Color(0xFFbdc3c7),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无搜索结果',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7f8c8d),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '请尝试其他关键词或调整筛选条件',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF95a5a6),
            ),
          ),
        ],
      ),
    );
  }
}

