#!/bin/zsh

c-cloudbuild-decrypt-to-envars(){
    local the_file secret project location keyRing cryptoKey val secret
    the_file="$1"
    shift 1
    secret="$(cat "$the_file" | gojq --yaml-input -r '.secrets[0].kmsKeyName')"
    [[ $secret =~ projects/([^/]*)/locations/([^/]*)/keyRings/([^/]*)/cryptoKeys/([^/]*) ]] || return
    project="${match[1]}"
    location="${match[2]}"
    keyRing="${match[3]}"
    cryptoKey="${match[4]}"
    for key in $(cat "$the_file" | gojq --yaml-input -r '.secrets[0].secretEnv|keys|.[]'); do
        val="$(cat "$the_file" | gojq --yaml-input -r  ".secrets[0].secretEnv.$key")"
        echo "$key"
        secret="$(echo "$val" | base64 -D | gcloud kms decrypt --project=$project --keyring=$keyRing --key=$cryptoKey --location=$location --ciphertext-file=- --plaintext-file=-)"
        printf -v "$key" '%s' "${secret}"
        export $key="${secret}"
    done
    unset GITHUB_TOKEN
}

c-cloudbuild-encrypt-value(){

    local the_file secret project location keyRing cryptoKey variable value secret
    the_file="$1"
    shift 1
    variable="$1"
    shift 1
    value="$1"
    shift 1
    secret="$(cat "$the_file" | gojq --yaml-input -r '.secrets[0].kmsKeyName')"
    [[ $secret =~ projects/([^/]*)/locations/([^/]*)/keyRings/([^/]*)/cryptoKeys/([^/]*) ]] || return
    project="${match[1]}"
    location="${match[2]}"
    keyRing="${match[3]}"
    cryptoKey="${match[4]}"
    secret="$(echo "$value"| gcloud kms encrypt --project=$project --keyring=$keyRing --key=$cryptoKey --location=$location --ciphertext-file=- --plaintext-file=- | base64)"
    echo "    $variable: '$secret'" >> "$the_file"
}

s-setup-iap () {
    # use c-decrypt-to-envars on one of the project repos first
    local GATE_ENDPOINT=https://spinnaker.pagerinc.com/gate
    local SERVICE_ACCOUNT_DEST=$HOME/.spin/spinnaker_sa.json
    local SPIN_CONFIG_DEST=~/.spin/config
    printf "%s" "$SPINNAKER_SA" > "$SERVICE_ACCOUNT_DEST"
    cat <<EOF >${SPIN_CONFIG_DEST}
gate:
  endpoint: ${GATE_ENDPOINT}
auth:
  enabled: true
  iap:
    iapClientId: ${SPINNAKER_GATE_IAP_CLIENT_ID}
    serviceAccountKeyPath: ${SERVICE_ACCOUNT_DEST}
EOF
}

function s-disable-pipelines (){
        APP="$1"
  pipelines=()
  while IFS= read -r pipeline; do
    pipelines+=("$pipeline")
  done < <(spin pipeline list --application "${APP}" | gojq -r '.[].name' | grep 'cloudrun')

  printf "%s\n" "${pipelines[@]}" | parallel spin pipeline update --application "${APP}" --name {} --disabled
}
