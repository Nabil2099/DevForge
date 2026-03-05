#!/usr/bin/env bash
# ============================================================
#  DevForge OS — SmartShell ⚡
#  Makes your terminal intelligent:
#  - Fish-style command autosuggestions
#  - File/folder tab completions with preview
#  - Fuzzy command history search
#  - Syntax highlighting as you type
#  - Smart directory jumping
#  - Command corrections
#  Run as normal user: ./smartshell.sh
# ============================================================

set -uo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'; BOLD='\033[1m'; RESET='\033[0m'

log()    { echo -e "${GREEN}[✔]${RESET} $*"; }
warn()   { echo -e "${YELLOW}[!]${RESET} $*"; }
info()   { echo -e "${CYAN}[→]${RESET} $*"; }
banner() {
  echo -e "\n${BOLD}${MAGENTA}╔═══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${MAGENTA}║  ⚡ $*$(printf '%*s' $((43 - ${#*})) '')║${RESET}"
  echo -e "${BOLD}${MAGENTA}╚═══════════════════════════════════════════════╝${RESET}\n"
}

[[ $EUID -eq 0 ]] && echo "Run as normal user, NOT root!" && exit 1

# ── Install packages ─────────────────────────────────────────
install_packages() {
  banner "Installing SmartShell Packages"

  sudo pacman -S --noconfirm --needed \
    zsh \
    fzf \
    zoxide \
    thefuck \
    mc \
    eza \
    bat \
    fd \
    ripgrep \
    tldr \
    navi 2>/dev/null || warn "Some packages failed"

  # AUR packages
  for pkg in \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    zsh-history-substring-search \
    zsh-autocomplete \
    fzf-tab-git; do
    yay -S --noconfirm "$pkg" 2>/dev/null || warn "AUR skipped: $pkg"
  done

  log "Packages installed"
}

# ── Oh My Zsh plugins (if not already installed) ─────────────
setup_omz_plugins() {
  banner "Oh My Zsh Smart Plugins"

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # zsh-autosuggestions (ghost text suggestions)
  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone -q https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    log "zsh-autosuggestions installed"
  else
    log "zsh-autosuggestions already present"
  fi

  # zsh-syntax-highlighting (colors as you type)
  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone -q https://github.com/zsh-users/zsh-syntax-highlighting \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    log "zsh-syntax-highlighting installed"
  else
    log "zsh-syntax-highlighting already present"
  fi

  # zsh-history-substring-search (arrow key history search)
  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]]; then
    git clone -q https://github.com/zsh-users/zsh-history-substring-search \
      "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
    log "zsh-history-substring-search installed"
  else
    log "zsh-history-substring-search already present"
  fi

  # fzf-tab (replace default tab with fzf)
  if [[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ]]; then
    git clone -q https://github.com/Aloxaf/fzf-tab \
      "$ZSH_CUSTOM/plugins/fzf-tab"
    log "fzf-tab installed"
  else
    log "fzf-tab already present"
  fi

  # you-should-use (reminds you of aliases)
  if [[ ! -d "$ZSH_CUSTOM/plugins/you-should-use" ]]; then
    git clone -q https://github.com/MichaelAquilina/zsh-you-should-use \
      "$ZSH_CUSTOM/plugins/you-should-use"
    log "you-should-use installed"
  else
    log "you-should-use already present"
  fi
}

# ── Write smart .zshrc additions ────────────────────────────
write_smartshell_config() {
  banner "Writing SmartShell Config"

  # Backup existing .zshrc
  cp "$HOME/.zshrc" "$HOME/.zshrc.pre-smartshell.bak" 2>/dev/null || true
  log "Backed up .zshrc to .zshrc.pre-smartshell.bak"

  # Append smartshell config block
  cat >> "$HOME/.zshrc" << 'SMARTSHELL'

# ============================================================
#  SmartShell ⚡ — Intelligent Terminal
# ============================================================

# ── Plugins ──────────────────────────────────────────────────
# Add these to your plugins=() list in .zshrc if not already there:
# zsh-autosuggestions zsh-syntax-highlighting
# zsh-history-substring-search fzf-tab you-should-use

# Source plugins directly (works even without OMZ plugin list)
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[[ -f "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
  source "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[[ -f "$ZSH_CUSTOM/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh" ]] && \
  source "$ZSH_CUSTOM/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"
[[ -f "$ZSH_CUSTOM/plugins/fzf-tab/fzf-tab.plugin.zsh" ]] && \
  source "$ZSH_CUSTOM/plugins/fzf-tab/fzf-tab.plugin.zsh"
[[ -f "$ZSH_CUSTOM/plugins/you-should-use/you-should-use.plugin.zsh" ]] && \
  source "$ZSH_CUSTOM/plugins/you-should-use/you-should-use.plugin.zsh"

# ── Autosuggestions ──────────────────────────────────────────
# Ghost text appears as you type — press → or End to accept
ZSH_AUTOSUGGEST_STRATEGY=(history completion)     # suggest from history first, then completions
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20                # don't suggest for very long commands
ZSH_AUTOSUGGEST_USE_ASYNC=true                    # non-blocking suggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c7086"      # Catppuccin overlay color
ZSH_AUTOSUGGEST_HISTORY_IGNORE="cd *"             # don't suggest cd paths from history

# Keybindings for autosuggestions
bindkey '→'    autosuggest-accept          # right arrow → accept full suggestion
bindkey '^ '   autosuggest-accept          # Ctrl+Space → accept full suggestion
bindkey '^F'   autosuggest-accept          # Ctrl+F → accept full suggestion
bindkey '^]'   autosuggest-accept-suggested-word  # accept one word at a time

# ── Syntax highlighting colors ───────────────────────────────
# Colors commands as you type: green=valid, red=invalid
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#a6e3a1,bold'           # valid command → green
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f38ba8,bold'     # unknown command → red
ZSH_HIGHLIGHT_STYLES[alias]='fg=#89b4fa,bold'             # alias → blue
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#cba6f7,bold'           # builtin → purple
ZSH_HIGHLIGHT_STYLES[function]='fg=#89dceb'               # function → sky
ZSH_HIGHLIGHT_STYLES[path]='fg=#f9e2af,underline'         # file path → yellow underlined
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#a6e3a1' # 'string' → green
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#a6e3a1' # "string" → green
ZSH_HIGHLIGHT_STYLES[comment]='fg=#585b70'                # # comment → dim
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#fab387'               # *.txt → peach
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#f9e2af'            # > >> | → yellow

# ── History substring search ────────────────────────────────
# Type part of a command → press Up/Down to search matching history
bindkey '^[[A' history-substring-search-up    # Up arrow
bindkey '^[[B' history-substring-search-down  # Down arrow
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=#a6e3a1,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='fg=#f38ba8,bold'
HISTORY_SUBSTRING_SEARCH_FUZZY=true

# ── FZF Tab completions ──────────────────────────────────────
# Press Tab → get a fuzzy searchable list with file preview
zstyle ':fzf-tab:complete:cd:*' fzf-preview \
  'eza --tree --icons --color=always --level=2 $realpath 2>/dev/null || ls $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview \
  'bat --color=always --style=numbers $realpath 2>/dev/null || cat $realpath 2>/dev/null || eza --tree $realpath'
zstyle ':fzf-tab:complete:cat:*' fzf-preview \
  'bat --color=always --style=numbers $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:nvim:*' fzf-preview \
  'bat --color=always --style=numbers $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:kill:*' fzf-preview \
  'ps --pid=$word -o pid,user,comm,args --no-headers 2>/dev/null'
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
  'git diff $word 2>/dev/null | bat --color=always --language=diff'
zstyle ':fzf-tab:complete:*' fzf-flags \
  --height=60% --layout=reverse --border --info=inline \
  --color='bg:#1e1e2e,border:#89b4fa,prompt:#cba6f7,pointer:#f38ba8'

# ── Native zsh completions ───────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select                           # navigable menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'         # case insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"     # colored completions
zstyle ':completion:*:descriptions' format '[%d]'           # show group names
zstyle ':completion:*' group-name ''                        # group by category
zstyle ':completion:*:git-checkout:*' sort false            # keep git branch order
zstyle ':completion:*' file-sort modification               # sort files by date
zstyle ':completion:*:*:kill:*:processes' list-colors \
  '=(#b) #([0-9]#)*=0=01;31'                               # red PIDs in kill

# ── FZF smart keybindings ────────────────────────────────────
# Ctrl+R → fuzzy search command history
# Ctrl+T → fuzzy find file and insert path
# Alt+C  → fuzzy find directory and cd into it
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude .dart_tool --exclude build --exclude node_modules'
export FZF_DEFAULT_OPTS="
  --height=50%
  --layout=reverse
  --border=rounded
  --info=inline
  --prompt='⚡ '
  --pointer='→'
  --marker='✓'
  --color='bg:#1e1e2e,bg+:#313244,border:#89b4fa'
  --color='fg:#cdd6f4,fg+:#cdd6f4,hl:#f38ba8,hl+:#f38ba8'
  --color='prompt:#cba6f7,pointer:#f38ba8,marker:#a6e3a1,info:#6c7086'
  --preview-window=right:50%:wrap
"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers {} 2>/dev/null || cat {}'"
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window=down:3:wrap
  --bind 'ctrl-y:execute-silent(echo -n {2..} | xclip -sel clip)+abort'
"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="--preview 'eza --tree --icons --color=always --level=2 {}'"

# Load fzf keybindings
[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -f /usr/share/fzf/completion.zsh ]]   && source /usr/share/fzf/completion.zsh

# ── Zoxide smart cd ──────────────────────────────────────────
# Type 'z projectname' to jump to any folder you've visited before
# Type 'zi' to get a fuzzy interactive picker
eval "$(zoxide init zsh --cmd cd)" 2>/dev/null || eval "$(zoxide init zsh)"

# ── Thefuck — auto correct commands ─────────────────────────
# Type a wrong command → press Esc Esc → it corrects it automatically
eval "$(thefuck --alias)" 2>/dev/null || true
eval "$(thefuck --alias fix)" 2>/dev/null || true  # or just type 'fix'

# ── Smart history settings ───────────────────────────────────
HISTSIZE=200000
SAVEHIST=200000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_DUPS       # don't save duplicate commands
setopt HIST_IGNORE_SPACE      # don't save commands starting with space
setopt HIST_VERIFY            # show command before executing from history
setopt SHARE_HISTORY          # share history between all terminal sessions
setopt HIST_REDUCE_BLANKS     # remove extra blanks from history
setopt EXTENDED_HISTORY       # save timestamp with each command
setopt INC_APPEND_HISTORY     # add to history immediately, not on exit

# ── Smart directory options ──────────────────────────────────
setopt AUTO_CD                # type folder name to cd into it (no need for 'cd')
setopt AUTO_PUSHD             # push old dir onto stack on cd
setopt PUSHD_IGNORE_DUPS      # no duplicate dirs in stack
setopt CDABLE_VARS            # cd to named directories

# ── Useful completions shortcuts ─────────────────────────────
# flutter pub get → flpg  (remind you of alias)
export YSU_MESSAGE_POSITION="after"
export YSU_MODE=ALL

# ── Smart aliases ────────────────────────────────────────────
# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'               # cd to previous dir

# Quick edits
alias zshrc='nvim ~/.zshrc && source ~/.zshrc'
alias reload='source ~/.zshrc && echo "✅ Shell reloaded"'

# File operations with confirmation
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'               # confirm before deleting multiple files
alias mkdir='mkdir -pv'         # create parent dirs automatically

# Search shortcuts
fif() {
  # Find In Files — fuzzy search file contents
  [[ -z "$1" ]] && echo "Usage: fif <search term>" && return 1
  rg --color=always --line-number "$1" | \
    fzf --ansi --delimiter : \
    --preview 'bat --color=always --style=numbers {1} --highlight-line {2}' \
    --preview-window '~4,+{2}+4/3,<80(up)'
}

# Interactive cd with preview
fcd() {
  local dir
  dir=$(fd --type d --hidden --follow --exclude .git 2>/dev/null | \
    fzf --preview 'eza --tree --icons --color=always --level=2 {}') && cd "$dir"
}

# Fuzzy kill process
fkill() {
  local pid
  pid=$(ps aux | fzf --header='Select process to kill' | awk '{print $2}')
  [[ -n "$pid" ]] && kill -9 "$pid" && echo "Killed PID $pid"
}

# Fuzzy git checkout branch
fbr() {
  local branch
  branch=$(git branch --all | fzf --preview 'git log --oneline --graph {}') && \
    git checkout "$(echo "$branch" | sed 's/remotes\/origin\///' | tr -d ' ')"
}

# Open recent file in nvim
frecent() {
  local file
  file=$(zoxide query --list 2>/dev/null | \
    fzf --preview 'eza --tree --icons --color=always --level=2 {}') && \
    cd "$file"
}

# ── Keybindings summary ──────────────────────────────────────
# →          Accept full autosuggestion
# Ctrl+F     Accept full autosuggestion
# Ctrl+]     Accept one word of suggestion
# ↑ / ↓     Search history by what you already typed
# Ctrl+R     Fuzzy search full command history
# Ctrl+T     Fuzzy find file → insert path
# Alt+C      Fuzzy find directory → cd into it
# Tab        Fuzzy completion menu with preview
# Esc Esc    Fix last wrong command (thefuck)

# ── Show smartshell tip on new terminal ──────────────────────
smartshell_tip() {
  local tips=(
    "→ arrow key accepts suggestion | Ctrl+R fuzzy history search"
    "Tab shows fuzzy completion with file preview"
    "↑↓ arrows search history by what you already typed"
    "Type part of old command + ↑ to find it in history"
    "Ctrl+T fuzzy finds any file | Alt+C fuzzy jumps to folder"
    "Esc Esc fixes your last wrong command automatically"
    "fif <term> searches inside all files with preview"
    "fcd opens fuzzy folder picker with tree preview"
    "fkill opens fuzzy process killer"
    "fbr opens fuzzy git branch switcher"
    "z <partial name> jumps to any folder you've been to"
  )
  echo -e "${CYAN}  ⚡ SmartShell tip:${RESET} ${tips[$RANDOM % ${#tips[@]}]}"
}
smartshell_tip
SMARTSHELL

  log "SmartShell config written to .zshrc"
}

# ── Update OMZ plugins list ──────────────────────────────────
update_omz_plugins() {
  banner "Updating OMZ Plugin List"

  # Update the plugins=() line in .zshrc to include all smart plugins
  sed -i 's/^plugins=(.*)/plugins=(git docker docker-compose kubectl python node rust golang flutter fzf zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search fzf-tab you-should-use colored-man-pages command-not-found archlinux)/' \
    "$HOME/.zshrc" 2>/dev/null || warn "Could not update plugins list — add manually"

  log "OMZ plugins list updated"
}

# ── Summary ──────────────────────────────────────────────────
print_summary() {
  echo ""
  echo -e "${BOLD}${MAGENTA}╔═══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${MAGENTA}║  ⚡ SmartShell Active!                         ║${RESET}"
  echo -e "${BOLD}${MAGENTA}╚═══════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "  ${CYAN}Feature${RESET}              ${CYAN}How to use${RESET}"
  echo -e "  ───────────────────────────────────────────────"
  echo -e "  Ghost suggestions    Type anything → see suggestion in grey"
  echo -e "                       Press ${GREEN}→${RESET} or ${GREEN}Ctrl+F${RESET} to accept it"
  echo -e ""
  echo -e "  History search       Start typing → press ${GREEN}↑${RESET} to find matches"
  echo -e "                       Press ${GREEN}Ctrl+R${RESET} for fuzzy full history"
  echo -e ""
  echo -e "  Tab completion       Press ${GREEN}Tab${RESET} → fuzzy menu with file preview"
  echo -e "                       Type to filter, Enter to select"
  echo -e ""
  echo -e "  Find files           ${GREEN}Ctrl+T${RESET} → pick any file, inserts path"
  echo -e "  Jump to folder       ${GREEN}Alt+C${RESET} → pick folder, cd into it"
  echo -e ""
  echo -e "  Fix wrong command    Type wrong command → press ${GREEN}Esc Esc${RESET}"
  echo -e "                       Or type ${GREEN}fix${RESET} after any error"
  echo -e ""
  echo -e "  Smart functions:"
  echo -e "  ${GREEN}fif <term>${RESET}           Search inside files with preview"
  echo -e "  ${GREEN}fcd${RESET}                  Fuzzy folder picker"
  echo -e "  ${GREEN}fkill${RESET}                Fuzzy process killer"
  echo -e "  ${GREEN}fbr${RESET}                  Fuzzy git branch switcher"
  echo -e "  ${GREEN}z <name>${RESET}             Jump to any previously visited folder"
  echo -e ""
  echo -e "  ${YELLOW}⚡ Run this to activate now:${RESET}"
  echo -e "  source ~/.zshrc"
  echo ""
}

# ── Main ─────────────────────────────────────────────────────
main() {
  banner "SmartShell — Intelligent Terminal Setup"
  install_packages
  setup_omz_plugins
  write_smartshell_config
  update_omz_plugins
  print_summary
}

main "$@"
