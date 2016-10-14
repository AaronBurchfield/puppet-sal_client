class sal_client::install {
  $version = $sal_client::version

  $install_dir = "${facts['puppet_vardir']}/repos/sal-scripts"

  $directories = [
    '/usr/local/sal',
    '/usr/local/munki',
    "${facts['puppet_vardir']}/repos"
  ]

  $directories.each | String $directory | {
    if !defined(File[$directory]){
      file { $directory:
        ensure  => directory,
        owner   => 0,
        group   => 0,
        recurse => true,
      }
    }
  }

  vcsrepo { $install_dir:
    ensure   => present,
    provider => git,
    remote   => 'origin',
    force    => true,
    source   => 'https://github.com/salopensource/sal-scripts.git',
    revision => $version,
    require  => File["${facts['puppet_vardir']}/repos"]
  }

  # Alright, let's copy everything where it needs to go

  $copy_files = [
    # ['source', 'destination', 'mode', 'recurse']
    ["${install_dir}/yaml", '/usr/local/sal/yaml', '0755', true, directory],
    ["${install_dir}/utils.py", '/usr/local/sal/utils.py', '0755', false, file],
    ["${install_dir}/postflight", '/usr/local/munki/postflight', '0755', false, file],
    ["${install_dir}/preflight", '/usr/local/munki/preflight', '0755', false, file],
    ["${install_dir}/preflight.d", '/usr/local/munki/preflight.d', '0755', true, directory],
    ["${install_dir}/postflight.d", '/usr/local/munki/postflight.d', '0755', true, directory],
  ]

  $copy_files.each | Array $copy_file | {
    $source      = $copy_file[0]
    $destination = $copy_file[1]
    $mode        = $copy_file[2]
    $recurse     = $copy_file[3]
    $ensure      = $copy_file[4]

    file {$destination:
      ensure  => $ensure,
      source  => $source,
      mode    => $mode,
      recurse => $recurse,
      purge   => $recurse,
      owner   => 0,
      group   => 0,
      require => Vcsrepo[$install_dir],
      ignore  => '*.pyc',
    }
  }


}