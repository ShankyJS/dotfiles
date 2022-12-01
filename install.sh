#!/bin/zsh
# source all to prevent repeating installations
eval "$(/opt/homebrew/bin/brew shellenv)"
source ~/.zshrc
# Installing prerequisites

homebrew_packages() {
    echo "Installing brew dependencies"
    brew tap garden-io/garden
    brew install tfenv kubectx garden-cli awscli vault gh sshuttle fzf k9s gojq
    brew install --cask google-cloud-sdk amethyst visual-studio-code 1password/tap/1password-cli
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

if kubectl &> /dev/null
then
    echo "kubectl is already installed, no action needed."
else
    echo "kubectl was not present, installing"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/arm64/kubectl"
fi

if helm version &> /dev/null
then
    echo "Helm is already installed, no action needed."
else
    echo "Helm was not present, installing"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
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
if [ -f .gitconfig ]; then
    echo "gitconfig is not present, installing"
    cp ./gitconfig/.gitconfig ~/
else
    echo "gitconfig is present, no action needed."
fi

if [ ! -f "~/.kube/config" ]; then
    echo "kubeconfig is present, no action needed."
else
    gcloud components install gke-gcloud-auth-plugin
    gcloud container clusters get-credentials dev-1 --region us-east1 --project develop-251413
    gcloud container clusters get-credentials staging-1 --region us-east1 --project staging-197117
    gcloud container clusters get-credentials qa-1 --region us-east1 --project staging-197117
    gcloud container clusters get-credentials prod-1 --region us-east1 --project production-197117
    gcloud container clusters get-credentials prod-2 --region us-east1 --project production-197117
    gcloud container clusters get-credentials prod-3 --region us-east1 --project production-197117
    gcloud container clusters get-credentials spinnaker-prod --region us-east1 --project animated-sniffle
fi