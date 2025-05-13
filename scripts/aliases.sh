#!/bin/zsh

# Exporting aliases
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export PAGER_PASSWORD="op://private/m2-login/password"
export TFENV_ARCH=amd64
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
# export DOCKER_DEFAULT_PLATFORM=linux/amd64

alias curl-gcp='curl -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) -H "Content-Type: application/json; charset=utf-8"'
alias pager='cd ~/Documents/pager'
alias os='cd ~/Documents/os'
alias pof='cd ~/Documents/pof'
alias reload='source ~/.config/zsh/.zshrc'
alias oplogin='eval $(op signin)'
alias getpass="op run --no-masking -- printenv PAGER_PASSWORD | pbcopy && echo 'Password copied to clipboard'"
alias g13="/Users/shankyjs/Documents/os/garden-io/garden-versions/garden-13/bin/garden"
export EDITOR="cursor -w"

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

function vaultlogin () {
  export VAULT_ADDR=https://vault.pagerinc.com
  export VAULT_TOKEN=$(vault login -method=oidc role="gsuite-role" -format=json | jq -r '.auth.client_token')
}

function getnpm () {
  export NPM_TOKEN=$(op item get pgr-npmjs --field NPM_TOKEN)
}

function getharness() {
  export HARNESS_ACCOUNT_ID=$(op item get harness-pat --field account_id)
  export HARNESS_API_KEY=$(op item get harness-pat --field credential)
  echo "AccountID: $HARNESS_ACCOUNT_ID"
  echo "Secret: $HARNESS_API_KEY"
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

# alias to find release in org by a 'contain' tagName

function gh_find_release() {
  if [ $# -ne 3 ]; then
    echo "Usage: gh_find_release <org_name> <repo_name> <search_term>"
    return 1
  fi

  local org_name=$1
  local repo_name=$2
  local search_term=$3

  # Validate inputs are not empty
  if [ -z "$org_name" ] || [ -z "$repo_name" ] || [ -z "$search_term" ]; then
    echo "Error: All parameters must not be empty"
    return 1
  fi

  # List releases and filter by search term
  gh release list \
    --repo "$org_name/$repo_name" \
    -L 10000 \
    --json tagName,name,publishedAt \
    -q ".[] | select(.tagName | contains(\"$search_term\")) | \"[\(.publishedAt)] \(.tagName) - \(.name)\""
}

newshuttle() {
  sudo pfctl -f /etc/pf.conf

  local instance_name
  instance_name=$(gcloud compute instance-groups managed list-instances iap-bastion-instance-group \
    --zone us-east1-c \
    --project=shared-vpc-host-bd39 \
    --format="value(name)" | shuf -n 1)

  sshuttle \
    --ssh-cmd="gcloud --project shared-vpc-host-bd39 compute ssh --tunnel-through-iap --ssh-key-expire-after 2m \
    --quiet --zone us-east1-c --ssh-flag='-ServerAliveInterval=60' --ssh-flag='-ServerAliveCountMax=120'" \
    -r "$instance_name" 172.16.0.0/12 10.0.0.0/8
}