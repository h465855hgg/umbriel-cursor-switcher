# 光标特效切换器 / Cursor Effects Switcher

给 [Umbriel](https://github.com/noctalia-dev/umbriel) 用的光标主题与光标 shader 光效切换器，HuxerUI 编写，带托盘。

- **自动识别**已安装的 Xcursor 主题（扫描 `~/.local/share/icons`、`~/.icons`、`/usr/share/icons`）
- 切换主题、调整大小 16–72 px
- 切换 30 个社区光标 shader 光效，可调半径
- 改动即时写入 `~/.config/umbriel/config.toml` 并热重载，没有「应用」按钮
- 中英文界面（按 `LANG` 自动选择）
- 托盘：显示 / 隐藏、退出
- 默认浮动窗口 640×560

> 只写 Umbriel 的配置，光效是 Umbriel 的 shader。主题文件本身是通用 Xcursor，其它桌面也能用，但切换要各自桌面自己的方式。

## 构建

需要 [HuxerUI SDK](https://github.com/HuxerUI/HuxerUI) 0.5.5+ 和 GTK3 开发库：

```sh
curl -fsSL https://github.com/HuxerUI/HuxerUI/releases/latest/download/install.sh | sh -s -- --yes
export HUXERUI_HOME=$HOME/.local/share/HuxerUI
export PATH=$HUXERUI_HOME/bin:$PATH
huxerui build linux --config release
./scripts/stage.sh
./scripts/package-all.sh        # rpm + deb + AppImage
```

## 安装

```sh
./install.sh      # 装到 ~/.local/opt/cursor-switcher
```

或装分发包（RPM/DEB/AppImage），见 Releases。

## 说明

- 光效不能叠加，一次只能挂一个

## 许可

MIT
