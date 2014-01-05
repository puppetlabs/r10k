module SystemProvisioning
  module EL
    def install_epel_release
      rpm_install(
        'epel-release',
        'http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm'
      )
    end

    def install_puppetlabs_release
      rpm_install(
        'puppetlabs-release',
      'http://yum.puppetlabs.com/puppetlabs-release-el-5.noarch.rpm'
      )
    end

    def yum_install(*pkgs)
      pkgs = Array(*pkgs)

      pkgs.each do |pkg|

        check_cmd = shell "rpm -q --filesbypkg #{pkg}"
        if check_cmd.exit_code != 0
          shell "yum -y install #{pkg}"
        end
      end
    end

    def rpm_install(name, install_name = nil)
      install_name ||= name

      check_cmd = shell "rpm -q --filesbypkg #{name}"
      if check_cmd.exit_code != 0
        shell "rpm -Uvh #{install_name}"
      end
    end
  end
end
