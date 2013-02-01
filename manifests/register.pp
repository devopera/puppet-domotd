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

