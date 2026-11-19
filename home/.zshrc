#  $██████╗$██████╗$███╗$$$██╗███████╗██╗$██████╗$
#  ██╔════╝██╔═══██╗████╗$$██║██╔════╝██║██╔════╝$
#  ██║$$$$$██║$$$██║██╔██╗$██║█████╗$$██║██║$$███╗
#  ██║$$$$$██║$$$██║██║╚██╗██║██╔══╝$$██║██║$$$██║
#  ╚██████╗╚██████╔╝██║$╚████║██║$$$$$██║╚██████╔╝
#  $╚═════╝$╚═════╝$╚═╝$$╚═══╝╚═╝$$$$$╚═╝$╚═════╝$
#  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

###
# envs
###

export ZSH="$HOME/.oh-my-zsh"
export JAVA_HOME="$HOME/.local/share/mise/installs/java/temurin-21"
export GRADLE_HOME="/opt/homebrew/opt/gradle"
export PATH="$JAVA_HOME:$GRADLE_HOME:$HOME/.local/bin:$PATH"
export EDITOR="fresh"
export LC_ALL="C.UTF-8"

eval "$(mise activate zsh)"

###
# zsh
###

setopt NO_BEEP

zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
autoload -U compinit && compinit

HISTSIZE=999
SAVEHIST=1000

setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt EXTENDED_HISTORY

autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '\e[A' history-beginning-search-backward-end
bindkey '\e[B' history-beginning-search-forward-end
zstyle ':completion:*' menu select

WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
autoload -Uz select-word-style
zstyle ':zle:shift-select::*' word-style normal
zstyle ':zle:shift-select::*' word-chars "$WORDCHARS"
zstyle ':zle:*' word-style normal

###
# starship
###

if [[ -z "$STARSHIP_INITIALIZED" ]]; then
    eval "$(starship init zsh)"
    export STARSHIP_INITIALIZED=1
fi

###
# plugins
###

source ~/zsh-plugins/zsh-shift-select/zsh-shift-select.plugin.zsh

###
# aliases
###

defaults write -g ApplePressAndHoldEnabled -bool false

alias l='eza -lAh'
alias ls="eza -a"
alias la="eza -a"
alias ll="eza -al"
alias ra="ranger"
alias gsw='git switch'
alias gco='git checkout'
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit -m'
alias gca='git commit --amend'
alias gcan='git commit --amend --no-edit'
alias gp='git push'
alias gpsu='git push --set-upstream origin $(git branch --show-current)'
alias gsl='git stash list'
alias gspop='git stash pop'
alias k='kubectl'
alias zs='fresh ~/.zshrc'
alias f='fresh'
alias ern='cd ~/IdeaProjects/ern'
alias jdk17='mise use --global java@temurin-17 && echo && java --version'
alias jdk21='mise use --global java@temurin-21 && echo && java --version'
alias jdk25='mise use --global java@temurin-25 && echo && java --version'

###
# functions
###

# caffeinate
function caf(){
  if pgrep -x "caffeinate" > /dev/null; then
    sudo pmset disablesleep 0
    pkill -x caffeinate
    echo "☕️ Caffeinate stopped. Sleep re-enabled."
  else
    sudo -v
    sudo pmset disablesleep 1
    nohup caffeinate -d >/dev/null 2>&1 &
    echo "☕️ Caffeinate is now running. Sleep disabled."
  fi
}

# customized diff
function diff(){
  local shortArgs="-HN" longArgs firstFile secondFile
  for arg in "$@"; do
    if [[ "$arg" == --* ]]; then
      longArgs+=" ${arg}"
    elif [[ "$arg" == -* ]]; then
      shortArgs+="${arg:1}"
    else
      if [[ -z "$firstFile" ]]; then
        firstFile="$arg"
      elif [[ -z "$secondFile" ]]; then
        secondFile="$arg"
      else
        echo "Invalid number of files to compare!"
        return 0;
      fi
    fi
  done
  local args="$shortArgs$lognArgs"
  icdiff "$args" "$firstFile" "$secondFile" | less -R
}

# git cherry-pick last commit from specific branch
function gcpf(){
  local commit="$(git log $1 | head -1 | awk '{print $2}')"
  git cherry-pick $commit
}

# git checkout master/main shortcut
function gcm() {
  local branch
  if git show-ref --verify --quiet refs/heads/main; then
    branch="main"
  else
    branch="master"
  fi
  git checkout "$branch"
}

# git commit with branch name as start of message
function gce() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: not a Git repository."
    return 1
  fi

  if [ -z "$1" ]; then
    echo "Error: please provide a commit message."
    return 1
  fi

  local full_branch=$(git branch --show-current)
  local branch_name="${full_branch##*/}"

  git commit -m "$branch_name $1"
}

# git stash push all and add message if argument present
function gsp() {
    if [[ $# -eq 0 ]]; then
        git stash push -u
    else
        git stash push -u -m "$*"
    fi
}

function decode_jwt() {
    pbpaste | jq -R "$@" 'split(".") | .[1] | gsub("-"; "+") | gsub("_"; "/") | @base64d | fromjson'
}

function zip_sign() {
  if [[ -z "$1" ]]; then
    echo "Error: provide version (example: zip_sign 3.38)"
    return 1
  fi

  local version="$1"
  local archive_name="${version//./_}"
  local base_dir="src/main/resources/fop/template/sign"
  local save_path
  
  if [[ -z "$2" ]]; then
    save_path="$HOME/Downloads"
  else
    save_path="${2%/}"
  fi
  
  if [[ ! -d "$save_path" ]]; then
    echo "Error: path \"$save_path\" not found, provide save path (example: zip_sign 3.38 $HOME/Downloads)
    \rDefault save path is \"$HOME/Downloads\""
    return 1
  fi

  if [[ ! -d "$base_dir/$version" ]]; then
    echo "Error: path $base_dir/$version not found"
    return 1
  fi

  zip -j "$save_path/${archive_name}.zip" \
    "$base_dir/$version"/*.xsl \
    "$base_dir"/*.xsl \
    -x "*.DS_Store" -x "__MACOSX*" -x "*/.DS_Store"
}
