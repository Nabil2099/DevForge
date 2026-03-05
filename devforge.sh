#!/usr/bin/env bash
# ============================================================
#  DevForge OS — Arch Edition 🏹
#  ALL-IN-ONE SINGLE FILE — no subfolders needed
#  Flutter / Android Developer Linux
#  Usage: sudo ./devforge.sh
# ============================================================

set -uo pipefail
# Note: -e removed intentionally so script never stops on single failures

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BOLD='\033[1m'; RESET='\033[0m'

LOG_FILE="/var/log/devforge-arch.log"
USERNAME="${SUDO_USER:-$USER}"
HOME_DIR="/home/$USERNAME"

log()    { echo -e "${GREEN}[✔]${RESET} $*" | tee -a "$LOG_FILE"; }
warn()   { echo -e "${YELLOW}[!]${RESET} $*" | tee -a "$LOG_FILE"; }
error()  { echo -e "${RED}[✘]${RESET} $*" | tee -a "$LOG_FILE"; exit 1; }
info()   { echo -e "${CYAN}[→]${RESET} $*" | tee -a "$LOG_FILE"; }
banner() {
  echo -e "\n${BOLD}${MAGENTA}┌──────────────────────────────────────────────┐${RESET}"
  echo -e "${BOLD}${MAGENTA}│  $*$(printf '%*s' $((44 - ${#*})) '')│${RESET}"
  echo -e "${BOLD}${MAGENTA}└──────────────────────────────────────────────┘${RESET}\n"
}

# ── Preflight ───────────────────────────────────────────────
preflight() {
  banner "DevForge Arch — Preflight"
  [[ $EUID -eq 0 ]] || error "Run with sudo: sudo ./devforge.sh"
  command -v pacman &>/dev/null || error "Arch Linux required"
  ping -c1 8.8.8.8 &>/dev/null || error "No internet connection"
  touch "$LOG_FILE" 2>/dev/null || mkdir -p "$(dirname $LOG_FILE)" && touch "$LOG_FILE"
  log "Building for user: $USERNAME"
}

# ── Pacman setup ────────────────────────────────────────────
setup_pacman() {
  banner "Pacman Setup & System Update"
  sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
  sed -i 's/^#Color/Color/' /etc/pacman.conf
  sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
  pacman -S --noconfirm --needed reflector
  reflector --country Egypt,Germany,France --latest 10 --sort rate \
    --save /etc/pacman.d/mirrorlist 2>/dev/null || warn "Reflector failed, using defaults"
  pacman -Syu --noconfirm
  log "System updated"
}

# ── yay AUR helper ──────────────────────────────────────────
install_yay() {
  banner "AUR Helper: yay"
  if command -v yay &>/dev/null; then log "yay already installed"; return; fi
  pacman -S --noconfirm --needed git base-devel
  sudo -u "$USERNAME" bash -c '
    cd /tmp && rm -rf yay-bin
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin && makepkg -si --noconfirm
  '
  log "yay installed"
}

# ── GNOME Desktop ───────────────────────────────────────────
install_gnome() {
  banner "GNOME Desktop"
  pacman -S --noconfirm --needed \
    gnome gnome-tweaks gnome-shell-extensions \
    gdm xorg-server \
    networkmanager network-manager-applet \
    bluez bluez-utils \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
    noto-fonts noto-fonts-cjk noto-fonts-emoji \
    ttf-jetbrains-mono ttf-fira-code ttf-cascadia-code ttf-hack-nerd
  systemctl enable gdm
  systemctl enable NetworkManager
  systemctl enable bluetooth
  for pkg in \
    gnome-shell-extension-blur-my-shell \
    papirus-icon-theme \
    catppuccin-gtk-theme-mocha \
    bibata-cursor-theme; do
    sudo -u "$USERNAME" yay -S --noconfirm "$pkg" 2>/dev/null || warn "Skipping AUR: $pkg"
  done
  log "GNOME installed"
}

# ── Languages ───────────────────────────────────────────────
install_languages() {
  banner "Languages & Runtimes"
  pacman -S --noconfirm --needed \
    python python-pip python-pipx python-virtualenv \
    nodejs npm go ruby ruby-bundler \
    php composer jdk17-openjdk kotlin

  info "Python tools..."
  sudo -u "$USERNAME" pip install --user --quiet --break-system-packages \
    uv black ruff mypy pytest httpx rich 2>/dev/null || warn "Some Python tools failed — skipping"

  info "Node.js tools..."
  npm install -g pnpm yarn typescript ts-node nodemon prettier eslint 2>/dev/null || warn "Some Node tools failed — skipping"

  info "Rust..."
  sudo -u "$USERNAME" bash -c \
    'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --quiet' \
    2>/dev/null || warn "Rust install failed — run manually later"

  log "Languages installed"
}

# ── Flutter SDK ─────────────────────────────────────────────
install_flutter() {
  banner "Flutter SDK"
  pacman -S --noconfirm --needed \
    clang cmake ninja gtk3 glib2 \
    curl unzip zip xz lib32-glibc lib32-gcc-libs

  sudo -u "$USERNAME" bash << FLUTTERINSTALL
    mkdir -p "$HOME_DIR/development"
    if [[ ! -d "$HOME_DIR/development/flutter" ]]; then
      git clone https://github.com/flutter/flutter.git \
        -b stable "$HOME_DIR/development/flutter" --depth 1
    fi
    export PATH="\$HOME/development/flutter/bin:\$PATH"
    flutter precache --quiet 2>/dev/null || true
    flutter config --no-analytics
    dart --disable-analytics
FLUTTERINSTALL
  log "Flutter installed at ~/development/flutter"
}

# ── Android Studio & SDK ────────────────────────────────────
install_android() {
  banner "Android Studio & SDK"

  # Install packages one by one so one failure doesn't stop everything
  for pkg in jdk17-openjdk lib32-gcc-libs lib32-glibc; do
    pacman -S --noconfirm --needed "$pkg" 2>/dev/null || warn "Skipping $pkg — not found"
  done

  usermod -aG kvm "$USERNAME" 2>/dev/null || true
  modprobe kvm_intel 2>/dev/null || modprobe kvm_amd 2>/dev/null || warn "KVM needs BIOS enable"

  info "Installing Android Studio from AUR..."
  sudo -u "$USERNAME" yay -S --noconfirm android-studio 2>/dev/null || warn "Android Studio AUR failed — install manually later"

  info "Installing Android SDK..."
  ANDROID_SDK="$HOME_DIR/Android/Sdk"
  sudo -u "$USERNAME" bash << ANDROIDSDK
    mkdir -p "$ANDROID_SDK/cmdline-tools"
    wget -q "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
      -O /tmp/cmdtools.zip
    unzip -q /tmp/cmdtools.zip -d /tmp/cmdtools
    mv /tmp/cmdtools/cmdline-tools "$ANDROID_SDK/cmdline-tools/latest"
    rm -f /tmp/cmdtools.zip
    export ANDROID_HOME="$ANDROID_SDK"
    export PATH="\$PATH:$ANDROID_SDK/cmdline-tools/latest/bin"
    yes | sdkmanager --licenses > /dev/null 2>&1 || true
    sdkmanager --quiet \
      "platform-tools" \
      "build-tools;34.0.0" \
      "platforms;android-34" \
      "platforms;android-33" \
      "emulator"
ANDROIDSDK
  log "Android Studio & SDK installed"
}

# ── Editors ─────────────────────────────────────────────────
install_editors() {
  banner "Editors"
  pacman -S --noconfirm --needed neovim vim
  sudo -u "$USERNAME" yay -S --noconfirm visual-studio-code-bin
  log "Editors installed"
}

# ── CLI Tools ───────────────────────────────────────────────
install_cli_tools() {
  banner "CLI Power Tools"
  pacman -S --noconfirm --needed \
    zsh tmux fzf ripgrep fd bat eza htop btop \
    jq yq tree ncdu shellcheck \
    neofetch figlet direnv \
    net-tools nmap openssh \
    zoxide git-delta lazygit

  info "Starship prompt..."
  sudo -u "$USERNAME" bash -c \
    'curl -sS https://starship.rs/install.sh | sh -s -- -y'

  log "CLI tools installed"
}

# ── DevOps ──────────────────────────────────────────────────
install_devops() {
  banner "DevOps & Cloud"
  pacman -S --noconfirm --needed docker docker-compose kubectl helm
  systemctl enable docker
  usermod -aG docker "$USERNAME"
  sudo -u "$USERNAME" yay -S --noconfirm terraform-bin aws-cli-v2 2>/dev/null || warn "Terraform/AWS failed"
  log "DevOps tools installed"
}

# ── Databases ───────────────────────────────────────────────
install_databases() {
  banner "Databases"
  pacman -S --noconfirm --needed \
    postgresql mariadb redis sqlite
  sudo -u postgres initdb -D /var/lib/postgres/data 2>/dev/null || true
  systemctl enable postgresql redis
  sudo -u "$USERNAME" yay -S --noconfirm dbeaver 2>/dev/null || warn "DBeaver AUR failed"
  log "Databases installed"
}

# ── Write all config files inline ───────────────────────────
write_configs() {
  banner "Writing Config Files"

  # ── .zshrc ──────────────────────────────────────────────
  cat > "$HOME_DIR/.zshrc" << 'ZSHRC'
export ZSH="$HOME/.oh-my-zsh"
export TERM="xterm-256color"
ZSH_THEME=""
plugins=(git docker docker-compose kubectl python node rust golang
         flutter fzf zsh-autosuggestions zsh-syntax-highlighting
         fzf-tab colored-man-pages command-not-found archlinux)
source $ZSH/oh-my-zsh.sh
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
export PATH="$HOME/development/flutter/bin:$PATH"
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/emulator"
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk"
export GOPATH="$HOME/go"
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="bat"
export CHROME_EXECUTABLE="/usr/bin/chromium"

# Better defaults
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --icons --level=2'
alias cat='bat --style=auto'
alias grep='rg'
alias find='fd'
alias vim='nvim'
alias vi='nvim'
alias top='btop'
alias cd='z'

# Flutter
alias fl='flutter'
alias flr='flutter run'
alias flb='flutter build'
alias flt='flutter test'
alias flc='flutter clean'
alias flpg='flutter pub get'
alias flpu='flutter pub upgrade'
alias fldoc='flutter doctor -v'
alias flandroid='flutter run -d android'
alias flweb='flutter run -d chrome'
alias fllinux='flutter run -d linux'
flnew() {
  [[ -z "$1" ]] && echo "Usage: flnew <app_name>" && return 1
  flutter create --org "${2:-com.devforge}" --platforms android,ios,linux,web "$1"
  cd "$1" && code .
}
avd-start() { emulator -avd "${1:-Pixel_7_API34}" -no-snapshot-save &; }

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias glog='git log --oneline --graph --decorate --all'
alias lg='lazygit'

# Docker
alias dk='docker'
alias dkc='docker compose'
alias dkps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dkclean='docker system prune -af --volumes'

# Python
alias py='python3'
alias venv='python3 -m venv .venv && source .venv/bin/activate'
alias activate='source .venv/bin/activate'

# Node
alias ni='npm install'
alias nr='npm run'
alias pn='pnpm'

# Arch
alias pac='sudo pacman -S'
alias pacu='sudo pacman -Syu'
alias pacr='sudo pacman -Rs'
alias yays='yay -S'
alias yayu='yay -Syu'

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
HISTSIZE=100000; SAVEHIST=100000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

if [[ -o interactive ]]; then
  echo ""
  echo "  🏹 DevForge OS Arch Edition — $(date '+%A, %B %d %Y')"
  echo "  Flutter $(flutter --version 2>/dev/null | awk 'NR==1{print $2}') | $(python3 --version) | $(node --version | sed 's/v/Node /')"
  echo ""
fi
ZSHRC

  # ── .tmux.conf ──────────────────────────────────────────
  cat > "$HOME_DIR/.tmux.conf" << 'TMUXCONF'
unbind C-b
set -g prefix C-a
bind C-a send-prefix
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"
set -g history-limit 50000
set -g mouse on
set -sg escape-time 0
set -g base-index 1
setw -g pane-base-index 1
set -g default-shell /bin/zsh
bind r source-file ~/.tmux.conf \; display "Reloaded!"
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"
unbind '"'; unbind %
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5
setw -g mode-keys vi
bind Enter copy-mode
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-selection-and-cancel

# Flutter layout
bind F new-window -n "flutter" \;\
  split-window -h -p 40 \;\
  split-window -v -p 40 \;\
  select-pane -t 1 \;\
  send-keys "nvim ." Enter

# Colors - Catppuccin Mocha
set -g status-style "bg=#1e1e2e fg=#cdd6f4"
set -g status-left "#[fg=#cba6f7,bold] 🏹 DevForge #[fg=#cdd6f4]│ "
set -g status-right "#[fg=#a6e3a1] %H:%M #[fg=#cdd6f4]│#[fg=#89b4fa] #H "
setw -g window-status-current-format "#[fg=#cba6f7,bold] #I:#W "
set -g pane-active-border-style "fg=#cba6f7"
set -g pane-border-style "fg=#313244"
TMUXCONF

  # ── .gitconfig ──────────────────────────────────────────
  cat > "$HOME_DIR/.gitconfig" << 'GITCONF'
[core]
  editor = nvim
  pager = delta
  autocrlf = input
[interactive]
  diffFilter = delta --color-only
[delta]
  navigate = true
  line-numbers = true
  side-by-side = true
  syntax-theme = Dracula
[merge]
  conflictstyle = diff3
[alias]
  st  = status
  lg  = log --oneline --graph --decorate --all
  undo = reset --soft HEAD~1
  visual = !lazygit
[pull]
  rebase = false
[push]
  default = current
  autoSetupRemote = true
[init]
  defaultBranch = main
[color]
  ui = auto
[rerere]
  enabled = true
GITCONF

  # ── starship.toml ────────────────────────────────────────
  mkdir -p "$HOME_DIR/.config"
  cat > "$HOME_DIR/.config/starship.toml" << 'STARSHIP'
format = """
[╭─](bold purple)\
$directory\
$git_branch\
$git_status\
$dart\
$python\
$nodejs\
$rust\
$golang\
$java\
$docker_context\
$cmd_duration\
$line_break\
[╰─](bold purple)$character"""

[character]
success_symbol = "[❯](bold green)"
error_symbol   = "[❯](bold red)"

[directory]
style = "bold cyan"
truncation_length = 4
truncate_to_repo = true

[git_branch]
format = "on [$symbol$branch]($style) "
symbol = " "
style  = "bold purple"

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style  = "bold red"

[dart]
symbol = "🎯 "
style  = "bold blue"

[custom.flutter]
command = "flutter --version 2>/dev/null | awk 'NR==1{print $2}'"
when    = "test -f pubspec.yaml"
symbol  = "🐦 "
style   = "bold #54c5f8"
format  = "via [$symbol($output )]($style)"

[python]
symbol = " "
style  = "bold yellow"

[nodejs]
symbol = " "
style  = "bold green"

[rust]
symbol = " "
style  = "bold red"

[golang]
symbol = " "
style  = "bold cyan"

[java]
symbol = " "
style  = "bold red"

[cmd_duration]
min_time = 2000
format   = "took [$duration]($style) "
style    = "bold yellow"
STARSHIP

  chown -R "$USERNAME:$USERNAME" \
    "$HOME_DIR/.zshrc" \
    "$HOME_DIR/.tmux.conf" \
    "$HOME_DIR/.gitconfig" \
    "$HOME_DIR/.config/starship.toml"

  log "Config files written"
}

# ── Shell setup ─────────────────────────────────────────────
setup_shell() {
  banner "Shell Setup"
  chsh -s "$(which zsh)" "$USERNAME"

  sudo -u "$USERNAME" bash -c \
    'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &>/dev/null'

  ZSH_CUSTOM="$HOME_DIR/.oh-my-zsh/custom"
  sudo -u "$USERNAME" bash -c "
    git clone -q https://github.com/zsh-users/zsh-autosuggestions '$ZSH_CUSTOM/plugins/zsh-autosuggestions'
    git clone -q https://github.com/zsh-users/zsh-syntax-highlighting '$ZSH_CUSTOM/plugins/zsh-syntax-highlighting'
    git clone -q https://github.com/Aloxaf/fzf-tab '$ZSH_CUSTOM/plugins/fzf-tab'
  "
  log "Shell configured"
}

# ── GNOME settings ───────────────────────────────────────────
configure_gnome() {
  banner "GNOME Configuration"
  sudo -u "$USERNAME" bash << 'GNOMECONF'
    gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-blue-standard+default' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
    gsettings set org.gnome.desktop.interface font-name 'JetBrains Mono 11'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 12'
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface clock-show-weekday true
    gsettings set org.gnome.desktop.interface show-battery-percentage true
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
    gsettings set org.gnome.mutter dynamic-workspaces false
    gsettings set org.gnome.desktop.wm.preferences num-workspaces 6
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4200
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
    gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']"
GNOMECONF
  log "GNOME configured"
}

# ── VS Code extensions ───────────────────────────────────────
install_vscode_extensions() {
  banner "VS Code Extensions"
  EXTENSIONS=(
    "Dart-Code.flutter" "Dart-Code.dart-code"
    "Nash.awesome-flutter-snippets" "alexisvt.flutter-snippets"
    "usernamehw.errorlens" "ms-python.python"
    "ms-python.pylance" "ms-python.black-formatter"
    "golang.go" "rust-lang.rust-analyzer"
    "vscjava.vscode-java-pack" "fwcd.kotlin"
    "esbenp.prettier-vscode" "dbaeumer.vscode-eslint"
    "eamodio.gitlens" "mhutchie.git-graph"
    "ms-azuretools.vscode-docker"
    "ms-kubernetes-tools.vscode-kubernetes-tools"
    "humao.rest-client" "mtxr.sqltools"
    "github.copilot" "github.copilot-chat"
    "catppuccin.catppuccin-vsc" "catppuccin.catppuccin-vsc-icons"
    "pkief.material-icon-theme" "vscodevim.vim"
    "aaron-bond.better-comments" "oderwat.indent-rainbow"
    "ms-vscode-remote.vscode-remote-extensionpack"
  )
  for ext in "${EXTENSIONS[@]}"; do
    sudo -u "$USERNAME" code --install-extension "$ext" --force &>/dev/null && \
      echo "  ✔ $ext" || echo "  ✘ $ext"
  done
  log "VS Code extensions installed"
}

# ── Flutter workspace ────────────────────────────────────────
setup_flutter_workspace() {
  banner "Flutter Workspace"
  sudo -u "$USERNAME" bash << 'WORKSPACE'
    mkdir -p "$HOME/workspace/flutter"
    export PATH="$HOME/development/flutter/bin:$PATH"
    cd "$HOME/workspace/flutter"
    flutter create --org com.devforge --platforms android,linux,web devforge_starter 2>/dev/null || true
WORKSPACE
  log "Flutter workspace ready"
}

# ── GRUB — detect Windows ────────────────────────────────────
fix_grub() {
  banner "GRUB — Detecting Windows"
  pacman -S --noconfirm --needed os-prober
  sed -i 's/^#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/' /etc/default/grub
  echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
  grub-mkconfig -o /boot/grub/grub.cfg
  log "GRUB updated — Windows should appear on next boot"
}

# ── Branding ─────────────────────────────────────────────────
apply_branding() {
  banner "DevForge Branding"
  cat > /etc/motd << 'MOTD'

  ██████╗ ███████╗██╗   ██╗███████╗ ██████╗ ██████╗  ██████╗ ███████╗
  ██╔══██╗██╔════╝██║   ██║██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝
  ██║  ██║█████╗  ██║   ██║█████╗  ██║   ██║██████╔╝██║  ███╗█████╗
  ██║  ██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝
  ██████╔╝███████╗ ╚████╔╝ ██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗
  ╚═════╝ ╚══════╝  ╚═══╝  ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
              Arch Edition 🏹 — Flutter Developer's Linux
MOTD
  log "Branding applied"
}

# ── Cleanup ──────────────────────────────────────────────────
cleanup() {
  banner "Cleanup"
  pacman -Scc --noconfirm
  sudo -u "$USERNAME" yay -Sc --noconfirm 2>/dev/null || true
  log "Cleanup done"
}

# ── Summary ──────────────────────────────────────────────────
print_summary() {
  echo ""
  echo -e "${BOLD}${MAGENTA}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${MAGENTA}║   DevForge OS Arch Edition — Done! 🚀 🏹     ║${RESET}"
  echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "  ${CYAN}✦ Desktop:${RESET}   GNOME + Catppuccin Mocha"
  echo -e "  ${CYAN}✦ Flutter:${RESET}   ~/development/flutter"
  echo -e "  ${CYAN}✦ Android:${RESET}   Android Studio + SDK 34"
  echo -e "  ${CYAN}✦ Languages:${RESET} Python, Node, Go, Rust, Java, Kotlin, Ruby, PHP"
  echo -e "  ${CYAN}✦ Editors:${RESET}   VS Code, Neovim, Vim"
  echo -e "  ${CYAN}✦ Shell:${RESET}     zsh + Oh My Zsh + Starship + tmux"
  echo ""
  echo -e "  ${YELLOW}⚡ REBOOT now:  sudo reboot${RESET}"
  echo -e "  ${YELLOW}⚡ After reboot run: flutter doctor -v${RESET}"
  echo -e "  ${YELLOW}⚡ Accept licenses: flutter doctor --android-licenses${RESET}"
  echo ""
}

# ── Main ─────────────────────────────────────────────────────
main() {
  preflight
  setup_pacman
  install_yay
  install_gnome
  install_languages
  install_flutter
  install_android
  install_editors
  install_cli_tools
  install_devops
  install_databases
  write_configs
  setup_shell
  configure_gnome
  install_vscode_extensions
  setup_flutter_workspace
  fix_grub
  apply_branding
  cleanup
  print_summary
}

main "$@"
