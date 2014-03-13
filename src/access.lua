-- certain endpoints are always blocked
--if nginx_uri == "/_access_token" or nginx_uri == "/_me" then
    --ngx.exit(403)
--end

-- import requirements
local io = require "io"
local cjson = require "cjson"
local socket = require "socket"
local http = require  "socket.http"
local ltn12 = require "ltn12"
local pl = require 'pl.pretty'

socket.TIMEOUT = 20
socket.http.TIMEOUT = 20

-- setup some app-level vars
local client_id = "64a87b1316e8a0f2fbb2"
local client_secret = "66b97d961f4499c6095edc67d1af57379151e8c0"
local callback_url = "http://keeper.local"

--
local code = ngx.var.arg_code;
local access_token = ngx.var.cookie_SGAccessToken or ngx.var.arg_access_token
local create = function() local req_sock = socket.tcp() req_sock:settimeout(nil) return req_sock end

if not access_token and not code then
    ngx.redirect("https://github.com/login/oauth/authorize?client_id=" .. client_id)
elseif code then
    --local url = "http://10.0.2.2:4000"
    --local url =  "https://google.com"
    local url = "https://github.com/login/oauth/access_token" 
    local request_body =  "code=" .. code .. "&client_id=" .. client_id .. "&client_secret=" .. client_secret
    local response_body = {}
    --local r, c, h = socket.http.request(url)
    local r, c, h = socket.http.request {
        url = url,
        method = "POST",
        redirect = true,
        headers = {
            ["TE"] = "trailers, deflate",
            --["Host"] = "github.com",
            ["User-Agent"] = "",
            ["Accept"] = "application/json",
            ["Connection"] = "keep-alive",
            ["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8",
            ["Content-Length"] = #request_body
        },
        sink = ltn12.sink.table(response_body)
        ,source = ltn12.source.string(request_body)
        --,create = create
    }

    --ngx.status = ngx.HTTP_UNAUTHORIZED
    --ngx.say({"status:", 401, "message:", url .. request_body})
    ngx.say(r)
    ngx.say(c)
    ngx.say(response_body)
    ngx.exit(401)
elseif ngx.var.arg_access_token then
    ngx.exit(403)
end
-- local args = ngx.req.get_uri_args()
-- if args.error and args.error == "access_denied" then
--     ngx.status = ngx.HTTP_UNAUTHORIZED
--     ngx.say({"status: ", 401, "message: ", ""..args.error_description..""})
--     return ngx.exit(ngx.HTTP_OK)
-- end
--
-- local access_token = ngx.var.cookie_SGAccessToken
-- if access_token then
--         ngx.header["Set-Cookie"] = "SGAccessToken="..access_token.."; path=/;Max-Age=3000"
-- end
--
-- -- first lets check for a code where we retrieve
-- -- credentials from the api
-- if not access_token or args.code then
--     if args.code then
--         -- internal-oauth:1337/access_token
--         local res = ngx.location.capture("/_access_token?client_id="..app_id.."&client_secret="..app_secret.."&code="..args.code)
--
--         -- kill all invalid responses immediately
--         if res.status ~= 200 then
--             ngx.status = res.status
--             ngx.say(res.body)
--             ngx.exit(ngx.HTTP_OK)
--         end
--
--         -- decode the token
--         local text = res.body
--         local json = cjson.decode(text)
--         access_token = json.access_token
--     end
--
--     -- both the cookie and proxy_pass token retrieval failed
--     if not access_token then
--         -- Track the endpoint they wanted access to so we can transparently redirect them back
--         ngx.header["Set-Cookie"] = "SGRedirectBack="..nginx_uri.."; path=/;Max-Age=120"
--
--         -- Redirect to the /oauth endpoint, request access to ALL scopes
--         return ngx.redirect("internal-oauth:1337/oauth?client_id="..app_id.."&scope=all")
--     end
-- end
--
-- -- ensure we have a user with the proper access app-level
-- -- internal-oauth:1337/accessible
-- local res = ngx.location.capture("/_accessible", {args = { access_token = access_token } } )
-- if res.status ~= 200 then
--     -- delete their bad token
--     ngx.header["Set-Cookie"] = "SGAccessToken=deleted; path=/; Expires=Thu, 01-Jan-1970 00:00:01 GMT"
--
--     -- Redirect 403 forbidden back to the oauth endpoint, as their stored token was somehow bad
--     if res.status == 403 then
--         return ngx.redirect("https://seatgeek.com/oauth?client_id="..app_id.."&scope=all")
--     end
--
--     -- Disallow access
--     ngx.status = res.status
--     ngx.say({"status:", 503, "message:", "Error accessing api/me for credentials"})
--     return ngx.exit(ngx.HTTP_OK)
-- end
--
-- local json = cjson.decode(res.body)
-- -- Ensure we have the minimum for access_level to this resource
-- if json.access_level < 255 then
--     -- Expire their stored token
--     ngx.header["Set-Cookie"] = "SGAccessToken=deleted; path=/; Expires=Thu, 01-Jan-1970 00:00:01 GMT"
--
--     -- Disallow access
--     ngx.status = ngx.HTTP_UNAUTHORIZED
--     ngx.say({"status:", 403, "message:", "USER_ID"..json.user_id.." has no access to this resource"})
--     return ngx.exit(ngx.HTTP_OK)
-- end
--
-- -- Store the access_token within a cookie
-- ngx.header["Set-Cookie"] = "SGAccessToken="..access_token.."; path=/;Max-Age=3000"
--
-- -- Support redirection back to your request if necessary
-- local redirect_back = ngx.var.cookie_SGRedirectBack
-- if redirect_back then
--     ngx.header["Set-Cookie"] = "SGRedirectBack=deleted; path=/; Expires=Thu, 01-Jan-1970 00:00:01 GMT"
--     return ngx.redirect(redirect_back)
-- end
--
-- -- Set some headers for use within the protected endpoint
-- ngx.req.set_header("X-USER-ACCESS-LEVEL", json.access_level)
-- ngx.req.set_header("X-USER-EMAIL", json.email)
