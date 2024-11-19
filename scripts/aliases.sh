#!/bin/zsh

# Exporting aliases
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export PAGER_PASSWORD="op://Lifeline/login-laptop/password"
export TFENV_ARCH=amd64
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
# export DOCKER_DEFAULT_PLATFORM=linux/amd64

alias curl-gcp='curl -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) -H "Content-Type: application/json; charset=utf-8"'
alias pager='cd ~/Documents/pager'
alias os='cd ~/Documents/os'
alias reload='source ~/.zshrc'
alias oplogin='eval $(op signin)'
alias getpass="op run --no-masking -- printenv PAGER_PASSWORD | pbcopy && echo 'Password copied to clipboard'"
alias g13="/Users/shankyjs/Documents/os/garden-io/garden-versions/garden-13/bin/garden"

# Google Cloud aliases
alias gactivate="gcloud config configurations activate $1"
alias gset="gcloud config set $1 $2"
alias glist="gcloud config configurations list"
alias gcreate="gcloud config configurations create $1"

# Shuttle aliases
alias getrootpass="op run --no-masking -- printenv PAGER_PASSWORD"
alias getopcode="ykman oath accounts code |awk {'print $2'}"

# Terraform aliases
function getvaultenvars () {
  export VAULT_ADDR=https://vault.pagerinc.com
  export VAULT_ROLE=vault-cloud-build-role
  export VAULT_TOKEN=$(op item get vault-root-token --field password)
}

function getnpm () {
  export NPM_TOKEN=$(op item get pgr-npmjs --field NPM_TOKEN)
}
function getOpCred () {
  op item get $1 --fields $2
}

# Export secrets from 1Password to environment variables
function setOpSecrets () {
  export CF_API_TOKEN=$(getOpCred cf-external-dns-garden credential)
}

alias tf="terraform"
alias tg="terragrunt"
