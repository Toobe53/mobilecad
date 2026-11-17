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

## 本地构建说明

仓库不包含 FreeCAD/CPython 运行时（`.gitignore` 里排除了 ~500 MB 的 `src/arm64` 资产）。
构建前需要按 `engine/` 的脚本产出运行时并 `engine/package_runtime.py` 暂存，另外本地签名配置不进仓库。
这就是为什么测试渠道的 APK 由维护者本机构建后上传，而不是 CI 自动构建。
