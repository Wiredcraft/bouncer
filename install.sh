#!/bin/bash

GHK_REPO="https://github.com/Wiredcraft/gh_keeper.git"
GHK_ROOT=/opt/ghk
GHK_SCRIPT=${GHK_ROOT}/ghk-server
GHK_DAEMON=/etc/init.d/ghk-server
NODE_BIN=`which node`
NPM_BIN=`which npm`

if [[ ! ${NODE_BIN} ]];then
  echo "Error: node not found in ${PATH}"
  echo "Installation terminated"
  exit 1
fi

if [[ ! ${NPM_BIN} ]];then
  echo "Error: npm not found in ${PATH}"
  echo "Installation terminated"
  exit 1
fi

echo -n "Proxy port - port [80]: "
read PORT
echo -n "Upstream - upstream [127.0.0.1:3000]: "
read UPSTREAM
#echo -n "Redirect url from githu oauth - Redirect[0.0.0.0:80]: "
#read REDIRECT
echo -n "Allowed organizations, separated names by commma - [,]: "
read ORGANIZATIONS

# Apply defauts
if [[ -z "$PORT" ]]; then
  PORT=80
fi
if [[ -z "$UPSTREAM" ]]; then
  UPSTREAM=127.0.0.1:3000
else
  UPSTREAM=`echo $UPSTREAM | sed -e "s/http:\/\///gi"`
fi
if [[ -z "$REDIRECT" ]]; then
  REDIRECT=0.0.0.0:80
else
  REDIRECT=`echo $REDIRECT | sed -e "s/http:\/\///gi"`
fi
if [[ -z "$ORGANIZATIONS" ]]; then
  echo "You need to specify some orgs. Exiting..."
  exit 1
fi

# if [ ! -d ${GHK_ROOT}/.git ];then
#   echo "Fetching ghk-server code"
#   git clone ${GHK_REPO} ${GHK_ROOT}
# else
#   echo "Updating ghk-server code"
#   cd ${GHK_ROOT}
#   git pull
# fi

# echo "Setting up API auto-health script"
# cat > /etc/cron.d/ghk-server-health << EOF
# # Simple health script that attempts to connect to the API and restart it on failure
# * * * * * root curl --fail http://$USER:$PASS@localhost:$PORT/api > /dev/null 2>&1 || (logger "restarting ghk-server"  && service ghk-server restart)
# EOF

echo "Preparing init script"
echo $UPSTREAM
cp ${GHK_SCRIPT} ${GHK_DAEMON}
sed -i "s/PROXY_PORT/$PORT/g; s/PROXY_UPSTREAM/http:\/\/${UPSTREAM}/g; s/PROXY_ORGANIZATIONS/$ORGANIZATIONS/g" ${GHK_DAEMON}
#sed -i "s/PROXY_PORT/$PORT/g; s/PROXY_UPSTREAM/http:\/\/${UPSTREAM}/g; s/PROXY_REDIRECT_URL/http:\/\/${REDIRECT}/g; s/PROXY_ORGANIZATIONS/$ORGANIZATIONS/g" ${GHK_DAEMON}
echo "Run [sudo] service ghk-server [re]start"
