#!/bin/bash

GHK_REPO="https://github.com/Wiredcraft/bouncer.git"
#GHK_REPO="https://gist.github.com/ab85e25b19a7fe2fc24c.git"
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

#
if [ ! -d ${GHK_ROOT}/.git ];then
  echo "Fetching ghk-server code"
  git clone ${GHK_REPO} ${GHK_ROOT}
else
  echo "Updating ghk-server code"
  cd ${GHK_ROOT}
  git pull
fi

echo -n "Proxy port - port [80]: "
read PORT
echo -n "Upstream - upstream [127.0.0.1:3000]: "
read UPSTREAM
echo -n "Allowed organizations, separated names by commma - [xxx,yyy]: "
read ORGANIZATIONS
echo -n "Oauth client id - [xxx]"
read CLIENT_ID
echo -n "Oauth client secret - [yyy]"
read CLIENT_SECRET
echo -n "Githubt app name - [some app name]"
read APP_NAME


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
if [[ -z "$APP_NAME" ]]; then
  echo "You need to specify app id. Exiting..."
  exit 1
fi
if [[ -z "$CLIENT_ID" ]]; then
  echo "You need to specify client id. Exiting..."
  exit 1
fi
if [[ -z "$CLIENT_SECRET" ]]; then
  echo "You need to specify client secret. Exiting..."
  exit 1
fi

# echo "Setting up API auto-health script"
# cat > /etc/cron.d/ghk-server-health << EOF
# # Simple health script that attempts to connect to the API and restart it on failure
# * * * * * root curl --fail http://$USER:$PASS@localhost:$PORT/api > /dev/null 2>&1 || (logger "restarting ghk-server"  && service ghk-server restart)
# EOF

echo "Preparing init script"
echo $UPSTREAM
cp ${GHK_SCRIPT} ${GHK_DAEMON}
sed -i "s/PROXY_APP_NAME/\"$APP_NAME\"/g; s/PROXY_CLIENT_ID/$CLIENT_ID/g; s/PROXY_CLIENT_SECRET/$CLIENT_SECRET/g; s/PROXY_PORT/$PORT/g; s/PROXY_UPSTREAM/http:\/\/${UPSTREAM}/g; s/PROXY_ORGANIZATIONS/$ORGANIZATIONS/g" ${GHK_DAEMON}
echo "Run [sudo] service ghk-server [re]start"
