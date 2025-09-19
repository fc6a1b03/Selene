## 自动化构建流水线

本Fork仅使用GitHub Actions实现Android APK的自动化构建和发布流程

### 构建环境配置
- **运行环境**: Ubuntu Latest
- **Java版本**: OpenJDK 17 (Temurin发行版)
- **Flutter版本**: 3.x稳定版本

### APK构建
执行多架构APK构建，支持以下CPU架构：
- `armeabi-v7a` - 32位ARM处理器
- `arm64-v8a` - 64位ARM处理器  
- `x86_64` - 64位x86处理器

构建命令使用`--split-per-abi`参数生成针对不同架构优化的独立APK文件

### 文件重命名
将默认的APK文件名重命名为更具描述性的格式：
```
selene-v{版本号}+{构建号}-{日期}-{GIT哈希}-{架构}.apk
selene-v{VERSION_NAME}+{BUILD_NUMBER}-{YYMMDDHH}-{GIT_HASH}-{arch}.apk
```
