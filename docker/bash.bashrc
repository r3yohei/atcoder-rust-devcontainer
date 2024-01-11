# user
export PS1="\[\e[31m\]\u\[\e[m\]:\[\e[33m\]\w\[\e[m\]\\n\$ "

# alias
alias grep="grep --color=auto"
alias ..="cd .."
alias ls="exa"
alias ll="exa -laF"
alias cat="bat"
alias fd="fdfind"
alias pip="pip3"
alias python="python3"

# 出力の後に改行を入れる
function add_line {
  if [[ -z "${PS1_NEWLINE_LOGIN}" ]]; then
    PS1_NEWLINE_LOGIN=true
  else
    printf "\n"
  fi
}
PROMPT_COMMAND="add_line"

# git
git config --global user.email r3yohei@gmail.com
git config --global user.name r3yohei

# pipによるバイナリのデフォルトのインストール先は~/.local/binであるが，ubuntuのデフォルトの$PATHに含まれないので追記する
export PATH="$HOME/.local/bin:$PATH"