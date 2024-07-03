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
alias pbcopy="xsel --clipboard --input"

# git
git config --global user.email r3yohei@gmail.com
git config --global user.name r3yohei

# pipによるバイナリのデフォルトのインストール先は~/.local/binであるが，ubuntuのデフォルトの$PATHに含まれないので追記する
export PATH="$HOME/.local/bin:$PATH"

# enable starship prompt
eval "$(starship init bash)"