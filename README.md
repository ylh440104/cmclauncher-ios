# CMCLauncher

在 iOS 上运行 Minecraft Java 版。

## 项目定位

Minecraft Java 版依赖桌面 JVM 与 OpenGL。iOS 两样都不给：没有可用的图形桌面栈，也不允许普通应用创建可执行内存页。CMCLauncher 的做法是把完整的 OpenJDK 运行时带进应用，用 Caciocavallo 提供 AWT 的无窗口后端，用 gl4es / ANGLE 把 OpenGL 转换成 Metal，并在应用启动阶段取得 JIT 权限，让 HotSpot 能正常工作。

## 功能

- 支持 1.7.10 至最新正式版与快照
- Fabric、Forge、NeoForge 安装
- Modrinth / CurseForge 整合包导入
- 微软正版账号登录与离线账号
- 多实例隔离，每个实例独立配置与存档
- 自定义虚拟按键布局，支持手柄与陀螺仪
- 三种渲染后端：gl4es、ANGLE(tinygl4angle)、OSMesa(Zink/Vulkan)
- 外接显示器与 AirPlay 输出

## 系统要求

- iOS / iPadOS 14.0 或更高
- arm64 设备
- 建议 4GB 以上内存，大型整合包需要 6GB 以上
- Java 运行时随应用分发，无需另行安装

## JIT 与安装方式

HotSpot 解释执行 Minecraft 会严重卡顿，必须有 JIT。iOS 只在两种情况下允许应用创建可执行内存：

1. 应用具备 `get-task-allow` 权限并被调试器 attach 过
2. 设备越狱，或通过 TrollStore 安装（可注入任意 entitlement）

应用启动时会自行尝试启用：

```c
if (!isJITEnabled(true) && getEntitlementValue(@"com.apple.private.security.no-sandbox")) {
    posix_spawnp(&pid, argv[0], NULL, NULL, ...);
    waitpid(pid, NULL, WUNTRACED);
    ptrace(PT_DETACH, pid, NULL, 0);
}
```

父进程 spawn 一个子进程并 attach 后立即 detach，父子都会带上 `CS_DEBUGGED` 标志，JIT 随即可用。

签名方式对应三种 entitlements：

| 方式 | entitlements 文件 | 说明 |
|---|---|---|
| 越狱 / TrollStore | `entitlements.trollstore.xml` | no-sandbox，JIT 自启用 |
| 自签侧载 | `entitlements.sideload.xml` | get-task-allow，需调试器或 StikDebug |
| 付费开发者账号 | `entitlements.codesign.xml` | 同上，描述文件有效期一年 |

## 构建

原生层用 CMake 交叉编译，不需要 macOS。只需要 iOS SDK、clang 与 ld64.lld：

```sh
cmake -B Natives/build -G Ninja \
  -DCMAKE_SYSTEM_NAME=Darwin \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DCMAKE_OSX_SYSROOT=/path/to/iPhoneOS16.5.sdk \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_OBJC_COMPILER=clang \
  -DCMAKE_C_COMPILER_TARGET=arm64-apple-ios14.0 \
  -DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=lld \
  -DCMAKE_SHARED_LINKER_FLAGS=-fuse-ld=lld \
  Natives

ninja -C Natives/build
```

Java 层：

```sh
make -C JavaApp BOOTJDK=/path/to/jdk/bin
```

产物：`Natives/build/CMCLauncher.app`、`JavaApp/build/*.jar`。

iOS SDK 可从 [theos/sdks](https://github.com/theos/sdks) 获取。

## 项目结构

```
Natives/                原生层
  main.m                入口，JIT 启用
  JavaLauncher.m        JVM 启动（JLI_Launch）
  SurfaceViewController 游戏视图与游戏循环
  ctxbridges/           OpenGL 上下文桥
  input/                手柄、陀螺仪、键盘输入
  customcontrols/       虚拟按键
  authenticator/        账号登录
  installer/            Fabric / Forge / 整合包安装
  resources/Frameworks  预编译原生库（gl4es、MoltenVK、OSMesa 等）
  ui/                   启动器界面
JavaApp/                Java 层
  src/launcher/         启动器逻辑与 LWJGL 桥
  src/lwjgl/            GLFW/OpenGL 的 Java 封装
  src/patchjna_agent/   JNA 在 iOS 上的修补
  libs/                 Caciocavallo 与 LWJGL 预编译包
```

## 常见问题

**启动后黑屏**：多数是渲染后端不兼容。到设置里依次尝试 gl4es、ANGLE、Zink。

**提示内存不足**：iOS 对单个应用有内存上限。降低设置里的分配内存，或减少模组数量。

**安装模组后崩溃**：部分模组依赖本地库或桌面 API，在 iOS 上无法运行。

**第一次启动很慢**：需要解压 Java 运行时与资源文件，之后启动会快很多。

## 致谢

本项目的执行模型、AWT 后端适配、GL 桥接与渲染管线设计建立在以下项目之上：

- [PojavLauncher_iOS](https://github.com/PojavLauncherTeam/PojavLauncher_iOS) — iOS 上运行 Minecraft Java 版的完整实现，本项目的原生层与 Java 层在其基础上继续开发
- [OpenJDK](https://openjdk.org) — Java 运行时
- [Caciocavallo](https://github.com/caciocavallosilano/caciocavallo17) — AWT 无窗口后端
- [LWJGL](https://www.lwjgl.org) — OpenGL / GLFW / OpenAL 绑定
- [gl4es](https://github.com/ptitSeb/gl4es) — OpenGL 1.x/2.x 到 OpenGL ES 的转换层
- [ANGLE](https://chromium.googlesource.com/angle/angle) — OpenGL ES 到 Metal 的转换层
- [MoltenVK](https://github.com/KhronosGroup/MoltenVK) — Vulkan 到 Metal 的转换层
- [UnzipKit](https://github.com/abbeycode/UnzipKit)、[AFNetworking](https://github.com/AFNetworking/AFNetworking)、[fishhook](https://github.com/facebook/fishhook)、[LZMA SDK](https://www.7-zip.org/sdk.html)

## 许可证

GPLv3，见 [LICENSE](LICENSE)。
