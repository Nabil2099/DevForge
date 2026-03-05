#!/usr/bin/env bash
# ============================================================
#  DevForge OS — Rice Switcher 🎨
#  1. Undoes CyberRice completely
#  2. Installs Youngermaster AllBlue dotfiles
#     (Hyprland + Waybar + Kitty + Rofi + Cava + Dunst)
#  Run as normal user (NOT root): ./switch-rice.sh
# ============================================================

set -uo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'; RED='\033[0;31m'; BOLD='\033[1m'; RESET='\033[0m'

log()    { echo -e "${GREEN}[✔]${RESET} $*"; }
warn()   { echo -e "${YELLOW}[!]${RESET} $*"; }
info()   { echo -e "${CYAN}[→]${RESET} $*"; }
banner() {
  echo -e "\n${BOLD}${MAGENTA}╔═══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${MAGENTA}║  🎨 $*$(printf '%*s' $((42 - ${#*})) '')║${RESET}"
  echo -e "${BOLD}${MAGENTA}╚═══════════════════════════════════════════════╝${RESET}\n"
}

[[ $EUID -eq 0 ]] && echo -e "${RED}Run as normal user, NOT root!${RESET}" && exit 1

# ── PHASE 1: Undo CyberRice ──────────────────────────────────
undo_cyberrice() {
  banner "Undoing CyberRice"

  # Kill running conky instances
  info "Stopping conky widgets..."
  pkill conky 2>/dev/null || true
  pkill cava  2>/dev/null || true

  # Remove conky autostart
  rm -f ~/.config/autostart/conky-cyberforge.desktop
  rm -f ~/.config/autostart/conky-music.desktop
  rm -f ~/.config/autostart/rofi-keybind.desktop
  log "Autostart entries removed"

  # Remove cyberrice configs
  rm -rf ~/.config/conky
  rm -f  ~/.config/rofi/cyberforge.rasi
  rm -f  ~/.xbindkeysrc
  rm -f  ~/.Xresources
  log "CyberRice configs removed"

  # Remove cyberpunk kitty config
  rm -f ~/.config/kitty/kitty.conf
  log "Kitty cyberpunk config removed"

  # Restore GRUB to default (remove cyberforge theme)
  sudo sed -i 's|^GRUB_THEME=.*|#GRUB_THEME=|' /etc/default/grub 2>/dev/null || true
  sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || warn "GRUB restore failed"
  log "GRUB restored to default"

  # Restore Catppuccin GNOME theme
  info "Restoring Catppuccin GNOME theme..."
  gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-blue-standard+default' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface font-name 'JetBrains Mono 11' 2>/dev/null || true
  log "GNOME theme restored"

  # Remove cyberpunk wallpaper
  rm -f ~/Pictures/wallpapers/cyberforge.png

  log "CyberRice fully undone ✅"
}

# ── PHASE 2: Install dependencies ───────────────────────────
install_deps() {
  banner "Installing AllBlue Dependencies"

  # Hyprland and wayland stack
  info "Installing Hyprland stack..."
  sudo pacman -S --noconfirm --needed \
    hyprland \
    waybar \
    wofi \
    dunst \
    kitty \
    wezterm \
    rofi-wayland \
    swappy \
    grim \
    slurp \
    wl-clipboard \
    swww \
    hyprpaper \
    xdg-desktop-portal-hyprland \
    polkit-gnome \
    nwg-look \
    qt5-wayland \
    qt6-wayland \
    papirus-icon-theme \
    ttf-jetbrains-mono-nerd \
    ttf-nerd-fonts-symbols \
    noto-fonts-emoji \
    lm_sensors \
    htop \
    cava \
    brightnessctl \
    playerctl \
    pamixer \
    pavucontrol \
    blueman \
    networkmanager-applet 2>/dev/null || warn "Some packages failed"

  # AUR packages
  info "Installing AUR packages..."
  for pkg in \
    hyprshot \
    wlogout \
    swaylock-effects \
    grimblast-git; do
    yay -S --noconfirm "$pkg" 2>/dev/null || warn "AUR skipped: $pkg"
  done

  log "Dependencies installed"
}

# ── PHASE 3: Clone dotfiles ──────────────────────────────────
clone_dotfiles() {
  banner "Cloning AllBlue Dotfiles"

  DOTFILES_DIR="$HOME/.dotfiles-allblue"

  if [[ -d "$DOTFILES_DIR" ]]; then
    info "Dotfiles already cloned — pulling latest..."
    git -C "$DOTFILES_DIR" pull 2>/dev/null || true
  else
    git clone https://github.com/Youngermaster/Arch-dotfiles "$DOTFILES_DIR" --depth 1
  fi

  ALLBLUE="$DOTFILES_DIR/AllBlue"
  log "Dotfiles ready at $DOTFILES_DIR"
  echo "$ALLBLUE"
}

# ── PHASE 4: Apply AllBlue configs ───────────────────────────
apply_configs() {
  banner "Applying AllBlue Configs"

  DOTFILES_DIR="$HOME/.dotfiles-allblue"
  ALLBLUE="$DOTFILES_DIR/AllBlue"

  # Backup existing configs
  info "Backing up existing configs..."
  BACKUP="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$BACKUP"
  for dir in hypr waybar kitty rofi dunst cava wezterm; do
    [[ -d "$HOME/.config/$dir" ]] && cp -r "$HOME/.config/$dir" "$BACKUP/" && \
      info "Backed up: ~/.config/$dir"
  done
  log "Backup saved to $BACKUP"

  # Apply configs
  mkdir -p "$HOME/.config"

  # Hyprland
  if [[ -d "$ALLBLUE/hypr" ]]; then
    rm -rf ~/.config/hypr
    cp -r "$ALLBLUE/hypr" ~/.config/hypr
    log "Hyprland config applied"
  fi

  # Waybar
  if [[ -d "$ALLBLUE/waybar" ]]; then
    rm -rf ~/.config/waybar
    cp -r "$ALLBLUE/waybar" ~/.config/waybar
    log "Waybar config applied"
  fi

  # Kitty
  if [[ -d "$ALLBLUE/kitty" ]]; then
    rm -rf ~/.config/kitty
    cp -r "$ALLBLUE/kitty" ~/.config/kitty
    log "Kitty config applied"
  fi

  # Rofi
  if [[ -d "$ALLBLUE/rofi" ]]; then
    rm -rf ~/.config/rofi
    cp -r "$ALLBLUE/rofi" ~/.config/rofi
    log "Rofi config applied"
  fi

  # Dunst
  if [[ -d "$ALLBLUE/dunst" ]]; then
    rm -rf ~/.config/dunst
    cp -r "$ALLBLUE/dunst" ~/.config/dunst
    log "Dunst config applied"
  fi

  # Cava
  if [[ -d "$ALLBLUE/cava" ]]; then
    rm -rf ~/.config/cava
    cp -r "$ALLBLUE/cava" ~/.config/cava
    log "Cava config applied"
  fi

  # Wezterm
  if [[ -d "$ALLBLUE/wezterm" ]]; then
    rm -rf ~/.config/wezterm
    cp -r "$ALLBLUE/wezterm" ~/.config/wezterm
    log "Wezterm config applied"
  fi

  # Htop
  if [[ -d "$ALLBLUE/htop" ]]; then
    mkdir -p ~/.config/htop
    cp -r "$ALLBLUE/htop/"* ~/.config/htop/ 2>/dev/null || true
    log "Htop config applied"
  fi

  # Swappy
  if [[ -d "$ALLBLUE/swappy" ]]; then
    mkdir -p ~/.config/swappy
    cp -r "$ALLBLUE/swappy/"* ~/.config/swappy/ 2>/dev/null || true
    log "Swappy config applied"
  fi

  # LunarVim
  if [[ -d "$ALLBLUE/lvim" ]]; then
    mkdir -p ~/.config/lvim
    cp -r "$ALLBLUE/lvim/"* ~/.config/lvim/ 2>/dev/null || true
    log "LunarVim config applied"
  fi

  # .zshrc
  if [[ -f "$ALLBLUE/.zshrc" ]]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.devforge.bak" 2>/dev/null || true
    cp "$ALLBLUE/.zshrc" "$HOME/.zshrc"
    log ".zshrc applied (DevForge backup at ~/.zshrc.devforge.bak)"
  fi

  # Wallpapers
  if [[ -d "$ALLBLUE/wallpapers" ]]; then
    mkdir -p ~/Pictures/wallpapers
    cp -r "$ALLBLUE/wallpapers/"* ~/Pictures/wallpapers/ 2>/dev/null || true
    log "Wallpapers copied"
  fi

  log "All AllBlue configs applied ✅"
}

# ── PHASE 5: Make scripts executable ─────────────────────────
fix_permissions() {
  banner "Fixing Permissions"

  ALLBLUE="$HOME/.dotfiles-allblue/AllBlue"

  # Make all scripts executable
  find "$ALLBLUE/scripts" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
  find "$HOME/.config/hypr" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
  find "$HOME/.config/waybar" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

  # Copy scripts to local bin
  mkdir -p ~/.local/bin
  find "$ALLBLUE/scripts" -type f -name "*.sh" \
    -exec cp {} ~/.local/bin/ \; 2>/dev/null || true

  log "Permissions fixed"
}

# ── PHASE 6: Hyprland autostart setup ───────────────────────
setup_hyprland_session() {
  banner "Hyprland Session Setup"

  # Create Hyprland desktop entry if missing
  sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null << 'HYPRDESKTOP' 2>/dev/null || true
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
HYPRDESKTOP

  # Add Hyprland PATH additions to .zshrc
  cat >> "$HOME/.zshrc" << 'ZSHAPPEND'

# AllBlue Hyprland additions
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_CURRENT_DESKTOP=Hyprland
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export ELECTRON_OZONE_PLATFORM_HINT=wayland
ZSHAPPEND

  log "Hyprland session configured"
}

# ── PHASE 7: Keep DevForge Flutter/Dev paths ─────────────────
preserve_devforge_paths() {
  banner "Preserving DevForge Dev Paths"

  # The AllBlue .zshrc may not have Flutter/Android paths
  # Add them back to make sure they persist
  cat >> "$HOME/.zshrc" << 'DEVPATHS'

# ── DevForge Dev Paths (preserved) ──────────────────────────
export PATH="$HOME/development/flutter/bin:$PATH"
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/emulator"
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk"
export CHROME_EXECUTABLE="/usr/bin/chromium"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"

# Flutter aliases (preserved from DevForge)
alias fl='flutter'
alias flr='flutter run'
alias flb='flutter build'
alias flt='flutter test'
alias flc='flutter clean'
alias flpg='flutter pub get'
alias fldoc='flutter doctor -v'
alias flandroid='flutter run -d android'
DEVPATHS

  log "DevForge dev paths preserved in .zshrc"
}

# ── Summary ──────────────────────────────────────────────────
print_summary() {
  echo ""
  echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║  🎨 Rice Switch Complete!                      ║${RESET}"
  echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "  ${GREEN}✦ CyberRice:${RESET}    Fully undone"
  echo -e "  ${GREEN}✦ AllBlue rice:${RESET} Installed"
  echo -e "  ${GREEN}✦ Hyprland:${RESET}     Ready"
  echo -e "  ${GREEN}✦ Waybar:${RESET}       Configured"
  echo -e "  ${GREEN}✦ Kitty:${RESET}        AllBlue theme"
  echo -e "  ${GREEN}✦ Rofi:${RESET}         AllBlue launcher"
  echo -e "  ${GREEN}✦ Cava:${RESET}         AllBlue colors"
  echo -e "  ${GREEN}✦ Flutter paths:${RESET} Preserved"
  echo ""
  echo -e "  ${YELLOW}⚡ Next steps:${RESET}"
  echo -e "  1. Log out of GNOME"
  echo -e "  2. On login screen → click gear icon ⚙️"
  echo -e "  3. Select ${CYAN}Hyprland${RESET} as session"
  echo -e "  4. Log in — enjoy AllBlue rice! 🎉"
  echo ""
  echo -e "  ${YELLOW}⚡ To switch back to GNOME anytime:${RESET}"
  echo -e "  Log out → select GNOME → log in"
  echo ""
  echo -e "  ${YELLOW}⚡ Backup of old configs saved at:${RESET}"
  ls ~/.config-backup-* -d 2>/dev/null | tail -1 || true
  echo ""
}

# ── Main ─────────────────────────────────────────────────────
main() {
  banner "Rice Switcher — CyberRice → AllBlue"
  undo_cyberrice
  install_deps
  clone_dotfiles
  apply_configs
  fix_permissions
  setup_hyprland_session
  preserve_devforge_paths
  print_summary
}

main "$@"
