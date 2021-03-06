#!/bin/bash

[[ "TRACE" ]] && set -x

: ${REALM:=NODE.DC1.CONSUL}
: ${DOMAIN_REALM:=node.dc1.consul}
: ${KERB_MASTER_KEY:=masterkey}
: ${KERB_ADMIN_USER:=admin}
: ${KERB_ADMIN_PASS:=admin}
: ${SEARCH_DOMAINS:=search.consul node.dc1.consul}

source /etc/consulFunctions.sh

fix_nameserver() {
  cat>/etc/resolv.conf<<EOF
nameserver $NAMESERVER_IP
search $SEARCH_DOMAINS
EOF
}

fix_hostname() {
  sed -i "/^hosts:/ s/ *files dns/ dns files/" /etc/nsswitch.conf
}

create_config() {
  : ${KDC_ADDRESS:=$(hostname -f)}

  cat>/etc/krb5.conf<<EOF
[logging]
 default = FILE:/var/log/kerberos/krb5libs.log
 kdc = FILE:/var/log/kerberos/krb5kdc.log
 admin_server = FILE:/var/log/kerberos/kadmind.log

[libdefaults]
 default_realm = $REALM
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true

[realms]
 $REALM = {
  kdc = $KDC_ADDRESS
  admin_server = $KDC_ADDRESS
 }

[domain_realm]
 .$DOMAIN_REALM = $REALM
 $DOMAIN_REALM = $REALM
EOF
}

create_db() {
  /usr/sbin/kdb5_util -P $KERB_MASTER_KEY -r $REALM create -s
}

start_kdc() {
  mkdir -p /var/log/kerberos

#  systemctl start krb5kdc
#  systemctl start kadmin
  source /etc/sysconfig/krb5kdc
  nohup /usr/sbin/krb5kdc -P /var/run/krb5kdc.pid $KRB5KDC_ARGS &

  source /etc/sysconfig/kadmin
  nohup /usr/sbin/_kadmind -P /var/run/kadmind.pid $KADMIND_ARGS &
  
#  systemctl enable krb5kdc
#  systemctl enable kadmin
}

restart_kdc() {
  systemctl restart krb5kdc
  systemctl restart kadmin
}

create_admin_user() {
  kadmin.local -q "addprinc -pw $KERB_ADMIN_PASS $KERB_ADMIN_USER/admin"
  echo "*/admin@$REALM *" > /var/kerberos/krb5kdc/kadm5.acl
}


main() {
#  fix_nameserver
  fix_hostname

  if [ ! -f /kerberos_initialized ]; then
    mkdir -p /var/log/kerberos
    create_config
    create_db
    create_admin_user
#    start_kdc

    touch /kerberos_initialized
  fi

  if [ ! -f /var/kerberos/krb5kdc/principal ]; then
    while true; do sleep 1000; done
  else
    start_kdc
    sleep 5
    tail -F /var/log/kerberos/krb5kdc.log
  fi
#  tail -f /var/log/kerberos/krb5kdc.log
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
