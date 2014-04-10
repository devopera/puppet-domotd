#
# requires concat
#
class domotd (

  # by default, don't update motd/issue every restart, only on puppet runs
  $use_dynamics = false,

  # location of motd file (used at login)
  $motd = $domotd::params::motd,
  $motd_template = $domotd::params::motd_template,

  # location of issue file (used at console)
  $issue = $domotd::params::issue,
  $issue_template = $domotd::params::issue_template,

  # location of rc.local, if used to update from template at startup
  $rc_local_target = $domotd::params::rc_local_target,

  # location of update-motd.d/script, if used to build domotd-motd into motd at login
  $update_motd_target = $domotd::params::update_motd_target,

) inherits domotd::params {

  # store current date and time
  $date = inline_template('<%=Time.now.strftime("%H:%M on %Y-%m-%d")%>')

  if ($motd != undef) {
    # setup the motd and issue files for concatenation
    concat{ "${motd}" :
      owner => root,
      group => root,
      mode  => '0644',
    }
    # create static motd using general and custom facts
    concat::fragment{"motd_header":
      target    => $motd,
      content   => "----${::hostname}------------------------------------------\n${::processorcount} cores, ${::memorysize} RAM, ${::operatingsystem} ${::operatingsystemrelease}, ${::environment} environment\n${::fqdn} ${::ipaddress} [${::macaddress}]\nConfigured at ${date} with profile: ${::server_profile}\nAvailable services: ",
      order     => 01,
    }
    concat::fragment{"motd_footer":
      target    => $motd,
      content   => "\n----${::hostname}------------------------ devopera.com ----\n",
      order     => 98,
    }
  }

  # dynamically update motd using a template file and variable substitution
  if ($motd_template != undef) {
    concat{ "${motd_template}" :
      owner => 'root',
      group => 'root',
      mode  => '0644',
    }
    # write message to templates using partial substitution
    concat::fragment { 'motd_template_header' :
      target  => "${motd_template}",
      # note only partial substitution (% = dynamic, $ = 'static')
      content => "----%{::hostname}------------------------------------------\n%{::processorcount} cores, %{::memorysize} RAM, %{::operatingsystem} %{::operatingsystemrelease}, ${::environment} environment\n%{::fqdn} %{::ipaddress} [%{::macaddress}]\nConfigured at ${date} with profile: ${::server_profile}\nAvailable services: ",
      order   => 01,
    }
    concat::fragment { 'motd_template_footer' :
      target  => "${motd_template}",
      content => "\n----%{::hostname}------------------------ devopera.com --(d\n",
      order   => 98,
    }
  }

  if ($issue != undef) {
    concat{ "${issue}" :
      owner => root,
      group => root,
      mode  => '0644',
    }
    # create static issue using general facts and issue substitution (\r,\m)
    concat::fragment{"issue_header":
      target    => $issue,
      content   => "${::operatingsystem} release ${::operatingsystemrelease}\nKernel \\r on an \\m\neth IP ${::ipaddress} [${::macaddress}]\n\n",
      order     => 01,
    }
  }

  if ($issue_template != undef) {
    concat{ "${issue_template}" :
      owner => 'root',
      group => 'root',
      mode  => '0644',
    }
    concat::fragment{"issue_template_header":
      target    => "${issue_template}",
      content   => "${::operatingsystem} release ${::operatingsystemrelease}\nKernel \\r on an \\m\neth IP %{::ipaddress} [%{::macaddress}]\n\n",
      order     => 01,
    }
  }

  case $operatingsystem {
    centos, redhat, fedora: {
      # if we're relying on rc.local
      if (($rc_local_target != undef) and ($use_dynamics)) {
        # check that rc.local is setup as a symlink
        # can't use file resource because it triggers file resource collision
        # file { 'domotd-rc-local-symlink':
        #   ensure => symlink,
        #   path   => '/etc/rc.local',
        #   target => $rc_local_target,
        #   owner  => 'root',
        #   group  => 'root',
        #   mode   => '0777',
        #   before => [Concat['/etc/rc.local']],
        # }
        #
        # create a symlink and overwrite any previous file (if one exists)
        exec { 'domotd-rc-local-clear-old-file':
          path => '/usr/bin:/bin',
          command => 'rm -f /etc/rc.local',
          onlyif => 'bash -c "test -f /etc/rc.local"',
        }->
        # force the symlink, because otherwise we can end up with two different files
        exec { 'domotd-rc-local-symlink':
          path => '/usr/bin:/bin',
          command => "ln -s ${rc_local_target} /etc/rc.local",
          before => [Concat["${rc_local_target}"]],
        }
      }
    }
    ubuntu, debian: {
      # disable some of the redundant parts of the existing motd
      exec { 'domotd-disable-redundants' :
        path => '/usr/bin:/bin',
        command => 'chmod 0644 /etc/update-motd.d/00-header /etc/update-motd.d/10-help-text',
      }
    }
  }

  # if this system allows us to execute things on startup using rc.local
  if (($rc_local_target != undef) and ($use_dynamics)) {
    # setup rc.local for concat'ing bits onto the end
    concat{ "${rc_local_target}" :
      owner => root,
      group => root,
      mode  => '0755',
    }
    # create a basic (standard) rc.local file
    concat::fragment { "concat_motd_initial_rc_local" :
      target  => $rc_local_target,
      source => 'puppet:///modules/domotd/rc.local',
      order   => 01,
    }
    # add commands to update motd and issue from template(s)
    concat::fragment { "concat_motd_template_sh" :
      target  => $rc_local_target,
      content => template('domotd/motd.sh.erb'),
      order   => 50,
    }
  }
  
  # if this system allows us to regenerate motd on login
  if ($update_motd_target != undef) {
    concat{ "${update_motd_target}" :
      owner => root,
      group => root,
      mode  => '0755',
    }
    # add commands to update motd from template(s)
    concat::fragment { "concat_motd_target_sh" :
      target  => "${update_motd_target}",
      content => template('domotd/update-motd.d.erb'),
      order   => 01,
    }
  }

  # realize all the register calls
  Domotd::Register <| |>

}
