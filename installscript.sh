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

#areyouroot?
if [ $whoami != root ]; then
	echo "Do it with sudo or with root :P "
	echo "byebye"
	exit
fi


#New Repos
rpm -ivh https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -ivh http://repo.ajenti.org/ajenti-repo-1.0-1.noarch.rpm 

#Install Packages
yum install $packages -y -y

#Services
chkconfig nagios on
chkconfig httpd on
chkconfig xinetd on
chkconfig ajenti on
chkconfig iptables off
service nagios start
service httpd start
service ajenti start
service iptables stop

sed -i 's/enforcing/disabled/g' /etc/selinux/config
setenforce 0

#Install cmk
rpm -ivh $checkmkagent
wget $checkmk
tar xvzf check_mk*
$dir/check*/setup.sh --yes


#Nagios settings
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
service nagios restart


echo "
#################################################
#### Finished installation
#################################################
###
## You can now go to following urls to start
## * http://HOST/nagios
## * http://HOST/pnp4nagios
## * http://HOST/check_mk
## * http://HOST:8000
##
###
## The user for Nagios is: nagiosadmin/nagiosadmin
###
## The user for ajenti is: root/admin
###
################################################# "
