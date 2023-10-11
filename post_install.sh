#!/bin/sh -x
IP_ADDRESS=$(ifconfig | grep -E 'inet.[0-9]' | grep -v '127.0.0.1' | awk '{ print $2}')
PORT=8001
KEY=$(openssl rand -base64 20 | md5 | head -c16)$(openssl rand -base64 20 | md5 | head -c16)

#SearXNG user
pw useradd -n searxng -c "SearXNG Search Engine" -d /usr/home/searxng -m

su searxng -c 'cd /usr/home/searxng && git clone --branch plugin https://github.com/SumGuyV5/searxng.git ~/src && python -m venv ~/venv'

su searxng -c 'cd ~/ && . ~/venv/bin/activate && pip install -U pip setuptools wheel pyyaml gunicorn && cd ~/src && pip install -e .'

sed -i.bak "s/ultrasecretkey/${KEY}/g" /usr/home/searxng/src/searx/settings.yml
sed -i.bak 's/127.0.0.1/0.0.0.0/g' /usr/home/searxng/src/searx/settings.yml

cat >> /usr/local/etc/supervisord.conf <<EOF
[program:searxng]
user=searxng
directory=/usr/home/searxng/src/searx
command=/usr/home/searxng/venv/bin/gunicorn -w 4 -b 0.0.0.0:${PORT} 'webapp:app' --chdir /usr/home/searxng/src/searx
stdout_logfile=/usr/home/searxng/venv/logs/gunicorn_supervisor.log
stderr = true
environment=LANG=en_US.UTF-8,LC_ALL=en_US.UTF-8
EOF

su searxng -c 'mkdir /usr/home/searxng/venv/logs'

cat > /usr/home/searxng/venv/bin/gunicorn_start <<EOF
#!/bin/sh

NAME="searxng"                                      # Project Name
DIR=/usr/home/searxng/src/searx                      # Project Directory
VENV=/usr/home/searxng/venv
SOCKFILE=/usr/home/searxng/src/searx/run/gunicorn.sock     # Gunicorn Sock File
USER=searxng                                           # Django Project Running under user vagrant
GROUP=searxng                                          # Django Project Running under group vagrant
NUM_WORKERS=3
  
echo "Starting \$NAME as `whoami`"
  
# Activate the virtual environment
cd \$VENV
. ./bin/activate

# Create the run directory if it doesn't exist
RUNDIR=\$(dirname \$SOCKFILE)
test -d \$RUNDIR || mkdir -p \$RUNDIR
  
# Start your Gunicorn
# Programs meant to be run under supervisor should not daemonize themselves (do not use --daemon)
exec ../bin/gunicorn webapp:app \
--name \$NAME \
--workers \$NUM_WORKERS \
--user=\$USER --group=\$GROUP \
--bind=unix:\$SOCKFILE \
--log-level=debug \
--log-file=-
EOF

sysrc supervisord_enable="YES"
service supervisord start

echo -e "SearXNG now installed.\n" > /root/PLUGIN_INFO
echo -e "\nPlease open your web browser and go to http://${IP_ADDRESS}:${PORT} to configure searxng\n" >> /root/PLUGIN_INFO