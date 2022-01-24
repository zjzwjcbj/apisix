local core     = require("apisix.core")
local json     = require("apisix.core.json")
local http     = require("resty.http")
local ck       = require("resty.cookie")
local plugin_name = "cas-auth"

local schema = {
    type = "object",
    properties = {
        content = {
            type = "string" }
    }
}

local _M = {
    version = 0.1,
    priority = 2600,
    name = plugin_name,
    schema = schema,
}

local function http_req(method, uri, body, myheaders, timeout)
    local httpc = http.new()
    if timeout then
        httpc:set_timeout(timeout)
    end

    local params = {method = method, headers = myheaders, body = body,
                    ssl_verify = false}
    local res, err = httpc:request_uri(uri, params)
    if err then
        core.log.error("FAIL REQUEST [ ",core.json.delay_encode(
                {method = method, uri = uri, body = body, headers = myheaders}),
                " ] failed! res is nil, err:", err)
        return nil, err
    end
    return res
end

function _M.rewrite(conf, ctx)
    local token = core.request.header(ctx, "Access-Token")
    core.log.warn("token:",token, "\n")
    if not token then
        local cookie, errCookie = ck:new()
        if errCookie then
            return 401, {code = 400, message = "获取Cookie失败:"..errCookie}
        end
        if not cookie then
            return 401, {code = 400, message = "没有cookie"}
        end
        token = cookie:get("access_token")
        if not token then
            return 401, {code = 401, message = "请先登录"}
        end
    end
    core.log.warn("token:",token, "\n")
    local uri = "test"
    core.log.warn("check cas uri:",uri, "\n")
    local timeout = 1000 * 2
    local res,err = http_req("GET", uri, nil, nil, timeout)
    if err then
        core.log.error("fail request: ", uri, ", err:", err)
        return 401, {code = 500, message = "fail request: "..uri..", err:"..err.."\n"}
    end
    local body, errBody = json.decode(res.body)
    if errBody then
        local errmsg = 'check permission failed! parse response json failed!'
        core.log.error( "json.decode(", res.body, ") failed! err:", errBody, "\n")
        return 401, {message = errmsg}
    end
    core.log.warn("check permission request:", uri, ", status:", res.status,
            ",body:", core.json.delay_encode(res.body), "\n")
    core.log.warn("code:",body["code"],",result:",body["resultMessage"],"\n")
    if body["code"] ~= 200 then
        return 401, {code=body["code"],message = body["resultMessage"]}
    end
end

return _M
