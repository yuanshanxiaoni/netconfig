#!/bin/bash - 
#===============================================================================
#
#          FILE:  ddnetcfg.sh
# 
#         USAGE:  ./ddnetcfg.sh 
# 
#   DESCRIPTION:  配置网络
# 
#       OPTIONS:  /ip/route/dns
#  REQUIREMENTS:  centos
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  poorNigga
#       COMPANY:  
#       CREATED:  2011年04月12日 09时51分07秒 CST
#      REVISION:  0.1
#===============================================================================
set -o nounset                              # Treat unset variables as an error

### default eth
ddev="eth3"

### dns config file
dnscfgfile="/etc/resolv.conf"

### ifcfg-ethx config file path
vpath="/etc/sysconfig/network-scripts"


#===  FUNCTION  ================================================================
#          NAME:  usage
#   DESCRIPTION:  script usage info
#    PARAMETERS:  none
#       RETURNS:  none
#===============================================================================
usage () {
    echo -ne "\n\tUsage :\n"
    echo -ne "\n\tddnetcfg  [ip|route|dns|show|delete]  ...\n"
    echo -ne "\n\t\t ddnetcfg  ip            ip_addr  net_mask \n"
    echo -ne "\n\t\t ddnetcfg  gateway|gw    gw_addr\n"
    echo -ne "\n\t\t ddnetcfg  dns           dns_addr1  dns_addr2\n"
    echo -ne "\n\t\t ddnetcfg  show|ls       ip|gateway|dns1|dns2\n"
    echo -ne "\n\t\t ddnetcfg  delete|del    gateway|dns1|dns2\n\n"
}

#===  FUNCTION  ================================================================
#          NAME:  show_usage
#   DESCRIPTION:  function show_usage
#    PARAMETERS:  none
#       RETURNS:  none
#===============================================================================
show_usage () {
    echo -ne "\n\tUsage :\n"
    echo -ne "\n\tddnetcfg  show|ls  [ip|gateway|dns1|dns2]\n"
    echo -ne "\n\t\t ddnetcfg  show|ls   ip\n"
    echo -ne "\n\t\t ddnetcfg  show|ls   gateway|gw\n"
    echo -ne "\n\t\t ddnetcfg  show|ls   dns1\n"
    echo -ne "\n\t\t ddnetcfg  show|ls   dns2\n\n"
}

#===  FUNCTION  ================================================================
#          NAME:  delete_usage
#   DESCRIPTION:  function delete_usage
#    PARAMETERS:  none
#       RETURNS:  none
#===============================================================================
delete_usage () {
    echo -ne "\n\tUsage :\n"
    echo -ne "\n\tddnetcfg  delete|del   [gateway|dns1|dns2]  ...\n"
    echo -ne "\n\t\t  ddnetcfg  delete|del   gateway|gw   gw_addr\n"
    echo -ne "\n\t\t  ddnetcfg  delete|del   dns1         dns1_addr\n"
    echo -ne "\n\t\t  ddnetcfg  delete|del   dns2         dns2_addr\n\n"
}


########################################################
if [ $# -lt 1 ]; then
    usage;
    exit 1;
fi

selector=$1
case "$selector" in
    #-------------------------------------------------------------------------------
    #  set ip address
    #-------------------------------------------------------------------------------
    "ip") 
    if [ $# -ne 3 ]; then
        echo -ne "\n\tUsage : \n"
        usage | grep "ip_addr"  && echo -ne "\n"
        exit 1;
    fi

    ifconfig $ddev $2 netmask $3 promisc up > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -ne "\nset ip for $ddev faild uing ifconfig\n\n"
        exit 1;
    fi

    if [ ! -f $vpath/ifcfg-$ddev.orig ]; then
        cp "$vpath/ifcfg-$ddev"{,.orig} > /dev/null 2>&1
    fi

    MESG=`head -n1 $vpath/ifcfg-$ddev.orig`
    TEST=`echo $MESG | cut -d' ' -f1`
    if [ ${#TEST} -ne  1 ]; then
        MESG="#####################"
    fi

    HWADDR=`grep "HWADDR=" $vpath/ifcfg-$ddev.orig | cut -d'=' -f2`
    NETWORK=`echo $2 | cut -d'.' -f1-3`

    #-------------------------------------------------------
    #  if not serch default gateway out in route ;
    #  set it as $xxx.xxx.xxx.1
    #-------------------------------------------------------
    GATEWAY=`netstat -nr | grep ^0.0.0.0 | awk '{print $2}'`
    if [ "$GATEWAY" = "" ];  then
        GATEWAY=$NETWORK.1
    fi

    if [ ! -f $vpath/.staticEther.config ]; then
        touch $vpath/.staticEther.config
    fi

### not set gateway ###
cat > $vpath/.staticEther.config << EOF
$MESG
DEVICE=$ddev
HWADDR=$HWADDR
IPADDR=$2
NETMASK=$3
BROADCAST=$NETWORK.255
NETWORK=$NETWORK.0
ONBOOT=yes
USERCTL=no
BOOTPROTO=none
TYPE=Ethernet
EOF

    mv -f $vpath/.staticEther.config $vpath/ifcfg-$ddev > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -ne "recover ifcfg-ethx file error\n" 
        exit 1;
    fi

    ;;
    #-------------------------------------------------------------------------------
    #  set default gateway 
    #-------------------------------------------------------------------------------
    "gateway"|"gw") 
    if [ $# -ne 2 ]; then
        echo -ne "\n\tUsage : \n"
        usage | grep "gw_addr"  && echo -ne "\n"
        exit 1;
    fi
    ip route flash cache > /dev/null 2>&1
    route del default > /dev/null 2>&1
    route add default gw $2 > /dev/null 2>&1 
    if [ $? -ne 0 ]; then
        echo -ne "\nadd default gateway error\n\n"
        exit 1;
    fi

    flags=`echo $2 | cut -d'.' -f1-3`
    cat $vpath/ifcfg-$ddev | grep "$flags" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -ne "be sure set ip first\n\n"
        exit 1;
    fi

    #-------------------------------------------------------
    #  update etc/sysconfig/network-scripts/ifcfg-ethx ;
    #  set route and recover the default route in cfg file ;
    #-------------------------------------------------------
    cat $vpath/ifcfg-$ddev | grep -v "GATEWAY=" > $vpath/route.ifcfg-$ddev
    if [ $? -ne 0 ]; then
        echo -ne "\nwrite route set to ifcfg-ethx config file error\n\n"
    fi

    echo "GATEWAY=$2" >> $vpath/route.ifcfg-$ddev > /dev/null 2>&1
    mv -f $vpath/route.ifcfg-$ddev $vpath/ifcfg-$ddev > /dev/null 2>&1

    ;;
    #-------------------------------------------------------------------------------
    #  set nameserver
    #-------------------------------------------------------------------------------
    "dns") 
    ### if parms less than 3 or more than 4, show usage;
    if [ $# -ne 3 ]; then 
        echo -ne "\n\tUsage : \n"
        usage | grep "dns_addr1"  && echo -ne "\n"
        echo -ne "\t\t set 1 nameserver, another just set with 0. like :\n\n"
        echo -ne "\t\t ddnetcfg dns 0 61.139.2.69\n\n"
        exit 1;
    fi
    ### bak the origal config file;
    if [ ! -f $dnscfgfile.bak ]; then
        cp "$dnscfgfile"{,.bak} > /dev/null  2>&1
    fi

    DNS1="0"
    DNS2="0"
    if [ ${#2} -ne 1 ]; then
        DNS1=$2
    fi
    if [ ${#3} -ne 1 ]; then
        DNS2=$3
    fi

    ### fill tmp file till success, recover config file;
    if [ $DNS1 != "0" ]; then
        echo "nameserver $DNS1" > $dnscfgfile.tmp
    else
        echo "# `cat $dnscfgfile | head -n1`" > $dnscfgfile.tmp
    fi

    if [ $DNS2 != "0" ]; then
        echo "nameserver $DNS2" >> $dnscfgfile.tmp
    else
        echo "# `cat $dnscfgfile | tail -n1`" >> $dnscfgfile.tmp
    fi

    len=`cat $dnscfgfile.tmp | wc -l`
    if [ $len -eq  2 ]; then    ## if write success;
        mv $dnscfgfile.tmp $dnscfgfile > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo -ne "\nrecover dns config file error\n\n"
            exit 1;
        fi
    fi

    ;;
    #-------------------------------------------------------------------------------
    #  show sub-command usage
    #-------------------------------------------------------------------------------
    "show"|"ls")
    if [ $# -ne 2 ];then 
        show_usage;
        exit 1;
    fi
    ctrlor=$2
    case $ctrlor in 
        "ip")
            ipshow=`cat $vpath/ifcfg-$ddev | grep "IPADDR=" | cut -d'=' -f2`
            echo -ne "\nshow ip addr : $ipshow\n\n"
        ;;
        "gw"|"gateway")
            gwshow=0
            cat $vpath/ifcfg-$ddev | grep "GATEWAY=" > /dev/null 2>&1
            if [ $? -eq  0 ]; then
                gwshow=`cat $vpath/ifcfg-$ddev | grep "GATEWAY=" | cut -d'=' -f1`
            else
                gwshow=`netstat -nr | grep ^0.0.0.0 | awk '{ print $2 }'`
            fi
            echo -ne "\nshow gateway addr : $gwshow\n\n"
        ;;
        "dns1")
           dns1show=`cat $dnscfgfile | head -n1 | cut -d' ' -f1`
           if [ ${#dns1show} -ne 1 ]; then
               dns1show=`cat $dnscfgfile | head -n1 | awk '{print $2}'`
           else
               dns1show=0
           fi
            echo -ne "\nshow dns1 addr : $dns1show\n\n"
           
        ;;
        "dns2")
            dns2show=`cat $dnscfgfile | tail -n1 | cut -d' ' -f1`
            if [ ${#dns2show} -ne 1 ]; then
               dns2show=`cat $dnscfgfile | tail -n1 | awk '{print $2}'`
           else
               dns2show=0
            fi
            echo -ne "\nshow dns2 addr : $dns2show\n\n"
        ;;
        *)
            show_usage;
            exit 1;
        ;;
    esac

    ;;
    #-------------------------------------------------------------------------------
    #  delete gw or dns1/dns2
    #-------------------------------------------------------------------------------
    "delete"|"del")
    if [ $# -ne 3 ]; then
        delete_usage;
        exit 1;
    fi
    optaddr=$3
    delor=$2
    case $delor in 
        "gateway"|"gw")
            echo -ne "\ngw = $optaddr\n\n"
            netstat -nr | grep "$optaddr" | grep ^0.0.0.0 > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo -ne "\nwrong gateway address \n\n"
                exit 1;
            fi
            ip route flash cache > /dev/null 2>&1
            route del default > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo -ne "\ndelete default gateway error\n\n"
                exit 1;
            fi
        ;;
        "dns1")
            echo -ne "\ndns1 = $optaddr\n\n"
            DNS1=`cat $dnscfgfile | head -n1 | cut -d' ' -f1`
            if [ ${#DNS1} -eq 1 ]; then
                echo -ne "\ndns1 not be set yet\n\n"
                exit 1;
            fi
            DNS1=`cat $dnscfgfile | head -n1 | awk '{print $2}'`
            if [ $DNS1 != $optaddr ]; then
                echo -ne "\nwrong dns1 address\n\n"
                exit 1;
            fi
            cp $dnscfgfile{,.temp} > /dev/null 2>&1
            echo "# `cat $dnscfgfile | head -n1`" > $dnscfgfile.temp
            echo "`cat $dnscfgfile | tail -n1`" >> $dnscfgfile.temp
            length=`cat $dnscfgfile.temp | wc -l`
            if [ $length  -ne  2 ]; then
                echo -ne "\ncp temp dnsconfigfile error\n\n"
                exit 1;
            fi 
            mv -f $dnscfgfile.temp $dnscfgfile

        ;;
        "dns2")
            echo -ne "\ndns2 = $optaddr\n\n"
            DNS2=`cat $dnscfgfile | tail -n1 | cut -d' ' -f1`
            if [ ${#DNS2} -eq 1 ]; then
                echo -ne "\ndns2 not be set yet\n\n"
                exit 1;
            fi
            DNS2=`cat $dnscfgfile | tail -n1 | awk '{print $2}'`
            if [ $DNS2 != $optaddr ]; then
                echo -ne "\nwrong dns2 address\n\n"
                exit 1;
            fi
            cp $dnscfgfile{,.temp} > /dev/null 2>&1
            echo "`cat $dnscfgfile | head -n1`" > $dnscfgfile.temp
            echo "# `cat $dnscfgfile | tail -n1`" >> $dnscfgfile.temp
            length=`cat $dnscfgfile.temp | wc -l`
            if [ $length  -ne  2 ]; then
                echo -ne "\ncp temp dnsconfigfile error\n\n"
                exit 1;
            fi 
            mv -f $dnscfgfile.temp $dnscfgfile
            if [ $? -ne 0 ]; then
                echo -ne "\nrecover dns config file error\n\n"
                exit 1;
            fi 

        ;;
        *)
            delete_usage;
            exit 1;
        ;;
    esac

    ;;
    #-------------------------------------------------------------------------------
    #  default show usage 
    #-------------------------------------------------------------------------------
    *)
    usage;
    exit 1;
    ;;
esac


#-------------------------------------------------------------------------------
#  success exit
#-------------------------------------------------------------------------------
exit $?

