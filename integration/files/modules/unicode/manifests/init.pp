class unicode {
  file { '/tmp/unicode.file':
    ensure => file,
    source => "puppet:///modules/unicode/굢챣샃뻧븣럩윕컾뾐깩"
  }
}
