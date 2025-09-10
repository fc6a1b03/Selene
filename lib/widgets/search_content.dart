import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/page_cache_service.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';

class SearchContent extends StatefulWidget {
  const SearchContent({super.key});

  @override
  State<SearchContent> createState() => _SearchContentState();
}

class _SearchContentState extends State<SearchContent> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<String> _searchHistory = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _searchQuery = query.trim();
      _hasSearched = true;
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

    // TODO: 实现实际的搜索逻辑
    _mockSearchResults();
  }

  void _mockSearchResults() {
    // 模拟搜索结果
    setState(() {
      _searchResults = [
        {
          'title': '${_searchQuery} - 电影',
          'type': '电影',
          'year': '2023',
          'rating': '8.5',
          'poster': 'https://via.placeholder.com/150x200',
        },
        {
          'title': '${_searchQuery} - 剧集',
          'type': '剧集',
          'year': '2022',
          'rating': '9.1',
          'poster': 'https://via.placeholder.com/150x200',
        },
        {
          'title': '${_searchQuery} - 动漫',
          'type': '动漫',
          'year': '2024',
          'rating': '8.8',
          'poster': 'https://via.placeholder.com/150x200',
        },
      ];
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      // 不清空搜索结果，保持显示
      // 不重置 _hasSearched，保持搜索结果页面
    });
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return SingleChildScrollView(
          child: Padding(
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
                  // 搜索结果（搜索过后始终显示，无论搜索框内容如何）
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

  Widget _buildSearchResults(ThemeService themeService) {
    // 如果没有搜索结果，显示空状态
    if (_searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '搜索结果 (${_searchResults.length})',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: themeService.isDarkMode 
                ? const Color(0xFFffffff)
                : const Color(0xFF2c3e50),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final result = _searchResults[index];
            return _buildSearchResultItem(result, themeService);
          },
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> result, ThemeService themeService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 海报占位符
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: themeService.isDarkMode 
                    ? const Color(0xFF333333)
                    : const Color(0xFFecf0f1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.image,
                color: themeService.isDarkMode 
                    ? const Color(0xFF666666)
                    : const Color(0xFFbdc3c7),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // 内容信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result['title'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeService.isDarkMode 
                          ? const Color(0xFFffffff)
                          : const Color(0xFF2c3e50),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: themeService.isDarkMode 
                              ? const Color(0xFF27ae60).withOpacity(0.2)
                              : const Color(0xFF27ae60).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          result['type'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF27ae60),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        result['year'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: themeService.isDarkMode 
                              ? const Color(0xFFb0b0b0)
                              : const Color(0xFF7f8c8d),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.star,
                        size: 12,
                        color: const Color(0xFFf39c12),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        result['rating'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: themeService.isDarkMode 
                              ? const Color(0xFFb0b0b0)
                              : const Color(0xFF7f8c8d),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 更多按钮
            IconButton(
              onPressed: () {
                // TODO: 实现更多操作
              },
              icon: Icon(
                LucideIcons.ellipsis,
                color: themeService.isDarkMode 
                    ? const Color(0xFFb0b0b0)
                    : const Color(0xFF7f8c8d),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
