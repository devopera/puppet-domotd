define domotd::register(
  $content = $name,
  $order = 10,
  $motd = '/etc/motd',
  $append = ' ',
) {

  # add content directly to /etc/motd
  if defined(Concat["${motd}"]) {
    # add fragment to target file
    concat::fragment{"motd_fragment_$name":
      target  => $motd,
      content => "${content}${append}",
      order => $order,
    }
  }

  # also add content to /etc/motd.template
  if defined(Concat["${motd}.template"]) {
    concat::fragment{"motd_fragment_template_$name":
      target  => "${motd}.template",
      content => "${content}${append}",
      order => $order,
    }
  }

}

