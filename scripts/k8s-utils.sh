#!/bin/bash

s-get-file(){
    local the_pod
    the_file="$1"
    shift
    the_pod="$1"
    shift
    kubectl -n "$NAMESPACE" exec "$the_pod"  -- cat "$the_file" |pbcopy
}

s-delete-service(){
    local ns app doit
    app="$1"
    ns="$2"
    ns="${ns:=$NAMESPACE}"
    kubectl -n "$ns" get Job,CronJob,DatadogMonitor,Deployment,HorizontalPodAutoscaler,VirtualService,ServiceEntry,NetworkPolicy,Service,PodDisruptionBudget,Role,RoleBinding,Role,Service,ServiceAccount -l "app=${app},app.kubernetes.io/managed-by=spinnaker"
    echo "You're about to delete all these objects. This action cannot be undone."
    read  -rsk 1 "doit?Are you sure(Y/n)? "
    printf "\n"
    if [[ ! "$doit" =~ ^[Yy]$ ]]
    then
        return
    fi
    kubectl -n "$ns" delete Job,CronJob,DatadogMonitor,Deployment,HorizontalPodAutoscaler,VirtualService,ServiceEntry,NetworkPolicy,Service,PodDisruptionBudget,Role,RoleBinding,Role,Service,ServiceAccount -l "app=${app},app.kubernetes.io/managed-by=spinnaker" --wait=0
}

s-environments-migrated(){
	a="$(echo -n "$1" | gsed -r 's/(-)(\w)/\U\2/g' )"
    echo "Looking for $a"
	for i in pgr-dev hrz-dev pgr-qa hrz-qa pgr-stage hrz-stage pgr-sdx sra-prod prod-2
	do
		echo "$i"
		gojq --yaml-input -r ".stagnation.$a" "releases/$i/manifest.yaml"
	done
}

s-service-selector-validation(){
    local service_selector app
    app="$1"
    service_selector="$(kubectl -n "$NS" get services "$NS-$app" -o jsonpath="{.spec.selector}"| gojq -r "[to_entries[]|[.key, .value]|join(\"=\")]|join(\",\")")"
    kubectl -n "$NS" get pods -l "${service_selector}"
}

s-duplicate-values(){  
    # local envi mye i ienv
    ienv="$1"
    ienv="${ienv:=pgr-dev}"
    typeset -A envi
    envi=(
        pgr-dev     dev-1
        pgr-qa      qa-1
        pgr-stage   staging-1
        pgr-sdx     staging-1
        hrz-dev     dev-1
        hrz-stage   staging-1
        hrz-qa      qa-1
        sra-prod    prod-1
        prod-2      prod-2
    )
    for i in pgr-dev pgr-qa pgr-stage pgr-sdx hrz-dev hrz-stage hrz-qa sra-prod prod-2;
    do
        cp -f "$ienv-values.yaml" "$i-values.yaml"
    done;
    for i in $(ls);
    do
        mye="$(echo "$i" | gsed s/\-values.yaml//g)";
        gsed -i "s/${ienv//-/\\-}/${mye//-/\\-}/g" "$i";
        gsed -i "s/${envi[$ienv]//-/\\-}/${envi[$mye]//-/\\-}/g" "$i";
    done
}

s-list-envars(){
    local service i d_json
    service="$1"
    shift
    d_json="$(kubectl -n "$NS" get deployment "$service" -o yaml)"
    printf "\n--- # init containers ---\n\n"
    echo "$d_json"|gojq --yaml-input --yaml-output '.spec.template.spec.initContainers[].env|map({"key":(.name),"value":(if .value then .value else .valueFrom end) })|from_entries'
    printf "\n--- # containers ---\n\n"
    echo "$d_json"|gojq --yaml-input --yaml-output '.spec.template.spec.containers[].env|map({"key":(.name),"value":(if .value then .value else .valueFrom end) })|from_entries'
    for i in $(echo "$d_json"|gojq --yaml-input -r '.spec.template.spec.containers[].envFrom[].secretRef|select(.name)|.name'); do
        printf "\n--- # $i secrets ---\n\n"
        kubectl -n $NS get secret/$i -o json|gojq --yaml-input --yaml-output '.data|to_entries|map_values(.value=(.value|@base64d))|from_entries';
    done
    for i in $(echo "$d_json"|gojq --yaml-input -r '.spec.template.spec.containers[].envFrom[].configMapRef|select(.name)|.name'); do
        printf "--- # %s configmaps ---" "$i"
        kubectl -n $NS get configmap/$i -o json|gojq --yaml-input --yaml-output '.data' 2>&1 || :
    done
}

s-network-connections(){
    printf "\n* Please review for accuracy. This is a list of apps that connect to your service\n\n"
    local app="$1"
    printf "networkPolicies:\n  ingress:"
    local i
    for i in **/values.yaml; do
        local j="$(cat  $i | gojq -r --yaml-input ".networkPolicy|select(.labels != null)|.labels[]|select(.|test(\"^$app\$\"))")"
        if [ "$j" ]; then
            printf "\n    - name: %s\n      targetLabels:\n        app: %s" "${i/\/values.yaml/}" "${i/\/values.yaml/}"
        fi
    done
    printf "\n# Validate these with kubectl -n \$NS get pods -l \$NS-%s-client=true\n" "$app"
    printf "\n* Note: Please include - kong-admin if your app connects to kong-admin under connections\n\n"
    local app="$1"
    cat $app/values.yaml | gojq --yaml-output --yaml-input "{temporaryEgressNetworkLabels: {labels: .networkPolicy.labels}}"

}

s-network-connections-legacy(){
    s-network-connections "$1"
}

s-envar-diff () {
    if [[ "$1" = "help" || "$1" = "--help" || "$1" = "-h" ]]; then
        cat  <<_EOF_
      set NS to your namespace:
        NS=pgr-dev
        app=my_app
      best if we have fresh pods:
        kubectl -n "\$NS" get deployment -l app="\$app" -o name | xargs kubectl -n "\$NS" rollout restart
      get some pods with:
        kubectl -n "\$NS" get pods -l app=\$app
      use like this:
        diff_envars first_pod_#### second_pod_####
_EOF_

        return;
    fi;
    local fst_app="$1";
    local snd_app="$2";
    local afile;
    local bfile;
    afile="$(mktemp -t "a-file-")";
    bfile="$(mktemp -t "b-file-")";
    echo "Files: $afile $bfile";
    kubectl -n "$NS" exec "$fst_app" -- "sh" "-c" "[ -d /vault/secrets ] && for f in /vault/secrets/*.env; do . \$f; done;env" | sort > "$afile";
    kubectl -n "$NS" exec "$snd_app" -- "sh" "-c" "[ -d /vault/secrets ] && for f in /vault/secrets/*.env; do . \$f; done;env" | sort > "$bfile";
    # git diff -U0 --no-index --word-diff "$afile" "$bfile"
    # you can use this instead of git if you have EDITOR set and working
    code -w --diff "$afile" "$bfile";
    rm "$afile" "$bfile"
}

s-list-chart-services(){
    local context
    for i in pgr-dev pgr-qa pgr-stage pgr-sdx hrz-dev hrz-qa hrz-stage sra-prod prod-2; do
        context="$(context "$i")"
        echo ------ For "$i" in "$context" ------
        kubectl -n="$i" --context="$context" get deploy -l app.kubernetes.io/managed-by=Helm -o name | egrep  -v "kong|default"
    done
}

# Function to repeat a passed command
# Usage: rerun [-t] COMMAND FLAGS
function rerun {
  local RERUN_UNTIL_FAIL
  local SUCCESS="\e[1;31mSUCCESS: \e[1;32mCTRL + C to cancel!\e[0m Run:"
  local FAIL="\e[1;31mERROR: \e[1;32mCTRL + C to cancel!\e[0m Run:"

  if [[ $# -eq 0 ]] ||  [[ $1 == "-h" ]]; then
    echo "You didn't pass any commands! You FOOL!!!"
    echo ""
    echo "USAGE: rerun COMMAND"
    echo "EXAMPLE: To test login to a node. Notice \e[1;32m \` \` \e[0m for aliases!"
    echo "         \e[1;32mrerun \`baptflnpd1mop101ops 'test -f ~/.bashrc'\`\e[0m"
    echo "EXAMPLE: To run \e[1;32git pull\e[0m 3 times"
    echo "         \e[1;32mrerun -t 3 git pull\e[0m"
    echo "EXAMPLE: To run \e[1;32git pull\e[0m without exiting"
    echo "         \e[1;32mrerun -f git pull\e[0m"
    echo ""
    return 0
  fi

  # Set's total number of runs before exiting.
  TOTAL_RUN=1000
  CURRENT_RUN=1

  # Checks to see if user passed X runs
  if [[ $1 == "-t" ]]; then
    TOTAL_RUN=$2
    shift 2
  fi

  if [[ $1 == "-r" ]]; then
    RERUN_UNTIL_FAIL=$2
    shift 2
  fi

  if [[ $1 == "-f" ]]; then
    ALWAYS_RERUN=$2
    RERUN_UNTIL_FAIL=100000
    shift 1
  fi

  if [[ -z ${RERUN_UNTIL_FAIL} ]]; then
    # Run the actually command, sleeping 1 second in between
    until "$@" || [[ $CURRENT_RUN -gt $TOTAL_RUN ]] ; do
      echo "\e[1;31mERROR: \e[1;32mCTRL + C to cancel!\e[0m Run: ${CURRENT_RUN}"
      CURRENT_RUN=$((CURRENT_RUN+1))
      sleep 1
    done
  else
    for n in $(seq $RERUN_UNTIL_FAIL); do
      echo "\e[1;32mINFO: \e[1;31m Run Number ${CURRENT_RUN}:\e[0m $@"
      if [[ -z ${ALWAYS_RERUN} ]]; then
        $@ || return 1
      else
        $@ && echo ${SUCCESS} ${CURRENT_RUN} || echo ${FAIL} ${CURRENT_RUN}
      fi
      CURRENT_RUN=$((CURRENT_RUN+1))
      sleep 1
    done
  fi
}

decrypt-secrets() {
  kubectl -n $1 get secret $2 -o json | jq -r '.data | to_entries[] | "\(.key): \(.value | @base64d)"'
}
