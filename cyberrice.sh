#!/usr/bin/env bash
# ============================================================
#  DevForge OS — CyberRice 🤖⚡
#  Futuristic Cyberpunk GNOME Rice
#  Run as normal user (NOT root): ./cyberrice.sh
# ============================================================

set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'; RED='\033[0;31m'; BOLD='\033[1m'; RESET='\033[0m'
NEON='\033[38;5;51m'

USERNAME="${USER}"
HOME_DIR="$HOME"

log()    { echo -e "${GREEN}[✔]${RESET} $*"; }
warn()   { echo -e "${YELLOW}[!]${RESET} $*"; }
info()   { echo -e "${CYAN}[→]${RESET} $*"; }
banner() {
  echo -e "\n${BOLD}${NEON}╔═══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${NEON}║  ⚡ $*$(printf '%*s' $((43 - ${#*})) '')║${RESET}"
  echo -e "${BOLD}${NEON}╚═══════════════════════════════════════════════╝${RESET}\n"
}

[[ $EUID -eq 0 ]] && echo -e "${RED}Run as normal user, NOT root!${RESET}" && exit 1

# ── Cyberpunk Color Palette ──────────────────────────────────
# Primary neon:  #00fff5 (cyan)
# Secondary:     #ff00a0 (hot pink)
# Accent:        #7700ff (purple)
# Warning:       #ffff00 (yellow)
# Background:    #0a0a0f (near black)
# Surface:       #0d1117 (dark blue-black)

# ── Install AUR packages ─────────────────────────────────────
install_packages() {
  banner "Installing Rice Packages"

  # Core rice tools
  sudo pacman -S --noconfirm --needed \
    conky \
    rofi \
    dunst \
    mpd ncmpcpp \
    playerctl \
    lm_sensors \
    xorg-xrandr \
    feh \
    imagemagick \
    python-requests \
    python-psutil \
    xdotool \
    wmctrl \
    ffmpeg \
    mpv \
    unzip wget curl git

  # AUR packages
  yay -S --noconfirm \
    oh-my-posh-bin \
    gnome-shell-extension-aylurs-gtk-shell \
    wpgtk-git \
    cava \
    pipes.sh \
    cbonsai \
    tty-clock \
    python-pywal \
    hollywood 2>/dev/null || warn "Some AUR packages failed — continuing"

  log "Packages installed"
}

# ── Cyberpunk Wallpaper (generated) ──────────────────────────
create_wallpaper() {
  banner "Generating Cyberpunk Wallpaper"

  mkdir -p "$HOME_DIR/Pictures/wallpapers"

  # Generate cyberpunk wallpaper using Python + ImageMagick
  python3 << 'WALLPAPER'
import subprocess
import os
import math

home = os.path.expanduser("~")
out = f"{home}/Pictures/wallpapers/cyberforge.png"

# Build ImageMagick command for cyberpunk wallpaper
cmd = [
    "convert",
    "-size", "1920x1080",
    # Dark background
    "xc:#0a0a0f",
    # Grid lines horizontal
    "-fill", "none",
    "-stroke", "#00fff510",
    "-strokewidth", "1",
]

# Add grid lines
for i in range(0, 1920, 60):
    cmd += ["-draw", f"line {i},0 {i},1080"]
for i in range(0, 1080, 60):
    cmd += ["-draw", f"line 0,{i} 1920,{i}"]

# Neon glow circles
cmd += [
    "-fill", "none",
    "-stroke", "#00fff520",
    "-strokewidth", "2",
    "-draw", "circle 960,540 960,740",
    "-stroke", "#ff00a015",
    "-strokewidth", "1",
    "-draw", "circle 960,540 960,840",
    "-stroke", "#7700ff20",
    "-strokewidth", "3",
    "-draw", "circle 960,540 960,640",
]

# Corner accents
cmd += [
    "-stroke", "#00fff540",
    "-strokewidth", "2",
    "-draw", "line 0,0 200,0",
    "-draw", "line 0,0 0,200",
    "-draw", "line 1920,0 1720,0",
    "-draw", "line 1920,0 1920,200",
    "-draw", "line 0,1080 200,1080",
    "-draw", "line 0,1080 0,880",
    "-draw", "line 1920,1080 1720,1080",
    "-draw", "line 1920,1080 1920,880",
]

# DevForge text
cmd += [
    "-fill", "#00fff5",
    "-font", "DejaVu-Sans-Bold",
    "-pointsize", "14",
    "-annotate", "+20+30", "DEVFORGE OS // ARCH EDITION",
    "-fill", "#ff00a0",
    "-pointsize", "11",
    "-annotate", "+20+50", "FLUTTER DEVELOPER WORKSTATION",
    "-fill", "#7700ff",
    "-pointsize", "10",
    "-annotate", "+1750+30", "v2.0",
]

# Bottom scanline effect
cmd += [
    "-fill", "#00fff505",
]
for i in range(0, 1080, 4):
    cmd += ["-draw", f"line 0,{i} 1920,{i}"]

cmd += [out]

try:
    subprocess.run(cmd, check=True, capture_output=True)
    print(f"Wallpaper created: {out}")
except Exception as e:
    # Fallback: simple gradient
    subprocess.run([
        "convert", "-size", "1920x1080",
        "gradient:#0a0a0f-#0d1117",
        out
    ])
    print(f"Fallback wallpaper created: {out}")
WALLPAPER

  # Set as wallpaper
  gsettings set org.gnome.desktop.background picture-uri \
    "file://$HOME_DIR/Pictures/wallpapers/cyberforge.png" 2>/dev/null || true
  gsettings set org.gnome.desktop.background picture-uri-dark \
    "file://$HOME_DIR/Pictures/wallpapers/cyberforge.png" 2>/dev/null || true
  gsettings set org.gnome.desktop.background picture-options "zoom"

  log "Cyberpunk wallpaper set"
}

# ── Conky Widgets ────────────────────────────────────────────
setup_conky() {
  banner "Conky Widgets"

  mkdir -p "$HOME_DIR/.config/conky"

  # ── Main widget (clock + system stats) ──────────────────
  cat > "$HOME_DIR/.config/conky/cyberforge.conf" << 'CONKY'
conky.config = {
  -- Window
  own_window = true,
  own_window_type = 'desktop',
  own_window_transparent = true,
  own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',
  own_window_argb_visual = true,
  own_window_argb_value = 0,

  -- Position (top right)
  alignment = 'top_right',
  gap_x = 30,
  gap_y = 50,

  -- Size
  minimum_width = 280,
  maximum_width = 280,

  -- Update
  update_interval = 1,
  double_buffer = true,
  no_buffers = true,

  -- Fonts
  use_xft = true,
  font = 'JetBrains Mono:size=9',
  xftalpha = 1,

  -- Colors
  default_color = '00fff5',
  color1 = 'ff00a0',
  color2 = '7700ff',
  color3 = 'ffff00',
  color4 = '0a0a0f',
  color5 = 'ffffff',
  color6 = '00ff88',

  -- No borders
  draw_borders = false,
  draw_graph_borders = false,
  border_width = 0,
  stippled_borders = 0,
}

conky.text = [[
${color1}╔══════════════════════════════╗${color}
${color1}║${color}  ${font JetBrains Mono:bold:size=28}${time %H:%M}${font}   ${color1}${font JetBrains Mono:size=9}${time %a %d %b}${font}  ${color1}║${color}
${color1}╚══════════════════════════════╝${color}

${color2}⚡ SYSTEM${color}  ${hr 1}

${color1}󰻠 CPU${color}      ${cpu cpu0}%  ${cpubar cpu0 6,180}
${color6}  Core 1:${color}  ${cpu cpu1}%   ${color6}Core 2:${color} ${cpu cpu2}%
${color6}  Core 3:${color}  ${cpu cpu3}%   ${color6}Core 4:${color} ${cpu cpu4}%
${color6}  Temp:${color}    ${hwmon 0 temp 1}°C

${color1}󰍛 RAM${color}      ${memperc}%  ${membar 6,180}
${color6}  Used:${color}    ${mem} / ${memmax}
${color6}  Free:${color}    ${memfree}

${color1}󰋊 DISK${color}     ${fs_used_perc /}%  ${fs_bar 6,180 /}
${color6}  Used:${color}    ${fs_used /} / ${fs_size /}
${color6}  Free:${color}    ${fs_free /}

${color2}⚡ NETWORK${color}  ${hr 1}
${color1}󰁅 Down:${color}    ${downspeed wlan0}/s   ${color1}󰁝 Up:${color} ${upspeed wlan0}/s
${color6}  IP:${color}      ${addr wlan0}

${color2}⚡ PROCESSES${color}  ${hr 1}
${color1}  CPU Top:${color}
  ${top name 1}  ${color6}${top cpu 1}%${color}
  ${top name 2}  ${color6}${top cpu 2}%${color}
  ${top name 3}  ${color6}${top cpu 3}%${color}

${color1}  MEM Top:${color}
  ${top_mem name 1}  ${color6}${top_mem mem_res 1}${color}
  ${top_mem name 2}  ${color6}${top_mem mem_res 2}${color}

${color2}⚡ FLUTTER${color}  ${hr 1}
${color6}  SDK:${color}     ~/development/flutter
${color6}  Android:${color} ~/Android/Sdk
${color1}  fldoc${color} → flutter doctor

${color1}╔══════════════════════════════╗${color}
${color1}║${color}  DEVFORGE OS // ARCH 🏹      ${color1}║${color}
${color1}╚══════════════════════════════╝${color}
]];
CONKY

  # ── Music widget ────────────────────────────────────────
  cat > "$HOME_DIR/.config/conky/music.conf" << 'MUSICONKY'
conky.config = {
  own_window = true,
  own_window_type = 'desktop',
  own_window_transparent = true,
  own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',
  own_window_argb_visual = true,
  own_window_argb_value = 0,
  alignment = 'bottom_right',
  gap_x = 30,
  gap_y = 80,
  minimum_width = 280,
  maximum_width = 280,
  update_interval = 1,
  double_buffer = true,
  use_xft = true,
  font = 'JetBrains Mono:size=9',
  default_color = '00fff5',
  color1 = 'ff00a0',
  color2 = '7700ff',
  color6 = '00ff88',
  draw_borders = false,
}

conky.text = [[
${color2}⚡ NOW PLAYING${color}  ${hr 1}
${color1}  ${color}${exec playerctl metadata title 2>/dev/null | head -c 30 || echo "No media playing"}
${color6}  ${color}${exec playerctl metadata artist 2>/dev/null | head -c 30 || echo ""}
${color6}  Status:${color} ${exec playerctl status 2>/dev/null || echo "Stopped"}

  ${color1}⏮${color}  prev    ${color1}⏸${color}  pause    ${color1}⏭${color}  next
  playerctl prev/play-pause/next
]];
MUSICONKY

  # ── Autostart conky ─────────────────────────────────────
  mkdir -p "$HOME_DIR/.config/autostart"
  cat > "$HOME_DIR/.config/autostart/conky-cyberforge.desktop" << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=Conky CyberForge
Exec=conky -c /home/USERPLACEHOLDER/.config/conky/cyberforge.conf
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
DESKTOP

  cat > "$HOME_DIR/.config/autostart/conky-music.desktop" << 'DESKTOP2'
[Desktop Entry]
Type=Application
Name=Conky Music
Exec=conky -c /home/USERPLACEHOLDER/.config/conky/music.conf
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
DESKTOP2

  # Replace placeholder with actual username
  sed -i "s/USERPLACEHOLDER/$USERNAME/g" \
    "$HOME_DIR/.config/autostart/conky-cyberforge.desktop" \
    "$HOME_DIR/.config/autostart/conky-music.desktop"

  log "Conky widgets configured"
}

# ── Rofi App Launcher ────────────────────────────────────────
setup_rofi() {
  banner "Rofi App Launcher"

  mkdir -p "$HOME_DIR/.config/rofi"

  cat > "$HOME_DIR/.config/rofi/cyberforge.rasi" << 'ROFI'
/* CyberForge Rofi Theme */
* {
  bg:          #0a0a0fee;
  bg-alt:      #0d1117ee;
  fg:          #00fff5;
  fg-alt:      #7700ff;
  accent:      #ff00a0;
  urgent:      #ffff00;
  font:        "JetBrains Mono 12";
}

window {
  background-color: @bg;
  border:           2px solid;
  border-color:     @accent;
  border-radius:    8px;
  width:            600px;
  padding:          20px;
}

mainbox {
  background-color: transparent;
  spacing:          10px;
}

inputbar {
  background-color: @bg-alt;
  border:           1px solid @fg-alt;
  border-radius:    4px;
  padding:          10px 14px;
  spacing:          10px;
  children:         [ prompt, entry ];
}

prompt {
  background-color: transparent;
  text-color:       @accent;
  font:             "JetBrains Mono Bold 12";
}

entry {
  background-color: transparent;
  text-color:       @fg;
  placeholder:      "search apps...";
  placeholder-color: #ffffff40;
}

listview {
  background-color: transparent;
  lines:            8;
  columns:          1;
  spacing:          4px;
  margin:           10px 0 0 0;
}

element {
  background-color: transparent;
  border-radius:    4px;
  padding:          8px 14px;
  spacing:          10px;
  orientation:      horizontal;
}

element normal.normal {
  background-color: transparent;
  text-color:       @fg;
}

element selected.normal {
  background-color: #00fff515;
  border:           1px solid @fg;
  border-radius:    4px;
  text-color:       @fg;
}

element-text {
  background-color: transparent;
  text-color:       inherit;
  vertical-align:   0.5;
}

element-icon {
  background-color: transparent;
  size:             24px;
}
ROFI

  # Keybinding: Super+Space → Rofi
  mkdir -p "$HOME_DIR/.config/autostart"
  cat > "$HOME_DIR/.config/autostart/rofi-keybind.desktop" << ROFIDESKTOP
[Desktop Entry]
Type=Application
Name=Rofi Keybind
Exec=bash -c "sleep 3 && xbindkeys"
Hidden=false
X-GNOME-Autostart-enabled=true
ROFIDESKTOP

  # xbindkeys config
  cat > "$HOME_DIR/.xbindkeysrc" << 'XBIND'
"rofi -show drun -theme /home/USERPLACEHOLDER/.config/rofi/cyberforge.rasi"
  Super + space

"rofi -show window -theme /home/USERPLACEHOLDER/.config/rofi/cyberforge.rasi"
  Super + Tab
XBIND
  sed -i "s/USERPLACEHOLDER/$USERNAME/g" "$HOME_DIR/.xbindkeysrc"

  log "Rofi configured — Super+Space to launch"
}

# ── Custom GRUB Theme ─────────────────────────────────────────
setup_grub() {
  banner "Cyberpunk GRUB Theme"

  sudo mkdir -p /boot/grub/themes/cyberforge

  # Generate GRUB background
  sudo python3 << 'GRUBWALLPAPER'
import subprocess
out = "/boot/grub/themes/cyberforge/background.png"
subprocess.run([
  "convert", "-size", "1920x1080",
  "xc:#0a0a0f",
  "-fill", "none",
  "-stroke", "#00fff520", "-strokewidth", "1",
  "-draw", "line 0,540 1920,540",
  "-draw", "line 960,0 960,1080",
  "-stroke", "#ff00a015",
  "-draw", "circle 960,540 960,700",
  "-fill", "#00fff5",
  "-font", "DejaVu-Sans-Bold", "-pointsize", "48",
  "-annotate", "+660+480", "DEVFORGE OS",
  "-fill", "#ff00a0",
  "-pointsize", "18",
  "-annotate", "+720+520", "ARCH EDITION  //  SELECT OS",
  out
], capture_output=True)
GRUBWALLPAPER

  # GRUB theme.txt
  sudo tee /boot/grub/themes/cyberforge/theme.txt > /dev/null << 'GRUBTHEME'
# CyberForge GRUB Theme
title-text: ""
desktop-image: "background.png"
desktop-color: "#0a0a0f"

+ boot_menu {
  left = 30%
  top = 55%
  width = 40%
  height = 30%
  item_color = "#00fff5"
  item_font = "JetBrains Mono Regular 14"
  selected_item_color = "#0a0a0f"
  selected_item_font = "JetBrains Mono Bold 14"
  selected_background = "#00fff5"
  item_height = 36
  item_padding = 10
  item_spacing = 4
  scrollbar = false
}

+ label {
  top = 90%
  left = 0
  width = 100%
  align = "center"
  text = "DEVFORGE OS  //  🏹 ARCH EDITION  //  USE ↑↓ TO SELECT"
  color = "#ff00a080"
  font = "JetBrains Mono Regular 10"
}
GRUBTHEME

  # Apply GRUB theme
  sudo sed -i 's|^#\?GRUB_THEME=.*|GRUB_THEME=/boot/grub/themes/cyberforge/theme.txt|' /etc/default/grub
  sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || warn "GRUB update failed — run manually"

  log "GRUB theme installed"
}

# ── GDM Login Screen ─────────────────────────────────────────
setup_gdm() {
  banner "Cyberpunk GDM Login Screen"

  # Copy wallpaper to GDM
  sudo mkdir -p /usr/share/pixmaps/cyberforge
  sudo cp "$HOME_DIR/Pictures/wallpapers/cyberforge.png" \
    /usr/share/pixmaps/cyberforge/login.png 2>/dev/null || warn "Copy wallpaper failed"

  # GDM CSS override
  GDM_CSS="/usr/share/gnome-shell/gnome-shell-theme.gresource"
  WORK_DIR="/tmp/gdm-theme"
  mkdir -p "$WORK_DIR"

  # Create custom GDM theme via gnome-shell CSS
  sudo tee /usr/share/gnome-shell/extensions/cyberforge-gdm.css > /dev/null << 'GDMCSS' 2>/dev/null || true
#lockDialogGroup {
  background-image: url('/usr/share/pixmaps/cyberforge/login.png');
  background-size: cover;
  background-position: center;
}

.login-dialog {
  background-color: rgba(10, 10, 15, 0.85);
  border: 1px solid #00fff5;
  border-radius: 8px;
}

.login-dialog StEntry {
  background-color: rgba(13, 17, 23, 0.9);
  border: 1px solid #7700ff;
  color: #00fff5;
  border-radius: 4px;
}

.login-dialog-user-list-item {
  color: #00fff5;
}
GDMCSS

  # dconf GDM settings
  sudo -u gdm dbus-launch gsettings set \
    org.gnome.login-screen logo '' 2>/dev/null || true
  sudo -u gdm dbus-launch gsettings set \
    org.gnome.desktop.background picture-uri \
    "file:///usr/share/pixmaps/cyberforge/login.png" 2>/dev/null || true

  log "GDM theme configured"
}

# ── Terminal Cyberpunk Colors ─────────────────────────────────
setup_terminal_colors() {
  banner "Cyberpunk Terminal Colors"

  # GNOME Terminal profile
  PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")

  gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/" \
    use-theme-colors false 2>/dev/null || true

  # Background & text
  gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/" \
    background-color '#0a0a0f' 2>/dev/null || true
  gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/" \
    foreground-color '#00fff5' 2>/dev/null || true
  gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/" \
    use-transparent-background true 2>/dev/null || true
  gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/" \
    background-transparency-percent 15 2>/dev/null || true
  gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/" \
    font 'JetBrains Mono 12' 2>/dev/null || true

  # Cyberpunk 16-color palette
  gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/" \
    palette "['#0a0a0f', '#ff00a0', '#00ff88', '#ffff00', '#00fff5', '#7700ff', '#00e5ff', '#c0c0c0', '#1a1a2e', '#ff69b4', '#39ff14', '#ffd700', '#00ffff', '#bf00ff', '#00ced1', '#ffffff']" \
    2>/dev/null || true

  # Also write .Xresources for other terminals
  cat > "$HOME_DIR/.Xresources" << 'XRESOURCES'
! CyberForge Terminal Colors
*background:  #0a0a0f
*foreground:  #00fff5
*cursorColor: #ff00a0

*color0:  #0a0a0f
*color1:  #ff00a0
*color2:  #00ff88
*color3:  #ffff00
*color4:  #00fff5
*color5:  #7700ff
*color6:  #00e5ff
*color7:  #c0c0c0
*color8:  #1a1a2e
*color9:  #ff69b4
*color10: #39ff14
*color11: #ffd700
*color12: #00ffff
*color13: #bf00ff
*color14: #00ced1
*color15: #ffffff

! Font
*font: xft:JetBrains Mono:size=12
*faceName: JetBrains Mono
*faceSize: 12

! Transparency
*depth: 32
*visualBell: false
XRESOURCES

  xrdb -merge "$HOME_DIR/.Xresources" 2>/dev/null || true

  # Kitty terminal config (better transparency support)
  mkdir -p "$HOME_DIR/.config/kitty"
  cat > "$HOME_DIR/.config/kitty/kitty.conf" << 'KITTY'
# CyberForge Kitty Config
font_family      JetBrains Mono
font_size        12.0
bold_font        JetBrains Mono Bold
italic_font      JetBrains Mono Italic

# Cyberpunk colors
background            #0a0a0f
foreground            #00fff5
cursor                #ff00a0
cursor_text_color     #0a0a0f
selection_background  #7700ff
selection_foreground  #00fff5

# 16 colors
color0  #0a0a0f
color1  #ff00a0
color2  #00ff88
color3  #ffff00
color4  #00fff5
color5  #7700ff
color6  #00e5ff
color7  #c0c0c0
color8  #1a1a2e
color9  #ff69b4
color10 #39ff14
color11 #ffd700
color12 #00ffff
color13 #bf00ff
color14 #00ced1
color15 #ffffff

# Window
background_opacity    0.88
window_padding_width  12
hide_window_decorations no
remember_window_size  yes

# Neon border
active_border_color   #00fff5
inactive_border_color #7700ff40

# Tab bar
tab_bar_style         powerline
tab_powerline_style   angled
active_tab_background #00fff5
active_tab_foreground #0a0a0f
inactive_tab_background #0d1117
inactive_tab_foreground #00fff580

# Bell
enable_audio_bell no
visual_bell_duration 0.1
visual_bell_color #ff00a0

# Scrollback
scrollback_lines 10000
KITTY

  # Install kitty
  sudo pacman -S --noconfirm --needed kitty 2>/dev/null || warn "kitty install failed"

  log "Terminal colors configured — kitty + GNOME Terminal"
}

# ── Dev App Shortcuts (VS Code + JetBrains) ──────────────────
setup_app_shortcuts() {
  banner "Dev App Quick Launch Shortcuts"

  mkdir -p "$HOME_DIR/.local/share/applications"

  # VS Code launcher
  cat > "$HOME_DIR/.local/share/applications/cyberforge-vscode.desktop" << VSCODE
[Desktop Entry]
Name=VS Code ⚡
Comment=Code Editor
Exec=code %F
Icon=code
Terminal=false
Type=Application
Categories=Development;
Keywords=vscode;code;editor;
StartupWMClass=Code
VSCODE

  # Android Studio launcher
  cat > "$HOME_DIR/.local/share/applications/cyberforge-android-studio.desktop" << ANDROID
[Desktop Entry]
Name=Android Studio 🤖
Comment=Flutter & Android IDE
Exec=android-studio %F
Icon=android-studio
Terminal=false
Type=Application
Categories=Development;IDE;
Keywords=android;flutter;studio;
ANDROID

  # Flutter Doctor quick terminal
  cat > "$HOME_DIR/.local/share/applications/cyberforge-flutter.desktop" << FLUTTER
[Desktop Entry]
Name=Flutter Doctor ⚡
Comment=Check Flutter Setup
Exec=kitty -e bash -c "flutter doctor -v; read"
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Development;
FLUTTER

  # Rofi dev menu script
  cat > "$HOME_DIR/.local/bin/devmenu" << 'DEVMENU'
#!/usr/bin/env bash
# CyberForge Dev App Menu
CHOICE=$(echo -e "💙 VS Code\n🤖 Android Studio\n🐦 Flutter Doctor\n🦊 Firefox\n🐳 Docker Stats\n🗄️ DBeaver\n📊 btop\n🎵 ncmpcpp" | \
  rofi -dmenu \
  -p "⚡ DevForge" \
  -theme "$HOME/.config/rofi/cyberforge.rasi" \
  -i)

case "$CHOICE" in
  "💙 VS Code")          code ;;
  "🤖 Android Studio")   android-studio ;;
  "🐦 Flutter Doctor")   kitty -e bash -c "flutter doctor -v; read" ;;
  "🦊 Firefox")          firefox ;;
  "🐳 Docker Stats")     kitty -e bash -c "docker stats; read" ;;
  "🗄️ DBeaver")          dbeaver ;;
  "📊 btop")             kitty -e btop ;;
  "🎵 ncmpcpp")          kitty -e ncmpcpp ;;
esac
DEVMENU

  chmod +x "$HOME_DIR/.local/bin/devmenu"

  # Add Super+D as dev menu shortcut
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
    "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']" 2>/dev/null || true

  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ \
    name 'Terminal' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ \
    command 'kitty' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ \
    binding '<Super>t' 2>/dev/null || true

  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ \
    name 'Dev Menu' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ \
    command "$HOME_DIR/.local/bin/devmenu" 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ \
    binding '<Super>d' 2>/dev/null || true

  log "Dev shortcuts configured — Super+D for dev menu"
}

# ── Cava Audio Visualizer ────────────────────────────────────
setup_cava() {
  banner "Cava Audio Visualizer"
  mkdir -p "$HOME_DIR/.config/cava"
  cat > "$HOME_DIR/.config/cava/config" << 'CAVA'
[general]
bars = 50
bar_width = 2
bar_spacing = 1
framerate = 60
sensitivity = 100

[color]
gradient = 1
gradient_count = 4
gradient_color_1 = '#7700ff'
gradient_color_2 = '#ff00a0'
gradient_color_3 = '#00fff5'
gradient_color_4 = '#00ff88'

[smoothing]
noise_reduction = 77
CAVA
  log "Cava configured"
}

# ── Neofetch cyberpunk config ────────────────────────────────
setup_neofetch() {
  banner "Neofetch Cyberpunk Config"
  mkdir -p "$HOME_DIR/.config/neofetch"
  cat > "$HOME_DIR/.config/neofetch/config.conf" << 'NEOFETCH'
print_info() {
  prin "$(color 6)⚡ DEVFORGE OS$(color) // ARCH EDITION 🏹"
  prin ""
  info "$(color 1)OS$(color)"         distro
  info "$(color 1)Kernel$(color)"     kernel
  info "$(color 1)Shell$(color)"      shell
  info "$(color 1)DE$(color)"         de
  info "$(color 1)WM$(color)"         wm
  info "$(color 1)Theme$(color)"      theme
  info "$(color 1)Icons$(color)"      icons
  info "$(color 1)Terminal$(color)"   term
  prin ""
  info "$(color 5)CPU$(color)"        cpu
  info "$(color 5)GPU$(color)"        gpu
  info "$(color 5)Memory$(color)"     memory
  info "$(color 5)Disk$(color)"       disk
  prin ""
  info "$(color 4)Flutter$(color)"    flutter_version
  info "$(color 4)Dart$(color)"       dart_version
  info "$(color 4)Node$(color)"       node_version
  info "$(color 4)Python$(color)"     python_version
  prin ""
  info cols
}

flutter_version() {
  flutter --version 2>/dev/null | awk 'NR==1{print "Flutter " $2}' || echo "not installed"
}
dart_version() {
  dart --version 2>/dev/null | awk '{print $4}' || echo "not installed"
}
node_version() {
  node --version 2>/dev/null || echo "not installed"
}

# ASCII art
ascii_distro="arch"
ascii_colors=(6 6 1 1 3 3)
bold=on

# Image
image_backend="ascii"
gap=3
NEOFETCH
  log "Neofetch configured"
}

# ── Summary ──────────────────────────────────────────────────
print_summary() {
  echo ""
  echo -e "${BOLD}${NEON}╔═══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${NEON}║  ⚡ CyberRice Complete! 🤖                     ║${RESET}"
  echo -e "${BOLD}${NEON}╚═══════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "  ${CYAN}✦ Widgets:${RESET}    Conky (clock + stats + music) top-right"
  echo -e "  ${CYAN}✦ Wallpaper:${RESET}  Cyberpunk grid generated"
  echo -e "  ${CYAN}✦ GRUB:${RESET}       CyberForge dark theme"
  echo -e "  ${CYAN}✦ GDM:${RESET}        Cyberpunk login screen"
  echo -e "  ${CYAN}✦ Terminal:${RESET}   Kitty + neon color scheme"
  echo -e "  ${CYAN}✦ Launcher:${RESET}   Rofi (Super+Space)"
  echo -e "  ${CYAN}✦ Dev Menu:${RESET}   Super+D → all your dev apps"
  echo -e "  ${CYAN}✦ Visualizer:${RESET} cava (run 'cava' in terminal)"
  echo ""
  echo -e "  ${YELLOW}⚡ Keyboard shortcuts:${RESET}"
  echo -e "  Super+Space  → App launcher (Rofi)"
  echo -e "  Super+D      → Dev app menu (VS Code, Android Studio...)"
  echo -e "  Super+T      → Kitty terminal"
  echo -e "  Super+1..6   → Switch workspaces"
  echo ""
  echo -e "  ${YELLOW}⚡ Log out and back in to see full changes!${RESET}"
  echo ""
}

# ── Main ─────────────────────────────────────────────────────
main() {
  banner "CyberRice — Futuristic Cyberpunk Rice 🤖⚡"
  install_packages
  create_wallpaper
  setup_conky
  setup_rofi
  setup_grub
  setup_gdm
  setup_terminal_colors
  setup_app_shortcuts
  setup_cava
  setup_neofetch
  print_summary
}

main "$@"
