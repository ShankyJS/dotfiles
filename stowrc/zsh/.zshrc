export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"

plugins=(
    git
    zsh-autosuggestions
    terraform
    helm
    kubectl
)

export XDG_CONFIG_HOME="~/.config"

source ~/.oh-my-zsh/oh-my-zsh.sh

# Set PATH, MANPATH, etc., for Homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)"

for file in ~/shankyjs-config/scripts/*; do
    source "$file"
done

export PATH="/usr/local/opt/libpq/bin:$PATH"
