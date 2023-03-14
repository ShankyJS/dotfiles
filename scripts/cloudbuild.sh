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
