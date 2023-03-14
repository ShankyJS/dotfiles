#!/bin/zsh

# Exporting aliases
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export PAGER_PASSWORD="op://Lifeline/login-laptop/password"
export TFENV_ARCH=amd64

alias curl-gcp='curl -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) -H "Content-Type: application/json; charset=utf-8"'
alias pager='cd ~/Documents/pager'
alias os='cd ~/Documents/os'
alias reload='source ~/.zshrc'
alias oplogin='eval $(op signin)'
alias getpass="op run --no-masking -- printenv PAGER_PASSWORD | pbcopy && echo 'Password copied to clipboard'"

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
