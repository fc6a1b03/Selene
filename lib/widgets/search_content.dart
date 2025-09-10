import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/page_cache_service.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import '../services/sse_search_service.dart';
import '../models/search_result.dart';
import '../models/video_info.dart';
import '../widgets/video_card.dart';

class SearchContent extends StatefulWidget {
  final Function(VideoInfo)? onVideoTap;
  
  const SearchContent({
    super.key,
    this.onVideoTap,
  });

  @override
  State<SearchContent> createState() => _SearchContentState();
}

class _SearchContentState extends State<SearchContent> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<String> _searchHistory = [];
  List<SearchResult> _searchResults = [];
  bool _hasSearched = false;
  bool _hasReceivedStart = false; // 是否已收到start消息
  String? _searchError;
  SearchProgress? _searchProgress;
  Timer? _updateTimer; // 用于防抖的定时器
  
  late SSESearchService _searchService;
  StreamSubscription<List<SearchResult>>? _incrementalResultsSubscription;
  StreamSubscription<SearchProgress>? _progressSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<SearchEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _searchService = SSESearchService();
    _setupSearchListeners();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _incrementalResultsSubscription?.cancel();
    _progressSubscription?.cancel();
    _errorSubscription?.cancel();
    _eventSubscription?.cancel();
    _updateTimer?.cancel();
    _searchService.dispose();
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
        } else if (event is SearchSourceErrorEvent || event is SearchSourceResultEvent) {
          // 收到源错误或源结果事件时，确保已标记为收到start消息
          setState(() {
            _hasReceivedStart = true;
          });
        }
      }
    });

    // 监听增量搜索结果
    _incrementalResultsSubscription = _searchService.incrementalResultsStream.listen((incrementalResults) {
      if (mounted && incrementalResults.isNotEmpty) {
        // 将增量结果添加到现有结果列表中
        _searchResults.addAll(incrementalResults);
        
        // 使用防抖机制，避免过于频繁的UI更新
        _updateTimer?.cancel();
        _updateTimer = Timer(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              // 触发UI更新
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
        setState(() {
          _searchError = error;
        });
      }
    });
  }

  Future<void> _loadSearchHistory() async {
    // 首先尝试从缓存加载数据
    try {
      final cachedHistory = await PageCacheService().getSearchHistory(context);
      if (mounted) {
        setState(() {
          _searchHistory = cachedHistory ?? [];
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

    // 然后在后台异步刷新数据
    _refreshSearchHistory();
  }

  Future<void> _refreshSearchHistory() async {
    try {
      final history = await PageCacheService().refreshSearchHistory(context);
      if (mounted) {
        setState(() {
          _searchHistory = history ?? [];
        });
      }
    } catch (e) {
      // 错误处理，保持当前显示的内容
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
              backgroundColor: themeService.isDarkMode 
                  ? const Color(0xFF1e1e1e)
                  : Colors.white,
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
      final response = await ApiService.clearSearchHistory(context);

      if (response.success) {
        setState(() {
          _searchHistory.clear();
        });
        // 清除缓存
        PageCacheService().clearCache('search_history');
        // 显示成功提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '搜索历史已清空',
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

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _searchQuery = query.trim();
      _hasSearched = true;
      _hasReceivedStart = false; // 重置start状态
      _searchError = null;
      _searchResults.clear();
      _searchProgress = null; // 清空进度信息
    });

    // 添加到搜索历史
    if (!_searchHistory.contains(_searchQuery)) {
      setState(() {
        _searchHistory.insert(0, _searchQuery);
        if (_searchHistory.length > 10) {
          _searchHistory = _searchHistory.take(10).toList();
        }
      });
    }

    // 搜索框失焦
    _searchFocusNode.unfocus();

    try {
      // 开始 SSE 搜索
      await _searchService.startSearch(_searchQuery);
      
      // 重新设置监听器，确保流控制器已初始化
      _setupSearchListeners();
    } catch (e) {
      if (mounted) {
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
        return SingleChildScrollView(
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
                    const SizedBox(height: 24),
                    
                    if (!_hasSearched) ...[
                      // 搜索历史（只有在从未搜索过时显示）
                      _buildSearchHistory(themeService),
                    ] else ...[
                      // 搜索进度和结果
                      if (_searchError != null)
                        _buildSearchError(themeService),
                    ],
                  ],
                ),
              ),
              if (_hasSearched) ...[
                // 搜索结果区域，不添加额外padding
                _buildSearchResults(themeService),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBox(ThemeService themeService) {
    return Container(
      decoration: BoxDecoration(
        color: themeService.isDarkMode 
            ? const Color(0xFF1e1e1e)
            : Colors.white,
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
                      ? const Color(0xFF27ae60)  // 有内容时绿色
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
          _searchQuery = value;
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
        Row(
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
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _searchHistory.map((history) {
            return GestureDetector(
              onTap: () {
                _searchController.text = history;
                _performSearch(history);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: themeService.isDarkMode 
                      ? const Color(0xFF1e1e1e)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: themeService.isDarkMode 
                        ? const Color(0xFF333333)
                        : const Color(0xFFe9ecef),
                    width: 1,
                  ),
                ),
                child: Text(
                  history,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: themeService.isDarkMode 
                        ? const Color(0xFFffffff)
                        : const Color(0xFF2c3e50),
                  ),
                ),
              ),
            );
          }).toList(),
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
          Icon(
            Icons.error_outline,
            color: const Color(0xFFe74c3c),
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _buildSearchResultsList(themeService),
      );
    }
    
    // 默认返回空容器
    return const SizedBox.shrink();
  }

  Widget _buildSearchResultsList(ThemeService themeService) {
    return Column(
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
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF27ae60)),
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _SearchResultsGrid(
          key: ValueKey(_searchResults.length), // 添加key以优化重渲染
          results: _searchResults,
          themeService: themeService,
          onVideoTap: widget.onVideoTap,
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
}

/// 搜索结果网格组件
class _SearchResultsGrid extends StatefulWidget {
  final List<SearchResult> results;
  final ThemeService themeService;
  final Function(VideoInfo)? onVideoTap;
  final bool hasReceivedStart;

  const _SearchResultsGrid({
    super.key,
    required this.results,
    required this.themeService,
    this.onVideoTap,
    required this.hasReceivedStart,
  });

  @override
  State<_SearchResultsGrid> createState() => _SearchResultsGridState();
}

class _SearchResultsGridState extends State<_SearchResultsGrid> with AutomaticKeepAliveClientMixin {
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
        final double availableWidth = screenWidth - (padding * 2) - (spacing * 2); // 减去padding和间距
        // 确保最小宽度，防止负宽度约束
        final double minItemWidth = 80.0; // 最小项目宽度
        final double calculatedItemWidth = availableWidth / 3;
        final double itemWidth = math.max(calculatedItemWidth, minItemWidth);
        final double itemHeight = itemWidth * 2.0; // 增加高度比例，确保有足够空间避免溢出
        
        return GridView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 严格3列布局
            childAspectRatio: itemWidth / itemHeight, // 精确计算宽高比
            crossAxisSpacing: spacing, // 列间距
            mainAxisSpacing: 16, // 行间距
          ),
          itemCount: widget.results.length,
          itemBuilder: (context, index) {
            final result = widget.results[index];
            final videoInfo = result.toVideoInfo();
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: VideoCard(
                key: ValueKey('${result.id}_${result.source}'), // 为每个卡片添加唯一key
                videoInfo: videoInfo,
                onTap: widget.onVideoTap != null ? () => widget.onVideoTap!(videoInfo) : null,
                from: 'search',
                cardWidth: itemWidth, // 传递计算出的宽度
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
          Icon(
            Icons.search_off,
            size: 80,
            color: const Color(0xFFbdc3c7),
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
            '请尝试其他关键词',
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
