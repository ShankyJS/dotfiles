export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
    git
    zsh-autosuggestions
    terraform
    helm
    kubectl
)

source $ZSH/oh-my-zsh.sh

# Set PATH, MANPATH, etc., for Homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)"

for file in ~/shankyjs-config/scripts/*; do
    source "$file"
done
