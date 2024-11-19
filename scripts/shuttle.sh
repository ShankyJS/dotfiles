sshstop() {
    ps | grep .ssh/google_compute_engine | awk '{ print $1 }' | xargs kill
}

function sshstart () {
  sshstop
  user=jhan_silva_pager_com
  project=shared-vpc-host-bd39
  bastion=one-bastion-to-rule-them-all
  zone=us-east1-c
  region=us-east1
  # Networks
  network=172.16.0.0/12
  cloudsql=10.0.0.0/8
  #dev=172.16.1.0/28 sra=172.16.2.0/28 rr=172.16.3.0/28 cox=172.16.4.0/28 stg=172.16.5.0/28

  gactivate pgr-shared
  while ! [[ $(gcloud compute instances list | grep "${bastion}.*RUNNING") ]]; do
    echo "${bastion} is NOT running"
    gcloud compute instances start "${bastion}"
  done
  echo "${bastion} is RUNNING"

  if [[ ! $(op account get) ]]
  then
    echo "You are not logged in to 1Password, sign in"
    oplogin
  fi

  # Sshuttle Connection Block
  if ! [[ $(ps -o 'command' | awk '/sshuttle --ssh-cmd\=gcloud/{print $9}' | grep -w $bastion) ]]; then
    # Grab 2fa code
    local SUDO_PASSWORD=$(getrootpass)
    local authenticator_code=$(op item get pager-google --otp)
    # Use expect to spawn sshuttle and send login creds (output is silenced)
    expect <(cat << EOF
spawn sh -c {
  sshuttle --ssh-cmd="gcloud --project ${project} compute ssh --quiet --zone $zone --ssh-flag=\"-ServerAliveInterval=30\"" -r $bastion $network $cloudsql
}
expect "Password: "
send "${SUDO_PASSWORD}\r"
#expect "google_compute_engine': "
#send "${GCLOUD_SSH_PASSWORD}\r"
expect -re "(\[0-9]): Security code from Google Authenticator application"
set authenticator_method \$expect_out(1,string)
expect "Enter the number for the authentication method to use:"
send "\$authenticator_method\r"
expect "Enter your one-time password:"
send "${authenticator_code}\r"
expect "client: Connected."
interact
EOF
) &
  fi

  # Get gcloud config, and list namespaces
  #gcloud container clusters get-credentials $cluster --region=$region
  printf "\nAvailable Namespaces..."
  kubectl get `ns`

}