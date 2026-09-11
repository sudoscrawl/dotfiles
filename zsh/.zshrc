alias vim='nvim'
alias venv='source .venv/bin/activate'
alias loc='git ls-files | xargs wc -l'


fastfetch
fpath+=($HOME/.zsh/pure)

autoload -U promptinit; promptinit
prompt pure


export QT_QPA_PLATFORMTHEME=qt6ct


export PATH="/home/ayush/.local/bin:$PATH"
