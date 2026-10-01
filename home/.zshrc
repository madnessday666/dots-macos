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
export EDITOR="ttt"
export LC_ALL=C.UTF-8

eval "$(mise activate zsh)"

###
# zsh
###

setopt NO_BEEP

zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
autoload -U compinit && compinit

setopt SHARE_HISTORY
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt HIST_EXPIRE_DUPS_FIRST
setopt EXTENDED_HISTORY

autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '\e[A' history-beginning-search-backward-end # sometimes this is '^[OA'
bindkey '\e[B' history-beginning-search-forward-end # sometimes this is '^[OB'

zstyle ':completion:*' menu select

bindkey "^[[1;3C" forward-word # opt+right arrow to jump a word forward
bindkey "^[[1;3D" backward-word # opt+left arrow to jump a word back

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

source ~/.zsh-shift-select/zsh-shift-select.plugin.zsh

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
alias t='ttt'
alias zs='ttt ~/.zshrc'
alias ern='cd ~/IdeaProjects/ern'
alias jdk17='mise use --global java@temurin-17 && echo && java --version'
alias jdk21='mise use --global java@temurin-21 && echo && java --version'
alias jdk25='mise use --global java@temurin-25 && echo && java --version'

###
# functions
###

# git cherry-pick last commit from specific branch
function gcpf(){
	local commit="$(LANG=en_GB git log $1 | head -1 | awk '{print $2}')"
	LANG=en_GB git cherry-pick $commit
}

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
        echo "Неккоректное количество файлов для сравнения!"
        return 0;
      fi
    fi
  done
  local args="$shortArgs$lognArgs"
  icdiff "$args" "$firstFile" "$secondFile" | less -R
}

# Функция для поиска файлов, которые НЕ содержат указанную подстроку
# Использование: fs <подстрока> [путь_к_папке]
function fs() {
    local exists=false

    if [[ "$1" == "--exists" || "$1" == "-e" ]]; then
        exists=true
        shift
    fi

    if [ $# -lt 1 ] || [ $# -gt 2 ]; then
        echo "Использование: fs [-e|--exists] <подстрока> [путь к папке]"
        echo ""
        echo "Поиск файлов по наличию/отсутствию подстроки в содержимом."
        echo ""
        echo "Флаги:"
        echo "  -e, --exists   Искать файлы, СОДЕРЖАЩИЕ подстроку (по умолчанию — НЕ содержащие)"
        echo ""
        echo "Примеры:"
        echo "  fs 'TODO'                     — файлы без 'TODO' в текущей директории"
        echo "  fs 'TODO' /path/to/dir        — файлы без 'TODO' в указанной директории"
        echo "  fs -e 'TODO'                  — файлы с 'TODO' в текущей директории"
        echo "  fs --exists 'TODO' /path/to   — файлы с 'TODO' в указанной директории"
        return 1
    fi

    local substring="$1"
    local search_dir="${2:-.}"  # По умолчанию текущая директория

    # Проверяем существование директории
    if [[ ! -d "$search_dir" ]]; then
        echo "Ошибка: директория '$search_dir' не существует"
        return 1
    fi

    # Переходим в указанную директорию
    pushd "$search_dir" > /dev/null

    # Получаем список файлов
    local files=(*(N.))

    # Проверяем, есть ли файлы в директории
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "Нет файлов в директории '$search_dir'"
        popd > /dev/null
        return 0
    fi

    if $exists; then
        echo "Файлы, содержащие подстроку '$substring' в '$search_dir':"
    else
        echo "Файлы, не содержащие подстроку '$substring' в '$search_dir':"
    fi
    echo "-----------------------------------------------------------"

    # Перебираем все файлы в директории
    local found_files=()
    for file in "${files[@]}"; do
        # Ищем подстроку в файле
        if ($exists && grep -q "$substring" "$file" 2>/dev/null) || \
        (! $exists && ! grep -q "$substring" "$file" 2>/dev/null); then
            found_files+=("$file")
        fi
    done

    # Выводим результаты
    if [[ ${#found_files[@]} -eq 0 ]]; then
        if $exists; then
            echo "Ни один файл не содержит подстроку '$substring'"
        else
            echo "Все файлы содержат подстроку '$substring'"
        fi
    else
        for file in "${found_files[@]}"; do
            echo "$file"
        done
        echo "-----------------------------------------------------------"
        echo "Найдено файлов: ${#found_files[@]}"
    fi

    # Возвращаемся в исходную директорию
    popd > /dev/null
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
    echo "Ошибка: это не Git-репозиторий."
    return 1
  fi

  if [ -z "$1" ]; then
    echo "Ошибка: укажите сообщение коммита."
    return 1
  fi

  local full_branch=$(git branch --show-current)
  local branch_name="${full_branch##*/}"

  git commit -m "$branch_name $1"
}

decode_jwt() {
    pbpaste | jq -R "$@" 'split(".") | .[1] | gsub("-"; "+") | gsub("_"; "/") | @base64d | fromjson'
}
