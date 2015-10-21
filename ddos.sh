#!/bin/sh
##############################################################################
# AntiDDoS Bless Your Server
##############################################################################

load_conf()
{
  CONF="/usr/local/ddos/ddos.conf"
  if [ -f "$CONF" ] && [ ! "$CONF" == "" ]; then
    source $CONF
  else
    head
    echo "\$CONF not found."
    exit 1
  fi
}

head()
{
  echo "AntiDDoS Bless Your Server"
  echo "Copyright (C) 2015, Yeezon"
  echo
}

showhelp()
{
  head
  echo 'Usage: ddos.sh [OPTIONS] [N]'
  echo 'N : number of tcp/udp connections (default 150)'
  echo 'OPTIONS:'
  echo '-h | --help: Show this help screen'
  echo '-c | --cron: Create cron job to run this script regularly (default 1 mins)'
}

unbanip()
{
  UNBAN_SCRIPT=`mktemp /tmp/unban.XXXXXXXX`
  TMP_FILE=`mktemp /tmp/unban.XXXXXXXX`
  echo '#!/bin/sh' > $UNBAN_SCRIPT
  echo "sleep $BAN_PERIOD" >> $UNBAN_SCRIPT
  while read line; do
    echo "$IPT -D INPUT -s $line -j DROP" >> $UNBAN_SCRIPT
  done < $TMP_BANNED_IP_LIST
  echo "grep -v --file=$TMP_BANNED_IP_LIST $BANNED_IP_LIST > $TMP_FILE" >> $UNBAN_SCRIPT
  echo "mv $TMP_FILE $BANNED_IP_LIST" >> $UNBAN_SCRIPT
  echo "rm -f $TMP_BANNED_IP_LIST" >> $UNBAN_SCRIPT
  echo "rm -f $UNBAN_SCRIPT" >> $UNBAN_SCRIPT
  echo "rm -f $TMP_FILE" >> $UNBAN_SCRIPT
  . $UNBAN_SCRIPT &
}

add_to_cron()
{
  rm -f $CRON
  sleep 1
  service crond restart
  sleep 1
  echo "SHELL=/bin/sh" > $CRON
  if [ $FREQ -le 2 ]; then
    echo "0-59/$FREQ * * * * root /usr/local/ddos/ddos.sh >/dev/null 2>&1" >> $CRON
  else
    let "START_MINUTE = $RANDOM % ($FREQ - 1)"
    let "START_MINUTE = $START_MINUTE + 1"
    let "END_MINUTE = 60 - $FREQ + $START_MINUTE"
    echo "$START_MINUTE-$END_MINUTE/$FREQ * * * * root /usr/local/ddos/ddos.sh >/dev/null 2>&1" >> $CRON
  fi
  service crond restart
}


load_conf
while [ $1 ]; do
  case $1 in
    '-h' | '--help' | '?' )
      showhelp
      exit
      ;;
    '--cron' | '-c' )
      add_to_cron
      exit
      ;;
     *[0-9]* )
      NO_OF_CONNECTIONS=$1
      ;;
    * )
      showhelp
      exit
      ;;
  esac
  shift
done

containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

REVERSE_IP1=( "10" "224" "225" "226" "227" "228" "229" "230" "231" "231" "234" "235" "236" "237" "238" "239" )
REVERSE_IP2=( "192.168" "172.16" "172.17" "172.18" "172.19" "172.20" "172.21" "172.22" "172.23" "172.24" "172.25" "172.26" "172.27" "172.28" "172.29" "172.30" "172.31" )

ALL_STATE=( "all" "connected" "synchronized" "syn-sent" "syn-recv" "established" "fin-wait-1" "fin-wait-2" "time-wait" "close-wait" "last-ack" "closing" "closed" )

TMP_PREFIX='/tmp/ddos'
TMP_FILE="mktemp $TMP_PREFIX.XXXXXXXX"
BANNED_IP_MAIL=`$TMP_FILE`
TMP_BANNED_IP_LIST=`mktemp /tmp/ban.XXXXXXXX`
echo "Banned the following ip addresses on `date`" > $BANNED_IP_MAIL
echo >> $BANNED_IP_MAIL
BAD_IP_LIST=`$TMP_FILE`

WITH_FILTER=""
MULTI_FILTER=0

if [ -z "$FILTER_STATE" ]; then
  FILTER_STATE="0"
fi
array=(${FILTER_STATE//:/ })
for i in "${!array[@]}"
do
    index=${array[i]}
    if [ $i -eq 0 ]; then
      WITH_FILTER="state ${ALL_STATE[index]}"
    else
      MULTI_FILTER=1
      WITH_FILTER="$WITH_FILTER state ${ALL_STATE[index]}"
    fi
done

ss -ntu $WITH_FILTER | awk 'NR!=1{print $6}' | cut -d: -f1 | sort | uniq -c | sort -nr > $BAD_IP_LIST

cat $BAD_IP_LIST
IP_BAN_NOW=0
while read line; do
  CURR_LINE_CONN=$(echo $line | cut -d" " -f1)
  CURR_LINE_IP=$(echo $line | cut -d" " -f2)
  if ! [[ $CURR_LINE_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]];then
    continue
  fi
  if [ $CURR_LINE_CONN -lt $NO_OF_CONNECTIONS ]; then
    break
  fi
  if [ $IGNORE_DEFAULT_IP -eq 1 ]; then
    if [ $CURR_LINE_IP == "127.0.0.1" ]; then
     continue
    fi
    LOCAL_IP1=$(echo $CURR_LINE_IP | cut -d"." -f1)
    if [[ "${REVERSE_IP1[@]}" =~ "${LOCAL_IP1}" ]]; then
      continue
    fi
    LOCAL_IP2=$(echo $CURR_LINE_IP | cut -d"." -f1,2)
    if [[ "${REVERSE_IP2[@]}" =~ "${LOCAL_IP2}" ]]; then
      continue
    fi
  fi
  IGNORE_BAN=`grep -c $CURR_LINE_IP $IGNORE_IP_LIST`
  if [ $IGNORE_BAN -ge 1 ]; then
    continue
  fi
  IGNORE_BAN1=`grep -c $CURR_LINE_IP $BANNED_IP_LIST`
  if [ $IGNORE_BAN1 -ge 1 ]; then
    continue
  fi
  IP_BAN_NOW=1
  echo "$CURR_LINE_IP with $CURR_LINE_CONN connections" >> $BANNED_IP_MAIL
  echo $CURR_LINE_IP >> $BANNED_IP_LIST
  echo $CURR_LINE_IP >> $TMP_BANNED_IP_LIST
  $IPT -I INPUT -s $CURR_LINE_IP -j DROP

done < $BAD_IP_LIST
if [ $IP_BAN_NOW -eq 1 ]; then
  dt=`date`
  if [ $EMAIL_TO != "" ]; then
    cat $BANNED_IP_MAIL | mail -s "IP addresses banned on $dt" $EMAIL_TO
  fi
  unbanip
else
  # remove empty temp ban ip file
  rm $TMP_BANNED_IP_LIST
fi

rm -f $TMP_PREFIX.*
