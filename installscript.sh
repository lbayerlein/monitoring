#!/bin/bash
# Version 1.0
# nagios, nagiosplugins, pnp4nagios, snmp, rrdtool, checkmk

#Variables
packages="rrdtool nagios pnp4nagios nagios-plugins-all mod_python httpd xinetd wget"
nagioscommands=/etc/nagios/objects/commands.cfg
checkmk=http://mathias-kettner.de/download/check_mk-1.2.4p5.tar.gz
checkmkagent=http://mathias-kettner.de/download/check_mk-agent-1.2.4p5-1.noarch.rpm
dir=`pwd`
whoami=`whoami`

#areyouroot?
if [ $whoami != root ]; then
	echo "Do it with sudo or with root :P "
	echo "byebye"
	exit
fi


#New Repos
rpm -ivh https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

#Install Packages
yum install $packages -y -y

#Services
chkconfig nagios on
chkconfig httpd on
chkconfig xinetd on
service nagios start
service httpd start

#Install cmk
rpm -ivh $checkmkagent
wget $checkmk
tar xvzf check_mk*
$dir/check*/setup.sh --yes


#Nagios settings
sed -i -n -e :a -e '1,10!{P;N;D;};N;ba' $nagioscommands
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

sed -i 'g/cfg_file=\/etc\/nagios\/objects\/localhost.cfg/#cfg_file=\/etc\/nagios\/objects\/localhost.cfg' /etc/nagios/nagios.cfg
service nagios restart


