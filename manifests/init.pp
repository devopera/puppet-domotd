#
# require concat
#
class domotd {
   $motd = "/etc/motd"

   concat{$motd:
      owner => root,
      group => root,
      mode  => '0644',
   }

   # store current date and time
   $date = inline_template('<%=Time.now.strftime("%H:%M on %Y-%m-%d")%>')

   # create motd using general and custom facts
   concat::fragment{"motd_header":
      target => $motd,
      content => "----${::hostname}------------------------------------------\n${::processorcount} cores, ${::memorytotal} RAM, ${::operatingsystem} ${::operatingsystemrelease}, ${::environment} environment\n${::fqdn} ${::ipaddress} [${::macaddress}]\nConfigured at ${date} with profile: ${::server_profile}\n----${::hostname}------------------------ devopera.com ----\n",
      order   => 01,
   }

   # local users on the machine can append to motd by just creating
   # /etc/motd.local
   concat::fragment{"motd_local":
      target => $motd,
      ensure  => "/etc/motd.local",
      order   => 15
   }
}

define domotd::register(
  $content = $name,
  $order = 10,
) {
  # add fragment to target file
  concat::fragment{"motd_fragment_$name":
    target  => '/etc/motd',
    content => "$content",
  }
}

