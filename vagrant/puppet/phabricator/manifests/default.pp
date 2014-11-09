# Basic Puppet Apache manifest

$apache2_sites = "/etc/apache2/sites"
$apache2_mods  = "/etc/apache2/mods"
$phab_dir      = "/phabricator"
$dev_dir       = "${phab_dir}/instances/dev"
$document_root = "${dev_dir}/phabricator/webroot"
$std_path      = "/usr/bin:/usr/sbin:/bin"
$http_proxy    = ""
$https_proxy    = ""

file { 'apt-proxyconfig' :
  path    => '/etc/apt/apt.conf.d/95proxies',
  ensure  => present,
  content => "Acquire::http::proxy \"${http_proxy}\";",
  notify  => Exec['apt-update'],
}

exec { 'apt-update':
    command     => 'apt-get update',
    refreshonly => true,
    path        => $std_path,
}

class apache2 {

  package { "apache2":
    ensure => present,
  }

   service { "apache2":
      ensure     => running,
      hasstatus  => true,
      hasrestart => true,
      require    => Package["apache2"],
   }

  file { 'vhost':
    path    => '/etc/apache2/conf.d/95-phab.conf',
    ensure  => present,
    content => template("phabricator/vhost.erb"),
    notify  => Service['apache2'],
  }

   define module ( $requires = 'apache2' ) {
        exec { "/usr/sbin/a2enmod ${name}":
           unless  => "/bin/readlink -e ${apache2_mods}-enabled/${name}.load",
           notify  => Service['apache2'],
           require => Package[$requires],
        }
   }
}

class otherpackages {
    $packages = ["git-core", "mysql-server", "php5", "dpkg-dev", "unzip", "vim", "mc", "screen", "bash"]
    $php_packages = ["php5-mysql", "php5-gd", "php5-dev", "php5-curl", "php-apc", "php5-cli"]

    package { $packages: ensure     => installed, }
    package { $php_packages: ensure => installed, }
}

class phabricatordirs {
    # puppet won't create parent directories and will fail if we don't
    # manually specify each of them as separate dependencies
    # it does automatically create them in the correct order though
    file { "/phabricator/instances/dev":
        ensure => directory,
        owner => 'vagrant',
    }
    file { "/phabricator/instances":
        ensure => directory,
    }
    file { "/phabricator":
        ensure => directory,
    }
}

class phabricator {

    define phabgithubunzip ($repo = $title) {
        $proxy_string = "https_proxy=${https_proxy}"
        $github_string = "https://github.com/facebook"
        exec { "git clone ${github_string}/${repo} ${dev_dir}/${repo}":
            path        => $std_path,
            creates     => "${dev_dir}/${repo}",
            environment => $proxy_string,
            require => Package['git-core'],
            user => 'vagrant',
        }
    }

    # set 'commit' to 'master' for the latest version
    phabgithubunzip {'phabricator':}
    phabgithubunzip {'libphutil':}
    phabgithubunzip {'arcanist':
        require => [File["/etc/profile.d/arcanist.sh"],
                    Exec["${dev_dir}/libphutil/scripts/build_xhpast.sh"]],
    }
    
    file { "/etc/profile.d/arcanist.sh":
        ensure => present,
        content => "# expose 'arc' command\nexport PATH=\$PATH:${dev_dir}/arcanist/bin\nsource ${dev_dir}/arcanist/resources/shell/bash-completion\n",
    }
    
    exec { "${dev_dir}/libphutil/scripts/build_xhpast.sh":
      creates => "${dev_dir}/libphutil/support/xhpast/xhpast",
      require => Phabgithubunzip['libphutil'],
    }
}

class phabricatordb {
    file { "initial.db":
	path   => "${phab_dir}/initial.db",
	source => "puppet:///modules/phabricator/initial.db",
	ensure => present,
    }

    exec { "mysql < ${phab_dir}/initial.db && ${dev_dir}/phabricator/bin/storage upgrade --force":
        path    => $std_path,
        unless  => "${dev_dir}/phabricator/bin/storage status",
	require => File["initial.db"],
    }
}

# declare our entities
class {'apache2':}
class {'otherpackages':}
apache2::module { "rewrite": }
class {'phabricatordirs':}
class {'phabricator':}
class {'phabricatordb':}

# declare our dependencies
Class['apache2']       <- File['apt-proxyconfig']
Class['otherpackages'] <- File['apt-proxyconfig']
Class['phabricator']   <- Class['apache2']
Class['phabricator']   <- Class['otherpackages']
Class['phabricator']   <- Class['phabricatordirs']
Class['phabricatordb'] <- Class['phabricator']

file { "/etc/profile.d/usevim.sh":
    ensure => present,
    content => "EDITOR=vim",
}
