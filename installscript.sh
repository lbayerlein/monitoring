#!/bin/bash
# Version 1.0
# nagios, nagiosplugins, pnp4nagios, snmp, rrdtool, checkmk

#Variables
packages="rrdtool nagios pnp4nagios nagios-plugins-all mod_python httpd xinetd wget gcc gcc-c++ make ajenti"
nagioscommands=/etc/nagios/objects/commands.cfg
checkmk=http://mathias-kettner.de/download/check_mk-1.2.4p5.tar.gz
checkmkagent=http://mathias-kettner.de/download/check_mk-agent-1.2.4p5-1.noarch.rpm
dir=`pwd`
whoami=`whoami`
nolog='>/dev/null'

#areyouroot?
if [ $whoami != root ]; then
	echo "Do it with sudo or with root :P "
	echo "byebye"
	exit
fi
echo -ne 'Begin install\r\n'
echo -ne '#                                              (0%)\r'


#New Repos
echo -ne 'Installing repositories\r\n'
echo -ne '#####                                         (10%)\r'
rpm -i --quiet https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm $nolog
rpm -i --quiet http://repo.ajenti.org/ajenti-repo-1.0-1.noarch.rpm  $nolog

#Install Packages
echo -ne 'Installing new packages\r\n'
echo -ne '######                                        (12%)\r'
yum install $packages -q -y -y $nolog

#Services
echo -ne 'Configure services\r\n'
echo -ne '#############                                 (24%)\r'
chkconfig nagios on
chkconfig httpd on
chkconfig xinetd on
chkconfig ajenti on
chkconfig iptables off
service nagios start
service httpd start
service ajenti start
service iptables stop

echo -ne 'Disable SELinux\r\n'
echo -ne '###############                               (36%)\r'
sed -i 's/enforcing/disabled/g' /etc/selinux/config
setenforce 0

#Install cmk
echo -ne 'Installing check mk\r\n'
echo -ne '######################                        (48%)\r'
rpm -ivh $checkmkagent $nolog
wget $checkmk $nolog
tar xvzf check_mk* $nolog
$dir/check*/setup.sh --yes $nolog


#Nagios settings
echo -ne 'Configure nagios\r\n'
echo -ne '###########################                   (60%)\r'
sed -i -n -e :a -e '1,13!{P;N;D;};N;ba' $nagioscommands
echo "define command{
        command_name    process-host-perfdata
        command_line    /usr/bin/perl /usr/libexec/pnp4nagios/process_perfdata.pl -d HOSTPERFDATA
        }


# 'process-service-perfdata' command definition
define command{
        command_name    process-service-perfdata
        command_line    /usr/bin/perl /usr/libexec/pnp4nagios/process_perfdata.pl
        }
" >> $nagioscommands

#sed -i 'g/cfg_file=\/etc\/nagios\/objects\/localhost.cfg/#cfg_file=\/etc\/nagios\/objects\/localhost.cfg' /etc/nagios/nagios.cfg
sed -i 's/livestatus.o/check_mk\/livestatus.o pnp_path=\/var\/lib\/pnp4nagios\//g' /etc/nagios/nagios.cfg
echo -ne 'Restarting services\r\n'
echo -ne '###################################           (72%)\r'
service nagios restart $nolog
service https restart $nolog

echo -ne 'Setting logrotating\r\n'
echo -ne '#########################################     (84%)\r'
echo "
/var/log/nagios*log {
	weekly
	rotate 2
	compress
	missingok
}
" > /etc/logrotate.d/nagios

#Nagvis still not implemented
echo -ne 'Nagvis still not implemented\r\n'
echo -ne '##########################################    (96%)\r'

#Finish
echo -ne 'Finished\r\n'
echo -ne '############################################ (100%)\r'
echo "
#################################################
#### Finished installation
#################################################
###
## You can now go to following urls to start
## * http://HOST/nagios
## * http://HOST/pnp4nagios
## * http://HOST/check_mk
## * https://HOST:8000
##
###
## The user for Nagios is: nagiosadmin/nagiosadmin
###
## The user for ajenti is: root/admin
###
################################################# "
