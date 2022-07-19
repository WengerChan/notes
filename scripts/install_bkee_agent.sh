#! /usr/bin/env bash

LC_ALL=C

[ -d /tmp/agents ] || mkdir -p /tmp/agents
curl -o  /tmp/agents/agent_setup_pro.sh http://10.150.45.215:80/download/agent_setup_pro.sh
chmod a+x /tmp/agents/agent_setup_pro.sh
/tmp/agents/agent_setup_pro.sh -m client -g 10.150.45.215:80 -e 10.137.13.32 -I 0
rm /tmp/agents -rf