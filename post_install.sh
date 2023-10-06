#!/bin/sh -x
IP_ADDRESS=$(ifconfig | grep -E 'inet.[0-9]' | grep -v '127.0.0.1' | awk '{ print $2}')
KEY=$(openssl rand -base64 20 | md5 | head -c16)$(openssl rand -base64 20 | md5 | head -c16)

#SearXNG user
pw useradd -n searxng -c "SearXNG Search Engine" -d /usr/home/searxng -m

su searxng -c 'cd /usr/home/searxng && git clone --branch plugin https://github.com/SumGuyV5/searxng.git ~/src && python -m venv ~/venv'

su searxng -c 'cd ~/ && . ~/venv/bin/activate && pip install -U pip setuptools wheel pyyaml && cd ~/src && pip install -e .'

sed -i.bak "s/ultrasecretkey/${KEY}/g" /usr/home/searxng/src/searx/settings.yml
sed -i.bak 's/127.0.0.1/0.0.0.0/g' /usr/home/searxng/src/searx/settings.yml

cat > /usr/local/etc/rc.d/searxng <<EOF
#!/bin/sh

# PROVIDE: searxng
# REQUIRE: DAEMON NETWORKING
# BEFORE: LOGIN
# KEYWORD: shutdown

# Add the following lines to /etc/rc.conf to enable searxng:
# searxng_enable="YES"
#
# searxng_enable (bool):	Set to YES to enable searx
#				Default: NO
# searxng_conf (str):		searx configuration file
#				Default: ${PREFIX}/etc/searx.conf
# searxng_user (str):		searx daemon user
#				Default: searx
# searxng_group (str):		searx daemon group
#				Default: searx
# searxng_flags (str):		Extra flags passed to searx

. /etc/rc.subr

name="searxng"
rcvar=searxng_enable

: \${searxng_enable:="NO"}
: \${searxng_user:="searxng"}
: \${searxng_group:="searxng"}
: \${searxng_flags:=""}

# daemon
pidfile="/var/run/\${name}.pid"
python="/usr/home/searxng/venv/bin/python"
script_py="/usr/home/searxng/src/searx/webapp.py"
command=/usr/sbin/daemon
procname="daemon"
command_args=" -c -f -P \${pidfile} \${python} \${script_py}"
start_precmd="searxng_precmd"

searxng_precmd()
{
    install -o \${searxng_user} /dev/null \${pidfile}
}

load_rc_config \$name
run_rc_command "\$1"
EOF

chmod 555 /usr/local/etc/rc.d/searxng

sysrc searxng_enable="YES"
service searxng start

echo -e "SearXNG now installed.\n" > /root/PLUGIN_INFO
echo -e "\nPlease open your web browser and go to http://${IP_ADDRESS}:8888 to configure searxng\n" >> /root/PLUGIN_INFO