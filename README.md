# AntiDDoS
Automatically scan tcp/udp connections, find bad IPs and ban them with iptables.

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
Please view `ddos.conf`.

You could set `EMAIL_TO` with your email address.
And when there is ip banned, you would recieve an email.
To enable email sending, you should config smtp in your server.

Open config file:

`vi /etc/mail.rc`

Add the following content:

*The `[]` means parameter, you should drop in your config.*
```
set from=[name-to-show@yourserver.com]
set smtp=[smtp.server.net]
set smtp-auth-user=[user name]
set smtp-auth-password=[password]
set smtp-auth=login
```
Save and quit with:

`:wq`