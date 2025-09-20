import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/user_data_service.dart';
import 'services/api_service.dart';
import 'services/theme_service.dart';
import 'services/douban_cache_service.dart';
import 'package:fvp/fvp.dart' as fvp;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  fvp.registerWith();
  
  // 初始化豆瓣缓存服务
  final cacheService = DoubanCacheService();
  await cacheService.init();
  
  // 启动定期清理
  cacheService.startPeriodicCleanup();
  
  runApp(const SeleneApp());
}

class SeleneApp extends StatelessWidget {
  const SeleneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeService(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Selene',
            debugShowCheckedModeBanner: false,
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.themeMode,
            home: const AppWrapper(),
          );
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    try {
      // 检查是否有自动登录所需的数据
      final hasAutoLoginData = await UserDataService.hasAutoLoginData();
      
      if (!hasAutoLoginData) {
        // 如果没有自动登录数据，直接进入登录页
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // 有自动登录数据，尝试自动登录

      final loginResult = await ApiService.autoLogin();
      
      if (mounted) {
        if (loginResult.success) {
          // 自动登录成功，进入首页
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // 自动登录失败，进入登录页
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // 发生异常，进入登录页
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                color: themeService.isDarkMode 
                    ? const Color(0xFF000000) // 深色模式纯黑色
                    : null,
                gradient: themeService.isDarkMode 
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFe6f3fb),
                          Color(0xFFeaf3f7),
                          Color(0xFFf7f7f3),
                          Color(0xFFe9ecef),
                          Color(0xFFdbe3ea),
                          Color(0xFFd3dde6),
                        ],
                        stops: [0.0, 0.18, 0.38, 0.60, 0.80, 1.0],
                      ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        themeService.isDarkMode 
                            ? const Color(0xFFffffff)
                            : const Color(0xFF2c3e50)
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '正在检查登录状态...',
                      style: TextStyle(
                        fontSize: 16,
                        color: themeService.isDarkMode 
                            ? const Color(0xFFffffff)
                            : const Color(0xFF2c3e50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    
    return const LoginScreen();
  }
}
