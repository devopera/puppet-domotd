#
# require concat
#
class domotd (
  # true for the machine to substitute (most) parameters on login
  $use_dynamics = false,
  # @todo move to params
  $motd = '/etc/motd',
  $script_exec_directory = '/etc/rc.local',
) {

  # setup the motd file for concatenation
  concat{ "${motd}" :
    owner => root,
    group => root,
    mode  => '0644',
  }

  # store current date and time
  $date = inline_template('<%=Time.now.strftime("%H:%M on %Y-%m-%d")%>')

  # create static motd using general and custom facts
  concat::fragment{"motd_header":
    target    => $motd,
    content   => "----${::hostname}------------------------------------------\n${::processorcount} cores, ${::memorytotal} RAM, ${::operatingsystem} ${::operatingsystemrelease}, ${::environment} environment\n${::fqdn} ${::ipaddress} [${::macaddress}]\nConfigured at ${date} with profile: ${::server_profile}\n----${::hostname}------------------------ devopera.com ----\n",
    order     => 01,
  }

  # dynamically update it on login
  if $use_dynamics {
    concat{ "${motd}.template" :
      owner => root,
      group => root,
      mode  => '0644',
    }
    # write message to template
    concat::fragment{"motd_template_header":
      target  => "${motd}.template",
      # note only partial substitution (% = dynamic, $ = 'static')
      content => "----%{::hostname}------------------------------------------\n%{::processorcount} cores, %{::memorytotal} RAM, %{::operatingsystem} %{::operatingsystemrelease}, ${::environment} environment\n%{::fqdn} %{::ipaddress} [%{::macaddress}]\nConfigured at ${date} with profile: ${::server_profile}\n----%{::hostname}------------------------ devopera.com ----\n",
      order   => 01,
    }->
    # setup script to replace message on login
    file { "${script_exec_directory}/motd.sh" :
      source => 'puppet:///modules/domotd/motd.sh',
      owner => 'root',
      group => 'root',
      mode => 0644,
    }
  }

  # local users on the machine can append to motd by just creating
  # /etc/motd.local
  concat::fragment{"motd_local":
    target => $motd,
    ensure  => "/etc/motd.local",
    order   => 15
  }
}
