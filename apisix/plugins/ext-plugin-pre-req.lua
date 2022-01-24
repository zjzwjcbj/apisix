--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
local core = require("apisix.core")
local ext = require("apisix.plugins.ext-plugin.init")
local log          = require("apisix.core.log")


local name = "ext-plugin-pre-req"
local _M = {
    version = 0.1,
    priority = 12000,
    name = name,
    schema = ext.schema,
}


function _M.check_schema(conf)
    return core.schema.check(_M.schema, conf)
end


function _M.rewrite(conf, ctx)
    ngx.update_time()
    log.warn("luaStart-------"..ngx.now())
    core.request.set_header(ctx, "lua-start", ngx.now())
    local code = ext.communicate(conf, ctx, name)
    local s = core.request.header(ctx,"java-end")
    log.warn("javaEnd-----"..s)
    ngx.update_time()
    local luaend = ngx.now()
    log.warn("luaend-------"..luaend)
    local lauEnd = ngx.re.sub(luaend,"\\.","")
    log.warn("luaEnd-------"..lauEnd)
    local endRPCCos = lauEnd - s
    log.warn("endRPCCos---"..endRPCCos)
    return code
end


return _M
