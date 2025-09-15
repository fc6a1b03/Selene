import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/user_data_service.dart';
import '../screens/login_screen.dart';
import '../services/douban_cache_service.dart';
import '../services/page_cache_service.dart';

class UserMenu extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onClose;

  const UserMenu({
    super.key,
    required this.isDarkMode,
    this.onClose,
  });

  @override
  State<UserMenu> createState() => _UserMenuState();
}

class _UserMenuState extends State<UserMenu> {
  String? _username;
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final username = await UserDataService.getUsername();
    final cookies = await UserDataService.getCookies();
    
    if (mounted) {
      setState(() {
        _username = username;
        _role = _parseRoleFromCookies(cookies);
      });
    }
  }

  String _parseRoleFromCookies(String? cookies) {
    if (cookies == null || cookies.isEmpty) {
      return 'user';
    }

    try {
      // 解析cookies字符串
      final cookieMap = <String, String>{};
      final cookiePairs = cookies.split(';');
      
      for (final cookie in cookiePairs) {
        final trimmed = cookie.trim();
        final firstEqualIndex = trimmed.indexOf('=');
        
        if (firstEqualIndex > 0) {
          final key = trimmed.substring(0, firstEqualIndex);
          final value = trimmed.substring(firstEqualIndex + 1);
          if (key.isNotEmpty && value.isNotEmpty) {
            cookieMap[key] = value;
          }
        }
      }

      final authCookie = cookieMap['auth'];
      if (authCookie == null) {
        return 'user';
      }

      // 处理可能的双重编码
      String decoded = Uri.decodeComponent(authCookie);
      
      // 如果解码后仍然包含 %，说明是双重编码，需要再次解码
      if (decoded.contains('%')) {
        decoded = Uri.decodeComponent(decoded);
      }

      final authData = json.decode(decoded);
      final role = authData['role'] as String?;
      
      return role ?? 'user';
    } catch (e) {
      // 解析失败时默认为user
      return 'user';
    }
  }

  Future<void> _handleLogout() async {
    // 只清除密码和cookies，保留服务器地址和用户名
    await UserDataService.clearPasswordAndCookies();
    
    // 跳转到登录页
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleClearDoubanCache() async {
    try {
      await DoubanCacheService().clearAll();
      // 同时清空 Bangumi 的函数级与内存级缓存
      PageCacheService().clearCache('bangumi_calendar');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已清除豆瓣缓存')),
        );
        // 清除后关闭菜单
        widget.onClose?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('清除豆瓣缓存失败')),
        );
        // 即便失败也关闭菜单，避免停留
        widget.onClose?.call();
      }
    }
  }

  Widget _buildRoleTag() {
    String label;
    Color color;
    
    switch (_role) {
      case 'admin':
        label = '管理员';
        color = const Color(0xFFf59e0b); // 橙黄色
        break;
      case 'owner':
        label = '站长';
        color = const Color(0xFF8b5cf6); // 紫色
        break;
      case 'user':
      default:
        label = '用户';
        color = const Color(0xFF10b981); // 绿色
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // 阻止点击菜单内容时关闭
              child: Container(
                width: 280,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: widget.isDarkMode 
                      ? const Color(0xFF2c2c2c)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 用户信息区域
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // 当前用户标签
                          Text(
                            '当前用户',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: widget.isDarkMode 
                                  ? const Color(0xFF9ca3af)
                                  : const Color(0xFF6b7280),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 用户名
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _username ?? '未知用户',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: widget.isDarkMode 
                                      ? const Color(0xFFffffff)
                                      : const Color(0xFF1f2937),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                               const SizedBox(width: 8),
                               // 角色标签
                               _buildRoleTag(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode 
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    // 清除豆瓣缓存按钮
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleClearDoubanCache,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.trash2,
                                size: 20,
                                color: const Color(0xFFf59e0b),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '清除豆瓣缓存',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: widget.isDarkMode 
                                      ? const Color(0xFFffffff)
                                      : const Color(0xFF1f2937),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode 
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    // 登出按钮
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleLogout,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.logOut,
                                size: 20,
                                color: const Color(0xFFef4444),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '登出',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: const Color(0xFFef4444),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
