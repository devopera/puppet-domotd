class domotd::params {

  $use_dynamics = false
  $issue = '/etc/issue'
  $issue_template = '/etc/issue.template'

  case $operatingsystem {
    centos, redhat, fedora: {
      $motd = '/etc/motd'
      $motd_template = '/etc/motd.template'
      $rc_local_target = '/etc/rc.d/rc.local'
      $update_motd_target = undef
    }
    ubuntu, debian: {
      $motd = '/etc/puppet/tmp/domotd-motd'
      $motd_template = '/etc/puppet/tmp/domotd-motd.template'
      $rc_local_target = '/etc/rc.local'
      $update_motd_target = '/etc/update-motd.d/15-devopera-motd'
    }
  }

}
