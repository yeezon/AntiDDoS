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

# Notify
In `ddos.conf`, fill `EMAIL_TO` with your email address.
And when there is ip banned, you would recieve an email.

To enable email sending, firstly, you should config `mailx` in your server.

Install mailx:

`yum install -y mailx`

Open config file:

`vi /etc/mail.rc`

Add the following content in the end:

*The `[]` means parameter*
```
set from=[name-to-show@yourserver.com]
set smtp=[smtp.server.net]
set smtp-auth-user=[user name]
set smtp-auth-password=[password]
set smtp-auth=login
```
Save and quit with:

`:wq`