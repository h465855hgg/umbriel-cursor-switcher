#!/usr/bin/env python3
"""PRTS 光标：读写 Umbriel 光标配置与 shader 光效。"""
import argparse, pathlib, re, subprocess, sys, tomllib

HOME = pathlib.Path.home()
CFG = HOME / ".config/umbriel/config.toml"
SHADER_DIR = HOME / ".config/umbriel/shaders/community/cursor"

def preset_files():
    """返回 {预设名: effect.toml 路径}，扫描已安装的社区 cursor 效果。"""
    found = {}
    for p in sorted(SHADER_DIR.glob("*/effect.toml")):
        try:
            d = tomllib.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue
        for name, preset in d.get("effects", {}).get("preset", {}).items():
            if preset.get("kind") == "cursor":
                found[name] = p
    return found

def read_state():
    d = tomllib.loads(CFG.read_text(encoding="utf-8"))
    cur = d.get("input", {}).get("cursor", {})
    effect = d.get("effects", {}).get("cursor", "") or "off"
    radius = 96
    p = preset_files().get(effect)
    if p is not None:
        try:
            sd = tomllib.loads(p.read_text(encoding="utf-8"))
            radius = int(sd.get("effects", {}).get("preset", {}).get(effect, {}).get("radius", radius))
        except Exception:
            pass
    return {
        "theme": cur.get("theme", ""),
        "size": int(cur.get("size", 24)),
        "effect": effect,
        "radius": radius,
    }

def upsert(text, section, key, literal):
    lines = text.splitlines()
    start = next((i for i, l in enumerate(lines) if l.strip() == f"[{section}]"), None)
    if start is None:
        if lines and lines[-1].strip():
            lines.append("")
        lines += [f"[{section}]", f"{key} = {literal}"]
        return "\n".join(lines) + "\n"
    end = len(lines)
    for j in range(start + 1, len(lines)):
        s = lines[j].strip()
        if s.startswith("[") and not s.startswith("#"):
            end = j
            break
    for j in range(start + 1, end):
        if re.match(rf"\s*{re.escape(key)}\s*=", lines[j]):
            lines[j] = f"{key} = {literal}"
            break
    else:
        lines.insert(start + 1, f"{key} = {literal}")
    return "\n".join(lines) + "\n"

def apply(theme, size, effect, radius):
    text = CFG.read_text(encoding="utf-8")
    text = upsert(text, "input.cursor", "theme", f'"{theme}"')
    text = upsert(text, "input.cursor", "size", str(int(size)))
    text = upsert(text, "effects", "cursor", f'"{effect}"' if effect != "off" else '""')
    CFG.write_text(text, encoding="utf-8")

    p = preset_files().get(effect)
    if p is not None:
        s = p.read_text(encoding="utf-8")
        s = re.sub(r"(?m)^radius\s*=\s*\d+", f"radius = {int(radius)}", s)
        p.write_text(s, encoding="utf-8")

    report = []
    v = subprocess.run(["umbriel", "config", "validate", "-c", str(CFG)], capture_output=True, text=True)
    report.append((v.stdout.strip() or v.stderr.strip()).splitlines()[0] if (v.stdout or v.stderr) else "")
    r = subprocess.run(["umbriel", "msg", "config-reload"], capture_output=True, text=True)
    if r.returncode != 0:
        report.append("重载失败: " + (r.stderr.strip() or r.stdout.strip()))
    e = subprocess.run(["umbriel", "msg", "effect-cursor-set", effect if effect != "off" else "off"], capture_output=True, text=True)
    if e.returncode != 0:
        report.append("光效切换失败: " + (e.stderr.strip() or e.stdout.strip()))
    return "；".join(x for x in report if x) or "已应用"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--get", action="store_true")
    ap.add_argument("--effects", action="store_true")
    ap.add_argument("--set", action="store_true")
    ap.add_argument("--theme", default="")
    ap.add_argument("--size", type=float, default=24)
    ap.add_argument("--effect", default="off")
    ap.add_argument("--radius", type=float, default=96)
    a = ap.parse_args()
    if a.get:
        for k, v in read_state().items():
            print(f"{k}={v}")
        return
    if a.effects:
        names = sorted(preset_files().keys())
        print("\n".join(names))
        return
    if a.set:
        print(apply(a.theme, a.size, a.effect, a.radius))
        return
    ap.print_help()

if __name__ == "__main__":
    main()
