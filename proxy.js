#!/usr/bin/env node

var info = require('debug')('ghk:proxy:info');
var debug = require('debug')('ghk:proxy:debug');

var url = require('url');
var util = require('util');
var http = require('http');
var path = require('path');

var request = require('request');
var httpProxy = require('http-proxy');
var connect = require('connect');
var cookies = require('cookies');
var bodyParser = require('body-parser');

var proxy = httpProxy.createProxyServer({});
var config = require(path.resolve(__dirname, 'config.json'));

//
var appName = process.env.GHK_APP_NAME;
var oauthClientId = process.env.GHK_CLIENT_ID;
var oauthClientSecret = process.env.GHK_CLIENT_SECRET;
var port = process.env.GHK_PORT || 80;
var upstream = process.env.GHK_UPSTREAM || 'http://127.0.0.1:3000';
var organizations = process.env.GHK_ORGANIZATIONS ? process.env.GHK_ORGANIZATIONS.split(',') : [];

//
var cachedTokens = [];
/*
 * Function
 */
//
function grantAccessToken(code, callback) {
    return request({uri: config.GHAcessTokenURL,
            method: "POST",
            form: {
                client_id: oauthClientId,
                client_secret: oauthClientSecret,
                scope: config.GHOAuthScope,
                code: code
            },
            headers: {
                "Accept": "application/json"
            }
    }, callback);
}

//
function getOrgs(token, callback) {
    return request({
        uri: config.GHUserOrgsURL,
        method: "GET",
        headers: {
            "User-Agent": appName,
            "Authorization": "token " + token
        }}, callback);
}

//
function isStranger(orgs) {
    var stranger = true;

    //
    orgs.forEach(function(org) {
        var login = org.login.toLowerCase();

        //
        if (organizations.indexOf(login) > -1) {
            stranger = false;
        }
    });

    return stranger;
}


//
var app = connect()
  .use(bodyParser())
  .use(connect.query())
  .use(cookies.express([config.secret]))
  .use(function(req, res, next){
    info("Request headers: %j", req.headers);
    var code = req.query.code;
    var token = req.cookies.get(config.cookieName, {signed: true});
    var authURL = config.GHAuthURL + '?client_id=' + oauthClientId + "&scope=" + config.GHOAuthScope;

    if (!code && !token) {
        info("Request have not code neither token");
        res.writeHead(302, {'Location': authURL});
        return res.end();
    } else if (token) {
        info("Request token: %s", token);
        if (cachedTokens.indexOf(token) > -1) {
            info("Fount token: %s in cached tokens", token);
            return proxy.web(req, res, {target:upstream});
        } else {
            info("Token: %s not in cached tokens", token);

            getOrgs(token, function(err, data) {
                info("Github response status code: %s", data.statusCode);

                if (data.statusCode !== 200) {
                    info("The token: %s is not valid any more", token);
                    res.cookies.set(config.cookieName, "");
                    res.writeHead(302, {'Location': authURL});
                    return res.end();
                } else {

                    var body = JSON.parse(data.body);
                    if (isStranger(body)) {
                        info("Token %s is a stranger's token", token);
                        res.writeHead(403, {});
                        return res.end(util.format("Sorry you are not member of any of those orgs: %s", organizations.join(',')));
                    } else {
                        cachedTokens.push(token);
                        info("Token %s is not a stranger's token", token);
                        return proxy.web(req, res, {target:upstream});
                    }
                }
            });
        }
    } else if (code) {
        grantAccessToken(code, function(err, data) {
            info("Github response status code: %s", data.statusCode);
            var body = JSON.parse(data.body);

            if (!body.access_token) {
                res.writeHead(401, {});
                return res.end(util.format("The code %s in your url query is not valid any more, please remove it, and try again", code));
            } else {
                //
                res.cookies.set(config.cookieName, body.access_token, config.cookieOpts);

                getOrgs(body.access_token, function(err, data) {
                    info("User's orgs: %j", data.body);

                    var body = JSON.parse(data.body);

                    if (isStranger(body)) {
                        res.writeHead(403, {});
                        return res.end(util.format("Sorry you are not member of any of those orgs: %s", organizations.join(',')));
                    } else {
                        cachedTokens.push(body.access_token);
                        return proxy.web(req, res, {target:upstream});
                    }
                });
            }
        });
    }
});

//
http.createServer(app).listen(port, function(err) {
 if (err) return debug(err.message || err);
    info("App name: %s", appName);
    info("Client id: %s", oauthClientId);
    info("Client secret: %s", oauthClientSecret);
    info("Cookie secret: %s", config.secret);
    info('Proxy server listening on port %d', port);
    info('Proxy to upstream: %s', upstream);
    info('Allow those who are members of %j go through', organizations);
});
