# DevForge OS — Complete Script Pack 🏹⚡
## EndeavourOS / Arch Linux — Flutter Developer Setup

---

## Scripts (run in this order):

### 1. devforge.sh — Main setup
Installs everything: GNOME, Flutter, Android Studio, all languages, CLI tools, VS Code

```bash
chmod +x devforge.sh
sudo ./devforge.sh
```

### 2. cyberrice.sh — Cyberpunk rice
Futuristic GNOME theme: neon colors, conky widgets, cyberpunk GRUB, kitty terminal

```bash
chmod +x cyberrice.sh
./cyberrice.sh
```

### 3. smartshell.sh — Smart terminal
Fish-style autosuggestions, fuzzy history, tab completions with preview, syntax highlighting

```bash
chmod +x smartshell.sh
./smartshell.sh
source ~/.zshrc
```

### 4. switch-rice.sh — Switch to AllBlue rice
Undoes cyberrice and installs Youngermaster AllBlue dotfiles (Hyprland + Waybar)

```bash
chmod +x switch-rice.sh
./switch-rice.sh
```

---

## Keyboard shortcuts after setup:

| Shortcut | Action |
|----------|--------|
| Super+Space | App launcher (Rofi) |
| Super+D | Dev app menu |
| Super+T | Kitty terminal |
| Super+1..6 | Switch workspaces |
| → arrow | Accept shell suggestion |
| Ctrl+R | Fuzzy history search |
| Tab | Fuzzy completion with preview |
| Esc Esc | Fix wrong command |

## Flutter aliases:
| Alias | Command |
|-------|---------|
| flr | flutter run |
| flb | flutter build |
| flt | flutter test |
| flc | flutter clean |
| flpg | flutter pub get |
| fldoc | flutter doctor -v |
| flnew myapp | Create new Flutter project |

---

## Partition layout used:
```
256GB SSD:
├── 1GB    /boot/efi
├── 100GB  /
├── 8GB    swap
└── 147GB  /home

1TB HDD:
├── Windows 10 (35GB)
└── Data storage
```

---
Built with ❤️ for yami@devforge
