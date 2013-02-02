
# cache facter output for repeat grepping
facter=`facter`

function find_fact {
  echo "$facter" | grep "$1 =>" | tail -n 1 | gawk -F" " ' { print $3; } '
}

eval "sed \
 -e 's/\%{::hostname}/$(find_fact "hostname")/g' \
 -e 's/\%{::processorcount}/$(find_fact "processorcount")/g' \
 -e 's/\%{::memorytotal}/$(find_fact "memorytotal")/g' \
 -e 's/\%{::operatingsystem}/$(find_fact "operatingsystem")/g' \
 -e 's/\%{::operatingsystemrelease}/$(find_fact "operatingsystemrelease")/g' \
 -e 's/\%{::fqdn}/$(find_fact "fqdn")/g' \
 -e 's/\%{::ipaddress}/$(find_fact "ipaddress")/g' \
 -e 's/\%{::macaddress}/$(find_fact "macaddress")/g' \
 /etc/motd.template > /etc/motd"