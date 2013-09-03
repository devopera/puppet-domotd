#
# require concat
#
class domotd (
  # true for the machine to substitute (most) parameters on login
  $use_dynamics = false,
  # @todo move to params
  $motd = '/etc/motd',
  $issue = '/etc/issue',
  $script_exec_directory = '/etc/rc.local',
) {

  # setup the motd and issue files for concatenation
  concat{ "${motd}" :
    owner => root,
    group => root,
    mode  => '0644',
  }
  concat{ "${issue}" :
    owner => root,
    group => root,
    mode  => '0644',
  }

  # store current date and time
  $date = inline_template('<%=Time.now.strftime("%H:%M on %Y-%m-%d")%>')

  # create static motd using general and custom facts
  concat::fragment{"motd_header":
    target    => $motd,
    content   => "----${::hostname}------------------------------------------\n${::processorcount} cores, ${::memorytotal} RAM, ${::operatingsystem} ${::operatingsystemrelease}, ${::environment} environment\n${::fqdn} ${::ipaddress} [${::macaddress}]\nConfigured at ${date} with profile: ${::server_profile}\nAvailable services: ",
    order     => 01,
  }
  concat::fragment{"motd_footer":
    target    => $motd,
    content   => "\n----${::hostname}------------------------ devopera.com ----\n",
    order     => 98,
  }
  # create static issue using general facts and issue substitution (\r,\m)
  concat::fragment{"issue_header":
    target    => $issue,
    content   => "${::operatingsystem} release ${::operatingsystemrelease}\nKernel \\r on an \\m\neth IP ${::ipaddress} [${::macaddress}]\n\n",
    order     => 01,
  }

  # dynamically update motd/issue using rc.local
  if $use_dynamics {
    # setup the motd and issue template files
    concat{ "${motd}.template" :
      owner => 'root',
      group => 'root',
      mode  => '0644',
    }
    concat{ "${issue}.template" :
      owner => 'root',
      group => 'root',
      mode  => '0644',
    }
    # write message to templates using partial substitution
    concat::fragment { 'motd_template_header' :
      target  => "${motd}.template",
      # note only partial substitution (% = dynamic, $ = 'static')
      content => "----%{::hostname}------------------------------------------\n%{::processorcount} cores, %{::memorytotal} RAM, %{::operatingsystem} %{::operatingsystemrelease}, ${::environment} environment\n%{::fqdn} %{::ipaddress} [%{::macaddress}]\nConfigured at ${date} with profile: ${::server_profile}\nAvailable services: ",
      order   => 01,
    }
    concat::fragment { 'motd_template_footer' :
      target  => "${motd}.template",
      content => "\n----%{::hostname}------------------------ devopera.com --(d\n",
      order   => 98,
    }
    concat::fragment{"issue_template_header":
      target    => "${issue}.template",
      content   => "${::operatingsystem} release ${::operatingsystemrelease}\nKernel \\r on an \\m\neth IP %{::ipaddress} [%{::macaddress}]\n\n",
      order     => 01,
    }
    
    # check that rc.local is setup the right way
    file {'/etc/rc.local':
      ensure => symlink,
      target => '/etc/rc.d/rc.local',
      owner => 'root',
      group => 'root',
      mode  => '0777',
    }
    # setup rc.local for concat'ing bits onto the end
    concat{ '/etc/rc.d/rc.local' :
      owner => root,
      group => root,
      mode  => '0755',
    }
    # create a basic standard rc.local file
    concat::fragment { "concat_motd_initial_rc" :
      target  => '/etc/rc.d/rc.local',
      source => 'puppet:///modules/domotd/rc.local',
      order  => 01,
    }
    # add script content rc.local to replace message on machine startup
    concat::fragment { "concat_motd_sh" :
      target  => '/etc/rc.d/rc.local',
      source => 'puppet:///modules/domotd/motd.sh',
      order  => 50,
    }
    # local appends must go to the template to avoid being lost
    $local_input = "${motd}.template"
  } else {
    # no dynamics mean that local input can go straight to motd
    $local_input = "${motd}"
  }

  # local users on the machine can append to motd by just creating
  # /etc/motd.local, which then gets appended to the template and copied
  # into /etc/motd
  concat::fragment{"motd_local":
    target => $local_input,
    ensure  => "/etc/motd.local",
    order   => 15
  }

  # realize all the register calls
  Domotd::Register <| |>

}
