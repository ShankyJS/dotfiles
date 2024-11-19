#!/bin/zsh
# source all to prevent repeating installations
eval "$(/opt/homebrew/bin/brew shellenv)"
source ~/.zshrc
# Installing prerequisites

homebrew_packages() {
    echo "Installing brew dependencies"
    brew bundle install --file=./Brewfile
}

# if command brew works
if brew -v &> /dev/null
then
    echo "brew already installed"
    homebrew_packages
else
    echo "brew not installed"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo '# Set PATH, MANPATH, etc., for Homebrew.' >> ~/.zshrc
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    eval "$(/opt/homebrew/bin/brew shellenv)"
    homebrew_packages
fi

if [ -d ~/.oh-my-zsh ]; then
	echo "oh-my-zsh is installed, no action needed."
 else
 	echo "oh-my-zsh is not installed, installing"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    # Goes into the folder and comes back, really clever solution. https://apple.stackexchange.com/a/321938
    cd ~/Library/Fonts && {
    curl -O 'https://github.com/Falkor/dotfiles/blob/master/fonts/SourceCodePro%2BPowerline%2BAwesome%2BRegular.ttf'
    cd -; }
    # Just in case we need it.
    git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
    # Iterm color
    curl -O 'https://raw.githubusercontent.com/utsavized/iterm2/develop/utsavized.itermcolors' > utsavized.itermcolors
    # Need dracula theme as well
    git clone https://github.com/dracula/iterm.git
    mv iterm/Dracula.itermcolors .
    mkdir color-themes
    mv *.itermcolors ./iterm-color-themes/
    rm -fr iterm
fi

# if gitconfig is not present, copy it.
if [ ! -f ~/.gitconfig ]; then
    echo "gitconfig is not present, installing"
    ln -s ./gitconfig/.gitconfig ~/.gitconfig # give me an absolute path to h
else
    echo "gitconfig is present, no action needed."
fi

if [ ! -f "~/.kube/config" ]; then
    echo "kubeconfig is present, no action needed."
else
    gcloud components install gke-gcloud-auth-plugin
    gcloud container clusters get-credentials dev-1s --region us-east1 --project develop-251413
    gcloud container clusters get-credentials staging-1 --region us-east1 --project staging-197117
    gcloud container clusters get-credentials staging-1s --region us-east1 --project staging-197117
    gcloud container clusters get-credentials qa-1s --region us-east1 --project staging-197117
    gcloud container clusters get-credentials prod-1 --region us-east1 --project production-197117
    gcloud container clusters get-credentials prod-2 --region us-east1 --project production-197117
    gcloud container clusters get-credentials prod-3 --region us-east1 --project production-197117
    gcloud container clusters get-credentials platform-tooling-1a --region us-east1 --project animated-sniffle
    gcloud container clusters get-credentials prod-4s --region us-east1 --project production-197117
fi


# check if nvm is installed
if command -v nvm &> /dev/null; then
    echo "nvm already installed"
else
    echo "nvm not installed"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    # make nvm command active without terminal reopening
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    # install node
    nvm install v18
    nvm alias default v18
    nvm use default

    # install/update global packages
    npm install -g gulp-cli ts-node typescript

    # install yarn
    npm install --global yarn
fi
