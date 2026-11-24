# 打包

所有包都从同一个安装树 `build-stage/` 生成（`scripts/stage.sh`）：

```
build-stage/
  opt/cursor-switcher/{cursor-switcher, cursor-switcher.resources/, helper.py, icon.png}
  usr/bin/cursor-switcher -> ../opt/cursor-switcher/cursor-switcher
  usr/share/applications/cursor-switcher.desktop
  usr/share/icons/hicolor/128x128/apps/cursor-switcher.png
```

## 当前架构（x86_64）

```sh
huxerui build linux --config release
./scripts/stage.sh
./scripts/package-all.sh          # rpm + deb + AppImage，产物在 dist/
```

单独打：

```sh
./scripts/package-rpm.sh
./scripts/package-deb.sh
./scripts/package-appimage.sh
```

## aarch64

GTK / HuxerUI 这套依赖没法在 x86_64 上交叉编译，必须在 aarch64 机器上原生构建：

```sh
# 在 aarch64 Fedora / Ubuntu 上
git clone https://github.com/h465855hgg/cursor-switcher
cd cursor-switcher
# 安装 HuxerUI SDK（会自动选 linux-aarch64 包）
curl -fsSL https://github.com/HuxerUI/HuxerUI/releases/latest/download/install.sh | sh -s -- --yes
export HUXERUI_HOME=$HOME/.local/share/HuxerUI
export PATH=$HUXERUI_HOME/bin:$PATH
huxerui build linux --config release
./scripts/stage.sh
./scripts/package-all.sh aarch64
```

脚本会按架构下载对应的 `linuxdeploy-aarch64.AppImage` / `appimagetool-aarch64.AppImage`。

## 用 GitHub Actions 自动出双架构包

`packaging/ci/github-workflow.yml` 是现成的 workfdow（x86_64 + `ubuntu-24.04-arm`），复制到 `.github/workflows/build.yml` 即可。

推送 workflow 文件需要 token 有 `workflow` scope：

```sh
gh auth refresh -h github.com -s workflow
```
