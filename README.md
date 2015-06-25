# AntiDDoS
Automaticly scan tcp/udp connections, find bad IPs and ban them with iptables.

# How to use
```
cd /usr/local
wget https://github.com/yeezon/AntiDDoS/archive/master.zip
unzip master.zip
mv AntiDDoS-master/ ddos
cd ddos
chmod +x ddos.sh
./ddos.sh -c
```

# Config
Open `ddos.conf`, edit EMAIL_TO config

Ensure your iptables is running:
service iptables status

Config mail
vi /etc/mail.rc



