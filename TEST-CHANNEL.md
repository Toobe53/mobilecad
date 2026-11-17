# 测试版发布渠道（test channel）

`test` 分支是这个 fork 的**测试版渠道**；稳定版仍走 `i18n/zh-hans` 分支和正式 Release。

## 这个渠道里有什么

- 简体中文界面（与正式中文版同一套 i18n）；
- 桥接层加固与网格缓存（PR #22 的三个提交）：
  - 三角化缓存（有界 LRU，按形状哈希失效）；
  - 参数校验、`ping`/`describe_ops`、缓存开关；
  - 选择不重建网格、刷新合并；
- **测试脚本随 APK 一起打包**：`assets/device-checks/device_check.py`、`device_extra.py`；
- `--es runchecks <脚本名>` 钩子（仅 debuggable 构建），可直接在真机跑自检。

## 安装包

- 包名：`app.mobilecad.i18n.test`（与正式中文版 `app.mobilecad.i18n` 共存）；
- 版本名：`0.5.18-test`（后缀 `-test`）；
- 仅 arm64，未签名发布（本地 keystore 签名），安装前请允许未知来源。

```bash
adb install -r MobileCAD-0.5.18-test-arm64-i18n.apk
```

## 真机自检

```bash
tools/run-device-checks.sh          # 构建 qa 包、安装、跑两个脚本并断言
SKIP_BUILD=1 SKIP_INSTALL=1 tools/run-device-checks.sh   # 只重跑检查
```

检查项：`ping`、参数错误、360 面实体缓存命中、平移/链接/草图/撤销重做、切文档清缓存。

## 发布约定

- tag 形如 `test-0.5.18.N`，发布为 **pre-release**；
- 每个 tag 附 APK + `SHA256SUMS`；
- 测试版可能包含未合并到上游的改动，不保证 F-Droid 可复现；
- 回滚：`adb uninstall app.mobilecad.i18n.test`，正式版不受影响。

## 可复现构建（CI）

运行时不再只存在于维护者机器上：

- `runtime-0.5.18` Release 里托管了 arm64 运行时包（`runtime-arm64-e95a31c.tar.zst`，约 140 MB，
  解压后 ~520 MB，含 FreeCAD/Qt/OCCT/VTK、CPython、jniLibs、Qt6Android.jar）；
- `tools/fetch-runtime.sh` 负责下载 + 校验 + 解压到 `app/app/src/arm64/` 和 `app/app/libs/`；
- `app/app/build.gradle.kts` 支持 `-PusePrebuiltBridge`：跳过 NDK/CMake，直接用运行时里的 `libfcbridge.so`
  （不传这个参数时仍是上游的 NDK 构建，不影响正式发布）；
- `.github/workflows/test-build.yml`：打 `test-*` tag 或手动触发时，在 Ubuntu runner 上
  fetch 运行时 → 构建 `assembleArm64Qa` → 校验 APK 内含 `libFreeCADApp.so` 与 `device-checks/` → 上传 artifact
  → 自动发 pre-release。

本地复现：

```bash
tools/fetch-runtime.sh
cd app && ./gradlew :app:assembleArm64Qa -PusePrebuiltBridge
```

签名：CI 默认用 debug key；如果想让 CI 产物和本地测试包同签名，在仓库 Secrets 里配置
`TEST_KEYSTORE_B64`（keystore 的 base64）、`TEST_KEYSTORE_PASS`、`TEST_KEY_ALIAS`、`TEST_KEY_PASS`，
workflow 会通过 `-PqaStoreFile…` 使用它。不配置时，换包前需先卸载旧测试版。
