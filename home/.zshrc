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
export GRADLE_HOME=/opt/homebrew/opt/gradle/libexec
export PATH="$JAVA_HOME:$GRADLE_HOME:$HOME/.local/bin:$PATH"
export EDITOR="fresh"
export LC_ALL=C.UTF-8

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
alias git='LANG=en_GB git'
alias gsw='LANG=en_GB git switch'
alias gco='LANG=en_GB git checkout'
alias gs='LANG=en_GB git status'
alias ga='LANG=en_GB git add'
alias gaa='LANG=en_GB git add .'
alias gc='LANG=en_GB git commit -m'
alias gca='LANG=en_GB git commit --amend'
alias gcan='LANG=en_GB git commit --amend --no-edit'
alias gp='LANG=en_GB git push'
alias gpsu='LANG=en_GB git push --set-upstream origin $(git branch --show-current)'
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
	local commit="$(LANG=en_GB git log $1 | head -1 | awk '{print $2}')"
	LANG=en_GB git cherry-pick $commit
}

# git checkout master/main shortcut
gcm() {
  local branch
  if git show-ref --verify --quiet refs/heads/main; then
    branch="main"
  else
    branch="master"
  fi
  git checkout "$branch"
}

# git commit with branch name (w/o prefix) as start of message
gce() {
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

decode_jwt() {
    pbpaste | jq -R "$@" 'split(".") | .[1] | gsub("-"; "+") | gsub("_"; "/") | @base64d | fromjson'
}
