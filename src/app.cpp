#include <huxerui/huxerui.h>

#include <algorithm>
#include <array>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <string>
#include <vector>

#include <unistd.h>

using namespace huxerui;
namespace fs = std::filesystem;

namespace {

bool IsZh() {
  const char* value = std::getenv("LC_ALL");
  if (value == nullptr || *value == '\0') {
    value = std::getenv("LANG");
  }
  return value != nullptr && std::string(value).rfind("zh", 0) == 0;
}

const char* T(const char* zh, const char* en) { return IsZh() ? zh : en; }

std::string HomeDir() {
  const char* home = std::getenv("HOME");
  return home != nullptr ? std::string(home) : std::string();
}

std::string ExecutableDir() {
  char buffer[4096];
  const ssize_t length = readlink("/proc/self/exe", buffer, sizeof(buffer) - 1);
  if (length <= 0) {
    return {};
  }
  buffer[length] = '\0';
  return fs::path(buffer).parent_path().string();
}

std::string FindFile(const std::vector<std::string>& candidates) {
  for (const auto& path : candidates) {
    if (!path.empty() && fs::exists(path)) {
      return path;
    }
  }
  return {};
}

std::string HelperPath() {
  const auto dir = ExecutableDir();
  return FindFile({
      dir + "/helper.py",
      HomeDir() + "/.local/opt/cursor-switcher/helper.py",
  });
}

std::string Run(const std::string& command) {
  std::string output;
  FILE* pipe = popen(command.c_str(), "r");
  if (pipe == nullptr) {
    return {};
  }
  char buffer[512];
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    output += buffer;
  }
  pclose(pipe);
  while (!output.empty() && (output.back() == '\n' || output.back() == '\r')) {
    output.pop_back();
  }
  return output;
}

std::vector<std::string> Lines(const std::string& text) {
  std::vector<std::string> out;
  std::string current;
  for (const char ch : text) {
    if (ch == '\n') {
      if (!current.empty()) {
        out.push_back(current);
      }
      current.clear();
    } else if (ch != '\r') {
      current += ch;
    }
  }
  if (!current.empty()) {
    out.push_back(current);
  }
  return out;
}

std::string Field(const std::string& text, const std::string& key) {
  const std::string prefix = key + "=";
  const auto start = text.find(prefix);
  if (start == std::string::npos) {
    return {};
  }
  const auto end = text.find('\n', start);
  return text.substr(start + prefix.size(), end == std::string::npos ? std::string::npos : end - start - prefix.size());
}

struct ThemeEntry {
  std::string id;
  std::string label;
};

bool HasCursors(const fs::path& dir) {
  return fs::is_directory(dir / "cursors") || fs::is_directory(dir / "cursors_scalable");
}

std::string KnownLabel(const std::string& id) {
  if (id == "PRTS-Final") {
    return T("PRTS 动画", "PRTS Animated");
  }
  if (id == "PRTS-Final-Static") {
    return T("PRTS 静态", "PRTS Static");
  }
  if (id == "Bibata-Modern-Classic") {
    return "Bibata";
  }
  if (id == "Adwaita") {
    return "Adwaita";
  }
  return id;
}

std::vector<ThemeEntry> DetectThemes() {
  std::vector<ThemeEntry> themes;
  std::vector<std::string> seen;
  const std::string home = HomeDir();
  const std::array<std::string, 3> roots = {home + "/.local/share/icons", home + "/.icons", "/usr/share/icons"};
  for (const auto& root : roots) {
    if (!fs::is_directory(root)) {
      continue;
    }
    for (const auto& entry : fs::directory_iterator(root)) {
      if (!entry.is_directory()) {
        continue;
      }
      const std::string id = entry.path().filename().string();
      if (std::find(seen.begin(), seen.end(), id) != seen.end() || !HasCursors(entry.path())) {
        continue;
      }
      seen.push_back(id);
      themes.push_back({id, KnownLabel(id)});
    }
  }
  const auto rank = [](const std::string& id) {
    if (id == "PRTS-Final") return 0;
    if (id == "PRTS-Final-Static") return 1;
    if (id == "Bibata-Modern-Classic") return 2;
    if (id == "Adwaita") return 3;
    return 10;
  };
  std::stable_sort(themes.begin(), themes.end(), [&](const ThemeEntry& left, const ThemeEntry& right) {
    const int left_rank = rank(left.id);
    const int right_rank = rank(right.id);
    if (left_rank != right_rank) {
      return left_rank < right_rank;
    }
    return left.id < right.id;
  });
  return themes;
}

std::string ShortLabel(const std::string& name) {
  std::string out = name;
  if (out.size() > 18) {
    out = out.substr(0, 17) + "…";
  }
  return out;
}

std::string EffectName(const std::vector<std::string>& effects, std::size_t index) {
  if (index == 0 || index > effects.size()) {
    return "off";
  }
  return effects[index - 1];
}

struct Initial {
  std::string theme;
  float size = 24.0F;
  std::size_t effect = 0;
  float radius = 96.0F;
  std::vector<std::string> effects;
};

const Initial& Current() {
  static const Initial cached = [] {
    Initial value;
    value.effects = Lines(Run(std::string("python3 ") + HelperPath() + " --effects 2>/dev/null"));
    const auto out = Run(std::string("python3 ") + HelperPath() + " --get 2>/dev/null");
    value.theme = Field(out, "theme");
    if (!value.theme.empty()) {
      value.size = static_cast<float>(std::atof(Field(out, "size").c_str()));
      value.radius = static_cast<float>(std::atof(Field(out, "radius").c_str()));
      const auto effect = Field(out, "effect");
      for (std::size_t i = 0; i < value.effects.size(); ++i) {
        if (value.effects[i] == effect) {
          value.effect = i + 1;
        }
      }
    }
    return value;
  }();
  return cached;
}

}  // namespace

View App() {
  const WindowHandle window = UseWindow();
  const Initial init = Current();
  const auto themes = DetectThemes();
  const auto& effects = init.effects;

  std::size_t theme_index = 0;
  for (std::size_t i = 0; i < themes.size(); ++i) {
    if (themes[i].id == init.theme) {
      theme_index = i;
    }
  }

  std::vector<std::string> effect_labels{"off"};
  effect_labels.insert(effect_labels.end(), effects.begin(), effects.end());

  auto themeIndex = UseState(theme_index);
  auto size = UseState(init.size);
  auto effectIndex = UseState(init.effect);
  auto radius = UseState(init.radius);
  auto status = UseState<std::string>(T("改动即时生效", "Changes apply immediately"));

  const auto apply = [=] {
    const std::string theme = themes.empty() ? std::string("Adwaita") : themes[std::min(themeIndex.Get(), themes.size() - 1)].id;
    const std::string result = Run(std::string("python3 ") + HelperPath() +
                                   " --set --theme " + theme +
                                   " --size " + std::to_string(static_cast<int>(size.Get())) +
                                   " --effect " + EffectName(effects, effectIndex.Get()) +
                                   " --radius " + std::to_string(static_cast<int>(radius.Get())) + " 2>&1");
    status = result.empty() || result.rfind("config: ok", 0) == 0 ? T("已应用", "Applied") : result;
  };

  const auto reset = [=] {
    std::size_t index = 0;
    for (std::size_t i = 0; i < themes.size(); ++i) {
      if (themes[i].id == "Bibata-Modern-Classic") {
        index = i;
      }
    }
    themeIndex = index;
    size = 24.0F;
    effectIndex = std::size_t{0};
    radius = 96.0F;
    apply();
  };

  std::vector<StringVariant> theme_labels;
  for (const auto& theme : themes) {
    theme_labels.emplace_back(theme.label);
  }

  constexpr std::size_t columnCount = 4;
  std::vector<View> columns[columnCount];
  for (std::size_t i = 0; i < effect_labels.size(); ++i) {
    columns[i % columnCount].push_back(
        RadioButton(effect_labels[i], effectIndex.Get() == i)
            .OnChanged([effectIndex, i, apply](bool on) mutable {
              if (on) {
                effectIndex = i;
                apply();
              }
            }));
  }
  std::vector<View> grid;
  for (std::size_t c = 0; c < columnCount; ++c) {
    grid.push_back(Column(std::move(columns[c])).With(Spacing(0.0F)));
  }

  return FlatTheme{Column{
      Row{
          Text(T("光标特效切换器", "Cursor Effects Switcher"), TextRole::Title),
          Spacer().With(Grow()),
      }.With(Spacing(6.0F), WindowDragRegion{}),
      Divider(),
      Text(T("主题", "Theme"), TextRole::Label),
      [&]() -> View {
        if (themes.empty()) {
          return Text(T("未检测到已安装的光标主题", "No cursor themes detected"), TextRole::Label);
        }
        if (themes.size() <= 4) {
          return SegmentedButton(theme_labels, themeIndex).OnChanged([themeIndex, apply](std::size_t next) mutable {
            themeIndex = next;
            apply();
          });
        }
        std::vector<View> columns[3];
        for (std::size_t i = 0; i < themes.size(); ++i) {
          columns[i % 3].push_back(
              RadioButton(ShortLabel(themes[i].label), themeIndex.Get() == i)
                  .OnChanged([themeIndex, i, apply](bool on) mutable {
                    if (on) {
                      themeIndex = i;
                      apply();
                    }
                  }));
        }
        return Row{
            Column(std::move(columns[0])).With(Spacing(0.0F)),
            Column(std::move(columns[1])).With(Spacing(0.0F)),
            Column(std::move(columns[2])).With(Spacing(0.0F)),
        }.With(Spacing(14.0F));
      }(),
      Row{
          Text(T("大小", "Size"), TextRole::Label),
          Text::Format("{} px", static_cast<int>(size.Get())),
      }.With(Spacing(6.0F)),
      Slider(size).Range(16.0F, 72.0F).Step(1.0F).OnCommitted([size, apply](float next) mutable {
        size = next;
        apply();
      }),
      Row{
          Text(T("光效半径", "Effect radius"), TextRole::Label),
          Text::Format("{}", static_cast<int>(radius.Get())),
      }.With(Spacing(6.0F)),
      Slider(radius).Range(32.0F, 256.0F).Step(8.0F).OnCommitted([radius, apply](float next) mutable {
        radius = next;
        apply();
      }),
      Text(T("光标光效（单选）", "Cursor effect (single)"), TextRole::Label),
      Row(std::move(grid)).With(Spacing(14.0F)),
      Row{
          Button(T("恢复默认", "Reset")).OnClick(reset),
          Text(status.Get(), TextRole::Label),
      }.With(Spacing(12.0F)),
  }.With(Padding(14.0F), Spacing(6.0F), Background(Color::White()), CornerRadius(12.0F),
         Border{.color = Color::Rgb(226, 228, 236), .width = 1.0F})};
}

const Application application{
    App,
    {.window = {.title = IsZh() ? "光标特效切换器" : "Cursor Effects Switcher",
                .initial_size = {640.0F, 560.0F},
                .minimum_size = Size{640.0F, 560.0F},
                .chrome_mode = WindowChromeMode::Custom,
                .title_bar_height = 46.0F}},
};
