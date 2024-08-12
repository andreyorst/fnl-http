--[[ "MIT License

Copyright (c) 2024 Andrey Listopadov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
" ]]
package.preload["http.client"] = package.preload["http.client"] or function(...)
  local _local_1_ = require("socket")
  local gettime = _local_1_["gettime"]
  local _local_486_ = require("lib.async")
  local _3e_21 = _local_486_[">!"]
  local _3c_21 = _local_486_["<!"]
  local _3e_21_21 = _local_486_[">!!"]
  local _3c_21_21 = _local_486_["<!!"]
  local chan_3f = _local_486_["chan?"]
  local _local_504_ = require("http.utils")
  local _3e_21_3f = _local_504_[">!?"]
  local _3c_21_3f = _local_504_["<!?"]
  local make_tcp_client = _local_504_["make-tcp-client"]
  local chunked_encoding_3f = _local_504_["chunked-encoding?"]
  local _local_813_ = require("http.parser")
  local parse_http_response = _local_813_["parse-http-response"]
  local _local_814_ = require("http.url")
  local parse_url = _local_814_["parse-url"]
  local format_path = _local_814_["format-path"]
  local _local_858_ = require("http.tcp")
  local tcp_chan = _local_858_["chan"]
  local _local_859_ = require("lib.async")
  local chan = _local_859_["chan"]
  local _local_860_ = require("http.readers")
  local reader_3f = _local_860_["reader?"]
  local file_reader = _local_860_["file-reader"]
  local _local_861_ = require("http.builder")
  local build_http_request = _local_861_["build-http-request"]
  local _local_862_ = require("http.body")
  local stream_body = _local_862_["stream-body"]
  local format_chunk = _local_862_["format-chunk"]
  local wrap_body = _local_862_["wrap-body"]
  local multipart_content_length = _local_862_["multipart-content-length"]
  local stream_multipart = _local_862_["stream-multipart"]
  local _local_867_ = require("http.uuid")
  local random_uuid = _local_867_["random-uuid"]
  local _local_934_ = require("http.json")
  local decode = _local_934_["decode"]
  local format = string["format"]
  local lower = string["lower"]
  local upper = string["upper"]
  local insert = table["insert"]
  local client = {}
  local function get_boundary(headers)
    local boundary = nil
    for header, value in pairs(headers) do
      if boundary then break end
      if ("content-type" == lower(header)) then
        boundary = value:match("boundary=([^;]+)")
      else
        boundary = nil
      end
    end
    return boundary
  end
  local function prepare_headers(_936_)
    local body = _936_["body"]
    local headers = _936_["headers"]
    local multipart = _936_["multipart"]
    local mime_subtype = _936_["mime-subtype"]
    local _arg_937_ = _936_["url"]
    local host = _arg_937_["host"]
    local port = _arg_937_["port"]
    local headers0
    do
      local tbl_16_auto
      local _938_
      if port then
        _938_ = (":" .. port)
      else
        _938_ = ""
      end
      local _940_
      if (type(body) == "string") then
        _940_ = #body
      elseif reader_3f(body) then
        _940_ = body:length()
      else
        _940_ = nil
      end
      local _943_
      do
        local _942_ = type(body)
        if ((_942_ == "string") or (_942_ == "nil")) then
          _943_ = nil
        else
          local _ = _942_
          _943_ = "chunked"
        end
      end
      local _947_
      if multipart then
        _947_ = ("multipart/" .. (mime_subtype or "form-data") .. "; boundary=------------" .. random_uuid())
      else
        _947_ = nil
      end
      tbl_16_auto = {host = (host .. _938_), ["content-length"] = _940_, ["transfer-encoding"] = _943_, ["content-type"] = _947_}
      for k, v in pairs((headers or {})) do
        local k_17_auto, v_18_auto = k, v
        if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
          tbl_16_auto[k_17_auto] = v_18_auto
        else
        end
      end
      headers0 = tbl_16_auto
    end
    local headers1
    if multipart then
      headers0["content-length"] = multipart_content_length(multipart, get_boundary(headers0, headers0))
      headers1 = headers0
    else
      headers1 = headers0
    end
    if (not multipart and chan_3f(body)) then
      headers1["content-length"] = nil
      headers1["transfer-encoding"] = "chunked"
      return headers1
    elseif (not multipart and reader_3f(body) and headers1["content-length"]) then
      headers1["transfer-encoding"] = nil
      return headers1
    else
      return headers1
    end
  end
  local function make_tcp_client_2a(opts)
    local _952_ = opts["http-client"]
    if (nil ~= _952_) then
      local http_client = _952_
      return http_client
    else
      local _ = _952_
      local function _954_()
        if opts["async?"] then
          local function _953_(err)
            opts["on-raise"](err)
            return nil
          end
          return _953_
        else
          return nil
        end
      end
      return make_tcp_client(tcp_chan(opts.url, nil, _954_()))
    end
  end
  local non_error_statuses = {[200] = true, [201] = true, [202] = true, [203] = true, [204] = true, [205] = true, [206] = true, [207] = true, [300] = true, [301] = true, [302] = true, [303] = true, [304] = true, [307] = true}
  local function try_coerce_body(_956_, opts)
    local len = _956_["length"]
    local response = _956_
    if ("table" == type(response)) then
      if ((len == nil) or (len and (len > 0))) then
        local _957_, _958_ = opts.as, response.body
        if ((_957_ == "json") and (nil ~= _958_)) then
          local body = _958_
          return pcall(decode, body)
        elseif (true and true) then
          local _ = _957_
          local _3fbody = _958_
          return true, _3fbody
        else
          return nil
        end
      else
        return true, nil
      end
    else
      return true, response
    end
  end
  local function raise_2a(response, opts)
    if opts["async?"] then
      return opts["on-raise"](response)
    else
      return error(response)
    end
  end
  local function respond_2a(response, opts)
    if opts["async?"] then
      return opts["on-response"](response)
    else
      return response
    end
  end
  local function respond(response, opts)
    local ok_3f, body = try_coerce_body(response, opts)
    local response0
    if (ok_3f and ("table" == type(response))) then
      response["parsed-headers"] = nil
      response["body"] = body
      response["trace-redirects"] = opts["redirect-trace"]
      response0 = response
    else
      response0 = body
    end
    if (not ok_3f or (opts["throw-errors?"] and not non_error_statuses[response0.status])) then
      return raise_2a(response0, opts)
    else
      return respond_2a(response0, opts)
    end
  end
  local function raise(response, opts)
    local ok_3f, body = try_coerce_body(response, opts)
    local response0
    if (ok_3f and ("table" == type(response))) then
      response["parsed-headers"] = nil
      response["body"] = body
      response["trace-redirects"] = opts["redirect-trace"]
      response0 = response
    else
      response0 = body
    end
    return raise_2a(response0, opts)
  end
  local function redirect_3f(status)
    return (("number" == type(status)) and ((300 <= status) and (status <= 399)))
  end
  local function consume_reader(src, remaining)
    local _967_
    local function _968_()
      if (1024 < remaining) then
        return 1024
      else
        return remaining
      end
    end
    _967_ = src:read(_968_())
    if (nil ~= _967_) then
      local data = _967_
      if (remaining > 0) then
        return consume_reader(src, (remaining - #data))
      else
        return nil
      end
    else
      return nil
    end
  end
  local function reuse_client_3f(_971_)
    local body = _971_["body"]
    local http_client = _971_["http-client"]
    local headers = _971_["headers"]
    local len = _971_["length"]
    if reader_3f(body) then
      if len then
        consume_reader(body, len)
      elseif chunked_encoding_3f(headers["Transfer-Encoding"]) then
        consume_reader(body, math.huge)
      else
      end
    else
    end
    local _974_ = lower((headers.Connection or "keep-alive"))
    if (_974_ == "keep-alive") then
      return http_client
    else
      local _ = _974_
      http_client:close()
      return nil
    end
  end
  local function relative_url(url, location)
    local tmp_9_auto
    do
      local tbl_16_auto = {}
      for k, v in pairs(url) do
        local k_17_auto, v_18_auto = k, v
        if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
          tbl_16_auto[k_17_auto] = v_18_auto
        else
        end
      end
      tmp_9_auto = tbl_16_auto
    end
    tmp_9_auto["path"] = location
    tmp_9_auto["query"] = nil
    tmp_9_auto["frarment"] = nil
    setmetatable(tmp_9_auto, getmetatable(url))
    return tmp_9_auto
  end
  local function redirect(response, opts, request_fn, location, method)
    local function _978_()
      local tmp_9_auto
      do
        local tbl_16_auto = {}
        for k, v in pairs(opts) do
          local k_17_auto, v_18_auto = k, v
          if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
            tbl_16_auto[k_17_auto] = v_18_auto
          else
          end
        end
        tmp_9_auto = tbl_16_auto
      end
      tmp_9_auto["method"] = (method or opts.method)
      tmp_9_auto["http-client"] = reuse_client_3f(response)
      tmp_9_auto["query-params"] = nil
      local _981_
      do
        local _979_, _980_ = pcall(parse_url, location)
        if ((_979_ == true) and (nil ~= _980_)) then
          local url = _980_
          if opts["follow-redirects?"] then
            insert(opts["redirect-trace"], tostring(url))
          else
          end
          _981_ = url
        elseif ((_979_ == false) and true) then
          local _ = _980_
          local url = relative_url(opts.url, location)
          if opts["follow-redirects?"] then
            insert(opts["redirect-trace"], tostring(url))
          else
          end
          _981_ = url
        else
          _981_ = nil
        end
      end
      tmp_9_auto["url"] = _981_
      tmp_9_auto["max-redirects"] = (opts["max-redirects"] - 1)
      return tmp_9_auto
    end
    return request_fn(_978_())
  end
  local function follow_redirects(_988_, _989_, request_fn)
    local status = _988_["status"]
    local headers = _988_["headers"]
    local response = _988_
    local method = _989_["method"]
    local throw_errors_3f = _989_["throw-errors?"]
    local max_redirects = _989_["max-redirects"]
    local force_redirects_3f = _989_["force-redirects?"]
    local opts = _989_
    if (not opts["follow-redirects?"] or not redirect_3f(status)) then
      return respond(response, opts)
    else
      local _990_ = headers.Location
      if (_990_ == nil) then
        return respond(response, opts)
      elseif (nil ~= _990_) then
        local location = _990_
        if (max_redirects <= 0) then
          if opts["throw-errors?"] then
            return raise("too many redirects", opts)
          else
            return respond(response, opts)
          end
        elseif ((301 == status) or (302 == status)) then
          if (("GET" == method) or ("HEAD" == method)) then
            return redirect(response, opts, request_fn, location)
          else
            return redirect(response, opts, request_fn, location, "GET")
          end
        elseif (303 == status) then
          return redirect(response, opts, request_fn, location, "GET")
        elseif ((307 == status) or (308 == status)) then
          return redirect(response, opts, request_fn, location)
        else
          return respond(response, opts)
        end
      else
        return nil
      end
    end
  end
  local function process_request(client0, request, body, headers, opts, request_fn)
    client0:write(request)
    stream_body(client0, body, headers)
    do
      local _996_ = opts.multipart
      if (nil ~= _996_) then
        local parts = _996_
        stream_multipart(client0, parts, get_boundary(headers))
      else
      end
    end
    if opts["async?"] then
      local _998_, _999_ = pcall(parse_http_response, client0, opts)
      if ((_998_ == true) and (nil ~= _999_)) then
        local resp = _999_
        return follow_redirects(resp, opts, request_fn)
      elseif (true and (nil ~= _999_)) then
        local _ = _998_
        local err = _999_
        return opts["on-raise"](err)
      else
        return nil
      end
    else
      return follow_redirects(parse_http_response(client0, opts), opts, request_fn)
    end
  end
  local function request_2a(opts)
    local body = wrap_body(opts.body)
    local headers = prepare_headers(opts)
    local req
    local function _1002_()
      if (headers["transfer-encoding"] == "chunked") then
        return nil
      elseif ("string" == type(body)) then
        return body
      else
        return nil
      end
    end
    req = build_http_request(opts.method, format_path(opts.url, opts["query-params"]), headers, _1002_())
    local client0 = make_tcp_client_2a(opts)
    assert((not opts["async?"] or (opts["on-response"] and opts["on-raise"])), "If async? is true, on-response and on-raise callbacks must be passed")
    opts.start = (opts.start or gettime())
    if opts["async?"] then
      local _let_1003_ = require("lib.async")
      local go_1_auto = _let_1003_["go"]
      local function _1004_()
        return process_request(client0, req, body, headers, opts, request_2a)
      end
      return go_1_auto(_1004_)
    else
      return process_request(client0, req, body, headers, opts, request_2a)
    end
  end
  client.request = function(method, url, opts, on_response, on_raise)
    local function _1007_()
      local tmp_9_auto
      do
        local tbl_16_auto = {as = "raw", time = gettime, ["throw-errors?"] = true, ["follow-redirects?"] = true, ["max-redirects"] = math.huge, url = parse_url(url), ["on-response"] = on_response, ["on-raise"] = on_raise, ["redirect-trace"] = {}, ["async?"] = false}
        for k, v in pairs((opts or {})) do
          local k_17_auto, v_18_auto = k, v
          if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
            tbl_16_auto[k_17_auto] = v_18_auto
          else
          end
        end
        tmp_9_auto = tbl_16_auto
      end
      tmp_9_auto["method"] = upper(method)
      return tmp_9_auto
    end
    return request_2a(_1007_())
  end
  client.get = function(url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
    return client.request("get", url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
  end
  client.post = function(url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
    return client.request("post", url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
  end
  client.put = function(url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
    return client.request("put", url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
  end
  client.patch = function(url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
    return client.request("patch", url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
  end
  client.options = function(url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
    return client.request("options", url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
  end
  client.trace = function(url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
    return client.request("trace", url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
  end
  client.head = function(url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
    return client.request("head", url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
  end
  client.delete = function(url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
    return client.request("delete", url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
  end
  client.connect = function(url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
    return client.request("connect", url_2_auto, opts_3_auto, on_response_4_auto, on_raise_5_auto)
  end
  return client
end
package.preload["lib.async"] = package.preload["lib.async"] or function(...)
  --[[ "Copyright (c) 2023 Andrey Listopadov and contributors.  All rights reserved.
  The use and distribution terms for this software are covered by the Eclipse
  Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php) which
  can be found in the file LICENSE at the root of this distribution.  By using
  this software in any fashion, you are agreeing to be bound by the terms of
  this license.
  You must not remove this notice, or any other, from this software." ]]
  local lib_name = (... or "async")
  local main_thread = (coroutine.running() or error((lib_name .. " requires Lua 5.2 or higher")))
  local or_2_ = package.preload.reduced
  if not or_2_ then
    local function _3_()
      local Reduced
      local function _5_(_4_, view, options, indent)
        local x = _4_[1]
        return ("#<reduced: " .. view(x, options, (11 + indent)) .. ">")
      end
      local function _7_(_6_)
        local x = _6_[1]
        return x
      end
      local function _9_(_8_)
        local x = _8_[1]
        return ("reduced: " .. tostring(x))
      end
      Reduced = {__fennelview = _5_, __index = {unbox = _7_}, __name = "reduced", __tostring = _9_}
      local function reduced(value)
        return setmetatable({value}, Reduced)
      end
      local function reduced_3f(value)
        return rawequal(getmetatable(value), Reduced)
      end
      return {is_reduced = reduced_3f, reduced = reduced, ["reduced?"] = reduced_3f}
    end
    or_2_ = _3_
  end
  package.preload.reduced = or_2_
  local _local_10_ = require("reduced")
  local reduced = _local_10_["reduced"]
  local reduced_3f = _local_10_["reduced?"]
  local gethook, sethook = nil, nil
  do
    local _11_ = _G.debug
    if ((_G.type(_11_) == "table") and (nil ~= _11_.gethook) and (nil ~= _11_.sethook)) then
      local gethook0 = _11_.gethook
      local sethook0 = _11_.sethook
      gethook, sethook = gethook0, sethook0
    else
      local _ = _11_
      io.stderr:write("WARNING: debug library is unawailable.  ", lib_name, " uses debug.sethook to advance timers.  ", "Time-related features are disabled.\n")
      gethook, sethook = nil
    end
  end
  local t_2fremove = table["remove"]
  local t_2fconcat = table["concat"]
  local t_2finsert = table["insert"]
  local t_2fsort = table["sort"]
  local t_2funpack = (_G.unpack or table.unpack)
  local c_2frunning = coroutine["running"]
  local c_2fresume = coroutine["resume"]
  local c_2fyield = coroutine["yield"]
  local c_2fcreate = coroutine["create"]
  local m_2fmin = math["min"]
  local m_2frandom = math["random"]
  local m_2fceil = math["ceil"]
  local m_2ffloor = math["floor"]
  local m_2fmodf = math["modf"]
  local function main_thread_3f()
    local _13_, _14_ = c_2frunning()
    if (_13_ == nil) then
      return true
    elseif (true and (_14_ == true)) then
      local _ = _13_
      return true
    else
      local _ = _13_
      return false
    end
  end
  local function merge_2a(t1, t2)
    local res = {}
    do
      local tbl_16_auto = res
      for k, v in pairs(t1) do
        local k_17_auto, v_18_auto = k, v
        if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
          tbl_16_auto[k_17_auto] = v_18_auto
        else
        end
      end
    end
    local tbl_16_auto = res
    for k, v in pairs(t2) do
      local k_17_auto, v_18_auto = k, v
      if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
        tbl_16_auto[k_17_auto] = v_18_auto
      else
      end
    end
    return tbl_16_auto
  end
  local function merge_with(f, t1, t2)
    local res
    do
      local tbl_16_auto = {}
      for k, v in pairs(t1) do
        local k_17_auto, v_18_auto = k, v
        if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
          tbl_16_auto[k_17_auto] = v_18_auto
        else
        end
      end
      res = tbl_16_auto
    end
    local tbl_16_auto = res
    for k, v in pairs(t2) do
      local k_17_auto, v_18_auto = nil, nil
      do
        local _19_ = res[k]
        if (nil ~= _19_) then
          local e = _19_
          k_17_auto, v_18_auto = k, f(e, v)
        elseif (_19_ == nil) then
          k_17_auto, v_18_auto = k, v
        else
          k_17_auto, v_18_auto = nil
        end
      end
      if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
        tbl_16_auto[k_17_auto] = v_18_auto
      else
      end
    end
    return tbl_16_auto
  end
  local function active_3f(h)
    _G.assert((nil ~= h), "Missing argument h on ./lib/async.fnl:334")
    return h["active?"](h)
  end
  local function blockable_3f(h)
    _G.assert((nil ~= h), "Missing argument h on ./lib/async.fnl:335")
    return h["blockable?"](h)
  end
  local function commit(h)
    _G.assert((nil ~= h), "Missing argument h on ./lib/async.fnl:336")
    return h:commit()
  end
  local _local_22_ = {["active?"] = active_3f, ["blockable?"] = blockable_3f, commit = commit}
  local active_3f0 = _local_22_["active?"]
  local blockable_3f0 = _local_22_["blockable?"]
  local commit0 = _local_22_["commit"]
  local Handler = _local_22_
  local function fn_handler(f, ...)
    local blockable
    if (0 == select("#", ...)) then
      blockable = true
    else
      blockable = ...
    end
    local _24_ = {}
    do
      do
        local _25_ = Handler["active?"]
        if (nil ~= _25_) then
          local f_3_auto = _25_
          local function _26_(_)
            return true
          end
          _24_["active?"] = _26_
        else
          local _ = _25_
          error("Protocol Handler doesn't define method active?")
        end
      end
      do
        local _28_ = Handler["blockable?"]
        if (nil ~= _28_) then
          local f_3_auto = _28_
          local function _29_(_)
            return blockable
          end
          _24_["blockable?"] = _29_
        else
          local _ = _28_
          error("Protocol Handler doesn't define method blockable?")
        end
      end
      local _31_ = Handler.commit
      if (nil ~= _31_) then
        local f_3_auto = _31_
        local function _32_(_)
          return f
        end
        _24_["commit"] = _32_
      else
        local _ = _31_
        error("Protocol Handler doesn't define method commit")
      end
    end
    local function _34_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Handler" .. ">")
    end
    return setmetatable({}, {__fennelview = _34_, __index = _24_, name = "reify"})
  end
  local fhnop
  local function _35_()
    return nil
  end
  fhnop = fn_handler(_35_)
  local socket
  do
    local _36_, _37_ = pcall(require, "socket")
    if ((_36_ == true) and (nil ~= _37_)) then
      local s = _37_
      socket = s
    else
      local _ = _36_
      socket = nil
    end
  end
  local posix
  do
    local _39_, _40_ = pcall(require, "posix")
    if ((_39_ == true) and (nil ~= _40_)) then
      local p = _40_
      posix = p
    else
      local _ = _39_
      posix = nil
    end
  end
  local time, sleep, time_type = nil, nil, nil
  local _43_
  do
    local t_42_ = socket
    if (nil ~= t_42_) then
      t_42_ = t_42_.gettime
    else
    end
    _43_ = t_42_
  end
  if _43_ then
    local sleep0 = socket.sleep
    local function _45_(_241)
      return sleep0((_241 / 1000))
    end
    time, sleep, time_type = socket.gettime, _45_, "socket"
  else
    local _47_
    do
      local t_46_ = posix
      if (nil ~= t_46_) then
        t_46_ = t_46_.clock_gettime
      else
      end
      _47_ = t_46_
    end
    if _47_ then
      local gettime = posix.clock_gettime
      local nanosleep = posix.nanosleep
      local function _49_()
        local s, ns = gettime()
        return (s + (ns / 1000000000))
      end
      local function _50_(_241)
        local s, ms = m_2fmodf((_241 / 1000))
        return nanosleep(s, (1000000 * 1000 * ms))
      end
      time, sleep, time_type = _49_, _50_, "posix"
    else
      time, sleep, time_type = os.time, nil, "lua"
    end
  end
  local difftime
  local function _52_(_241, _242)
    return (_241 - _242)
  end
  difftime = _52_
  local function add_21(buffer, item)
    _G.assert((nil ~= item), "Missing argument item on ./lib/async.fnl:375")
    _G.assert((nil ~= buffer), "Missing argument buffer on ./lib/async.fnl:375")
    return buffer["add!"](buffer, item)
  end
  local function close_buf_21(buffer)
    _G.assert((nil ~= buffer), "Missing argument buffer on ./lib/async.fnl:376")
    return buffer["close-buf!"](buffer)
  end
  local function full_3f(buffer)
    _G.assert((nil ~= buffer), "Missing argument buffer on ./lib/async.fnl:373")
    return buffer["full?"](buffer)
  end
  local function remove_21(buffer)
    _G.assert((nil ~= buffer), "Missing argument buffer on ./lib/async.fnl:374")
    return buffer["remove!"](buffer)
  end
  local _local_53_ = {["add!"] = add_21, ["close-buf!"] = close_buf_21, ["full?"] = full_3f, ["remove!"] = remove_21}
  local add_210 = _local_53_["add!"]
  local close_buf_210 = _local_53_["close-buf!"]
  local full_3f0 = _local_53_["full?"]
  local remove_210 = _local_53_["remove!"]
  local Buffer = _local_53_
  local FixedBuffer
  local function _55_(_54_)
    local buffer = _54_["buf"]
    local size = _54_["size"]
    return (#buffer >= size)
  end
  local function _57_(_56_)
    local buffer = _56_["buf"]
    return #buffer
  end
  local function _59_(_58_, val)
    local buffer = _58_["buf"]
    local this = _58_
    assert((val ~= nil), "value must not be nil")
    buffer[(1 + #buffer)] = val
    return this
  end
  local function _61_(_60_)
    local buffer = _60_["buf"]
    if (#buffer > 0) then
      return t_2fremove(buffer, 1)
    else
      return nil
    end
  end
  local function _63_(_)
    return nil
  end
  FixedBuffer = {type = Buffer, ["full?"] = _55_, length = _57_, ["add!"] = _59_, ["remove!"] = _61_, ["close-buf!"] = _63_}
  local DroppingBuffer
  local function _64_()
    return false
  end
  local function _66_(_65_)
    local buffer = _65_["buf"]
    return #buffer
  end
  local function _68_(_67_, val)
    local buffer = _67_["buf"]
    local size = _67_["size"]
    local this = _67_
    assert((val ~= nil), "value must not be nil")
    if (#buffer < size) then
      buffer[(1 + #buffer)] = val
    else
    end
    return this
  end
  local function _71_(_70_)
    local buffer = _70_["buf"]
    if (#buffer > 0) then
      return t_2fremove(buffer, 1)
    else
      return nil
    end
  end
  local function _73_(_)
    return nil
  end
  DroppingBuffer = {type = Buffer, ["full?"] = _64_, length = _66_, ["add!"] = _68_, ["remove!"] = _71_, ["close-buf!"] = _73_}
  local SlidingBuffer
  local function _74_()
    return false
  end
  local function _76_(_75_)
    local buffer = _75_["buf"]
    return #buffer
  end
  local function _78_(_77_, val)
    local buffer = _77_["buf"]
    local size = _77_["size"]
    local this = _77_
    assert((val ~= nil), "value must not be nil")
    buffer[(1 + #buffer)] = val
    if (size < #buffer) then
      t_2fremove(buffer, 1)
    else
    end
    return this
  end
  local function _81_(_80_)
    local buffer = _80_["buf"]
    if (#buffer > 0) then
      return t_2fremove(buffer, 1)
    else
      return nil
    end
  end
  local function _83_(_)
    return nil
  end
  SlidingBuffer = {type = Buffer, ["full?"] = _74_, length = _76_, ["add!"] = _78_, ["remove!"] = _81_, ["close-buf!"] = _83_}
  local no_val = {}
  local PromiseBuffer
  local function _84_()
    return false
  end
  local function _85_(this)
    if rawequal(no_val, this.val) then
      return 0
    else
      return 1
    end
  end
  local function _87_(this, val)
    assert((val ~= nil), "value must not be nil")
    if rawequal(no_val, this.val) then
      this["val"] = val
    else
    end
    return this
  end
  local function _90_(_89_)
    local value = _89_["val"]
    return value
  end
  local function _92_(_91_)
    local value = _91_["val"]
    local this = _91_
    if rawequal(no_val, value) then
      this["val"] = nil
      return nil
    else
      return nil
    end
  end
  PromiseBuffer = {type = Buffer, val = no_val, ["full?"] = _84_, length = _85_, ["add!"] = _87_, ["remove!"] = _90_, ["close-buf!"] = _92_}
  local function buffer_2a(size, buffer_type)
    do local _ = (size and assert(("number" == type(size)), ("size must be a number: " .. tostring(size)))) end
    assert(not tostring(size):match("%."), "size must be integer")
    local function _94_(self)
      return self:length()
    end
    local function _95_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "buffer:") .. ">")
    end
    return setmetatable({size = size, buf = {}}, {__index = buffer_type, __name = "buffer", __len = _94_, __fennelview = _95_})
  end
  local function buffer(n)
    return buffer_2a(n, FixedBuffer)
  end
  local function dropping_buffer(n)
    return buffer_2a(n, DroppingBuffer)
  end
  local function sliding_buffer(n)
    return buffer_2a(n, SlidingBuffer)
  end
  local function promise_buffer()
    return buffer_2a(1, PromiseBuffer)
  end
  local function buffer_3f(obj)
    if ((_G.type(obj) == "table") and (obj.type == Buffer)) then
      return true
    else
      local _ = obj
      return false
    end
  end
  local function unblocking_buffer_3f(buff)
    local _97_ = (buffer_3f(buff) and getmetatable(buff).__index)
    if (_97_ == SlidingBuffer) then
      return true
    elseif (_97_ == DroppingBuffer) then
      return true
    elseif (_97_ == PromiseBuffer) then
      return true
    else
      local _ = _97_
      return false
    end
  end
  local timeouts = {}
  local dispatched_tasks = {}
  local os_2fclock = os.clock
  local n_instr, register_time, orig_hook, orig_mask, orig_n = 1000000
  local function schedule_hook(hook, n)
    if (gethook and sethook) then
      local hook_2a, mask, n_2a = gethook()
      if (hook ~= hook_2a) then
        register_time, orig_hook, orig_mask, orig_n = os_2fclock(), hook_2a, mask, n_2a
        return sethook(main_thread, hook, "", n)
      else
        return nil
      end
    else
      return nil
    end
  end
  local function cancel_hook(hook)
    if (gethook and sethook) then
      local _101_, _102_, _103_ = gethook(main_thread)
      if ((_101_ == hook) and true and true) then
        local _3fmask = _102_
        local _3fn = _103_
        sethook(main_thread, orig_hook, orig_mask, orig_n)
        return _3fmask, _3fn
      else
        return nil
      end
    else
      return nil
    end
  end
  local function process_messages(event)
    local took = (os_2fclock() - register_time)
    local _, n = cancel_hook(process_messages)
    if (event ~= "count") then
      n_instr = n
    else
      n_instr = m_2ffloor((0.01 / (took / n)))
    end
    do
      local done = nil
      for _0 = 1, 1024 do
        if done then break end
        local _107_ = next(dispatched_tasks)
        if (nil ~= _107_) then
          local f = _107_
          local _108_
          do
            pcall(f)
            _108_ = f
          end
          dispatched_tasks[_108_] = nil
          done = nil
        elseif (_107_ == nil) then
          done = true
        else
          done = nil
        end
      end
    end
    for t, ch in pairs(timeouts) do
      if (0 >= difftime(t, time())) then
        timeouts[t] = ch["close!"](ch)
      else
      end
    end
    if (next(dispatched_tasks) or next(timeouts)) then
      return schedule_hook(process_messages, n_instr)
    else
      return nil
    end
  end
  local function dispatch(f)
    if (gethook and sethook) then
      dispatched_tasks[f] = true
      schedule_hook(process_messages, n_instr)
    else
      f()
    end
    return nil
  end
  local function put_active_3f(_113_)
    local handler = _113_[1]
    return handler["active?"](handler)
  end
  local function cleanup_21(t, pred)
    local to_keep
    do
      local tbl_21_auto = {}
      local i_22_auto = 0
      for i, v in ipairs(t) do
        local val_23_auto
        if pred(v) then
          val_23_auto = v
        else
          val_23_auto = nil
        end
        if (nil ~= val_23_auto) then
          i_22_auto = (i_22_auto + 1)
          tbl_21_auto[i_22_auto] = val_23_auto
        else
        end
      end
      to_keep = tbl_21_auto
    end
    while t_2fremove(t) do
    end
    for _, v in ipairs(to_keep) do
      t_2finsert(t, v)
    end
    return t
  end
  local MAX_QUEUE_SIZE = 1024
  local MAX_DIRTY = 64
  local Channel = {["dirty-puts"] = 0, ["dirty-takes"] = 0}
  Channel.abort = function(_116_)
    local puts = _116_["puts"]
    local function recur()
      local putter = t_2fremove(puts, 1)
      if (nil ~= putter) then
        local put_handler = putter[1]
        local val = putter[2]
        if put_handler["active?"](put_handler) then
          local put_cb = put_handler:commit()
          local function _117_()
            return put_cb(true)
          end
          return dispatch(_117_)
        else
          return recur()
        end
      else
        return nil
      end
    end
    return recur
  end
  Channel["put!"] = function(_120_, val, handler, enqueue_3f)
    local buf = _120_["buf"]
    local closed = _120_["closed"]
    local this = _120_
    assert((val ~= nil), "Can't put nil on a channel")
    if not handler["active?"]() then
      return {not closed}
    elseif closed then
      handler:commit()
      return {false}
    elseif (buf and not buf["full?"](buf)) then
      local takes = this["takes"]
      local add_211 = this["add!"]
      handler:commit()
      local done_3f = reduced_3f(add_211(buf, val))
      local take_cbs
      local function recur(takers)
        if (next(takes) and (#buf > 0)) then
          local taker = t_2fremove(takes, 1)
          if taker["active?"](taker) then
            local ret = taker:commit()
            local val0 = buf["remove!"](buf)
            local function _121_()
              local function _122_()
                return ret(val0)
              end
              t_2finsert(takers, _122_)
              return takers
            end
            return recur(_121_())
          else
            return recur(takers)
          end
        else
          return takers
        end
      end
      take_cbs = recur({})
      if done_3f then
        this:abort()
      else
      end
      if next(take_cbs) then
        for _, f in ipairs(take_cbs) do
          dispatch(f)
        end
      else
      end
      return {true}
    else
      local takes = this.takes
      local taker
      local function recur()
        local taker0 = t_2fremove(takes, 1)
        if taker0 then
          if taker0["active?"](taker0) then
            return taker0
          else
            return recur()
          end
        else
          return nil
        end
      end
      taker = recur()
      if taker then
        local take_cb = taker:commit()
        handler:commit()
        local function _129_()
          return take_cb(val)
        end
        dispatch(_129_)
        return {true}
      else
        local puts = this["puts"]
        local dirty_puts = this["dirty-puts"]
        if (dirty_puts > MAX_DIRTY) then
          this["dirty-puts"] = 0
          cleanup_21(puts, put_active_3f)
        else
          this["dirty-puts"] = (1 + dirty_puts)
        end
        if handler["blockable?"](handler) then
          assert((#puts < MAX_QUEUE_SIZE), ("No more than " .. MAX_QUEUE_SIZE .. " pending puts are allowed on a single channel." .. " Consider using a windowed buffer."))
          local handler_2a
          if (main_thread_3f() or enqueue_3f) then
            handler_2a = handler
          else
            local thunk = c_2frunning()
            local _131_ = {}
            do
              do
                local _132_ = Handler["active?"]
                if (nil ~= _132_) then
                  local f_3_auto = _132_
                  local function _133_(_)
                    return handler["active?"](handler)
                  end
                  _131_["active?"] = _133_
                else
                  local _ = _132_
                  error("Protocol Handler doesn't define method active?")
                end
              end
              do
                local _135_ = Handler["blockable?"]
                if (nil ~= _135_) then
                  local f_3_auto = _135_
                  local function _136_(_)
                    return handler["blockable?"](handler)
                  end
                  _131_["blockable?"] = _136_
                else
                  local _ = _135_
                  error("Protocol Handler doesn't define method blockable?")
                end
              end
              local _138_ = Handler.commit
              if (nil ~= _138_) then
                local f_3_auto = _138_
                local function _139_(_)
                  local function _140_(...)
                    return c_2fresume(thunk, ...)
                  end
                  return _140_
                end
                _131_["commit"] = _139_
              else
                local _ = _138_
                error("Protocol Handler doesn't define method commit")
              end
            end
            local function _142_(_241)
              return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Handler" .. ">")
            end
            handler_2a = setmetatable({}, {__fennelview = _142_, __index = _131_, name = "reify"})
          end
          t_2finsert(puts, {handler_2a, val})
          if (handler ~= handler_2a) then
            local val0 = c_2fyield()
            handler:commit()(val0)
            return {val0}
          else
            return nil
          end
        else
          return nil
        end
      end
    end
  end
  Channel["take!"] = function(_148_, handler, enqueue_3f)
    local buf = _148_["buf"]
    local this = _148_
    if not handler["active?"](handler) then
      return nil
    elseif (not (nil == buf) and (#buf > 0)) then
      local _149_ = handler:commit()
      if (nil ~= _149_) then
        local take_cb = _149_
        local puts = this.puts
        local val = buf["remove!"](buf)
        if (not buf["full?"](buf) and next(puts)) then
          local add_211 = this["add!"]
          local function recur(cbs)
            local putter = t_2fremove(puts, 1)
            local put_handler = putter[1]
            local val0 = putter[2]
            local cb = (put_handler["active?"](put_handler) and put_handler:commit())
            local cbs0
            if cb then
              t_2finsert(cbs, cb)
              cbs0 = cbs
            else
              cbs0 = cbs
            end
            local done_3f
            if cb then
              done_3f = reduced_3f(add_211(buf, val0))
            else
              done_3f = nil
            end
            if (not done_3f and not buf["full?"](buf) and next(puts)) then
              return recur(cbs0)
            else
              return {done_3f, cbs0}
            end
          end
          local _let_153_ = recur({})
          local done_3f = _let_153_[1]
          local cbs = _let_153_[2]
          if done_3f then
            this:abort()
          else
          end
          for _, cb in ipairs(cbs) do
            local function _155_()
              return cb(true)
            end
            dispatch(_155_)
          end
        else
        end
        return {val}
      else
        return nil
      end
    else
      local puts = this.puts
      local putter
      local function recur()
        local putter0 = t_2fremove(puts, 1)
        if putter0 then
          local tgt_158_ = putter0[1]
          if (tgt_158_)["active?"](tgt_158_) then
            return putter0
          else
            return recur()
          end
        else
          return nil
        end
      end
      putter = recur()
      if putter then
        local put_cb = putter[1]:commit()
        handler:commit()
        local function _161_()
          return put_cb(true)
        end
        dispatch(_161_)
        return {putter[2]}
      elseif this.closed then
        if buf then
          this["add!"](buf)
        else
        end
        if (handler["active?"](handler) and handler:commit()) then
          local has_val = (buf and next(buf.buf))
          local val
          if has_val then
            val = buf["remove!"](buf)
          else
            val = nil
          end
          return {val}
        else
          return nil
        end
      else
        local takes = this["takes"]
        local dirty_takes = this["dirty-takes"]
        if (dirty_takes > MAX_DIRTY) then
          this["dirty-takes"] = 0
          local function _165_(_241)
            return _241["active?"](_241)
          end
          cleanup_21(takes, _165_)
        else
          this["dirty-takes"] = (1 + dirty_takes)
        end
        if handler["blockable?"](handler) then
          assert((#takes < MAX_QUEUE_SIZE), ("No more than " .. MAX_QUEUE_SIZE .. " pending takes are allowed on a single channel."))
          local handler_2a
          if (main_thread_3f() or enqueue_3f) then
            handler_2a = handler
          else
            local thunk = c_2frunning()
            local _167_ = {}
            do
              do
                local _168_ = Handler["active?"]
                if (nil ~= _168_) then
                  local f_3_auto = _168_
                  local function _169_(_)
                    return handler["active?"](handler)
                  end
                  _167_["active?"] = _169_
                else
                  local _ = _168_
                  error("Protocol Handler doesn't define method active?")
                end
              end
              do
                local _171_ = Handler["blockable?"]
                if (nil ~= _171_) then
                  local f_3_auto = _171_
                  local function _172_(_)
                    return handler["blockable?"](handler)
                  end
                  _167_["blockable?"] = _172_
                else
                  local _ = _171_
                  error("Protocol Handler doesn't define method blockable?")
                end
              end
              local _174_ = Handler.commit
              if (nil ~= _174_) then
                local f_3_auto = _174_
                local function _175_(_)
                  local function _176_(...)
                    return c_2fresume(thunk, ...)
                  end
                  return _176_
                end
                _167_["commit"] = _175_
              else
                local _ = _174_
                error("Protocol Handler doesn't define method commit")
              end
            end
            local function _178_(_241)
              return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Handler" .. ">")
            end
            handler_2a = setmetatable({}, {__fennelview = _178_, __index = _167_, name = "reify"})
          end
          t_2finsert(takes, handler_2a)
          if (handler ~= handler_2a) then
            local val = c_2fyield()
            handler:commit()(val)
            return {val}
          else
            return nil
          end
        else
          return nil
        end
      end
    end
  end
  Channel["close!"] = function(this)
    if this.closed then
      return nil
    else
      local buf = this["buf"]
      local takes = this["takes"]
      this.closed = true
      if (buf and (0 == #this.puts)) then
        this["add!"](buf)
      else
      end
      local function recur()
        local taker = t_2fremove(takes, 1)
        if (nil ~= taker) then
          if taker["active?"](taker) then
            local take_cb = taker:commit()
            local val
            if (buf and next(buf.buf)) then
              val = buf["remove!"](buf)
            else
              val = nil
            end
            local function _186_()
              return take_cb(val)
            end
            dispatch(_186_)
          else
          end
          return recur()
        else
          return nil
        end
      end
      recur()
      if buf then
        buf["close-buf!"](buf)
      else
      end
      return nil
    end
  end
  do
    Channel["type"] = Channel
    Channel["close"] = Channel["close!"]
  end
  local function err_handler_2a(e)
    io.stderr:write(tostring(e), "\n")
    return nil
  end
  local function add_21_2a(buf, ...)
    local _191_, _192_ = select("#", ...), ...
    if ((_191_ == 1) and true) then
      local _3fval = _192_
      return buf["add!"](buf, _3fval)
    elseif (_191_ == 0) then
      return buf
    else
      return nil
    end
  end
  local function chan(buf_or_n, xform, err_handler)
    local buffer0
    if ((_G.type(buf_or_n) == "table") and (buf_or_n.type == Buffer)) then
      buffer0 = buf_or_n
    elseif (buf_or_n == 0) then
      buffer0 = nil
    elseif (nil ~= buf_or_n) then
      local size = buf_or_n
      buffer0 = buffer(size)
    else
      buffer0 = nil
    end
    local add_211
    if xform then
      assert((nil ~= buffer0), "buffer must be supplied when transducer is")
      add_211 = xform(add_21_2a)
    else
      add_211 = add_21_2a
    end
    local err_handler0 = (err_handler or err_handler_2a)
    local handler
    local function _196_(ch, err)
      local _197_ = err_handler0(err)
      if (nil ~= _197_) then
        local res = _197_
        return ch["put!"](ch, res, fhnop)
      else
        return nil
      end
    end
    handler = _196_
    local c = {puts = {}, takes = {}, buf = buffer0, ["err-handler"] = handler}
    c["add!"] = function(...)
      local _199_, _200_ = pcall(add_211, ...)
      if ((_199_ == true) and true) then
        local _ = _200_
        return _
      elseif ((_199_ == false) and (nil ~= _200_)) then
        local e = _200_
        return handler(c, e)
      else
        return nil
      end
    end
    local function _202_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "ManyToManyChannel:") .. ">")
    end
    return setmetatable(c, {__index = Channel, __name = "ManyToManyChannel", __fennelview = _202_})
  end
  local function promise_chan(xform, err_handler)
    return chan(promise_buffer(), xform, err_handler)
  end
  local function chan_3f(obj)
    if ((_G.type(obj) == "table") and (obj.type == Channel)) then
      return true
    else
      local _ = obj
      return false
    end
  end
  local function closed_3f(port)
    assert(chan_3f(port), "expected a channel")
    return port.closed
  end
  local warned = false
  local function timeout(msecs)
    assert((gethook and sethook), "Can't advance timers - debug.sethook unavailable")
    local dt
    if (time_type == "lua") then
      local s = (msecs / 1000)
      if (not warned and not (m_2fceil(s) == s)) then
        warned = true
        local function _204_()
          warned = false
          return nil
        end
        local tgt_205_ = timeout(10000)
        do end (tgt_205_)["take!"](tgt_205_, fn_handler(_204_))
        io.stderr:write(("WARNING Lua doesn't support sub-second time precision.  " .. "Timeout rounded to the next nearest whole second.  " .. "Install luasocket or luaposix to get sub-second precision.\n"))
      else
      end
      dt = s
    else
      local _ = time_type
      dt = (msecs / 1000)
    end
    local t = ((m_2fceil((time() * 100)) / 100) + dt)
    local c
    local or_208_ = timeouts[t]
    if not or_208_ then
      local c0 = chan()
      timeouts[t] = c0
      or_208_ = c0
    end
    c = or_208_
    schedule_hook(process_messages, n_instr)
    return c
  end
  local function take_21(port, fn1, ...)
    assert(chan_3f(port), "expected a channel as first argument")
    assert((nil ~= fn1), "expected a callback")
    local on_caller_3f
    if (select("#", ...) == 0) then
      on_caller_3f = true
    else
      on_caller_3f = ...
    end
    do
      local _211_ = port["take!"](port, fn_handler(fn1))
      if (nil ~= _211_) then
        local retb = _211_
        local val = retb[1]
        if on_caller_3f then
          fn1(val)
        else
          local function _212_()
            return fn1(val)
          end
          dispatch(_212_)
        end
      else
      end
    end
    return nil
  end
  local function try_sleep()
    local timers
    do
      local tmp_9_auto
      do
        local tbl_21_auto = {}
        local i_22_auto = 0
        for timer in pairs(timeouts) do
          local val_23_auto = timer
          if (nil ~= val_23_auto) then
            i_22_auto = (i_22_auto + 1)
            tbl_21_auto[i_22_auto] = val_23_auto
          else
          end
        end
        tmp_9_auto = tbl_21_auto
      end
      t_2fsort(tmp_9_auto)
      timers = tmp_9_auto
    end
    local _216_ = timers[1]
    local and_217_ = (nil ~= _216_)
    if and_217_ then
      local t = _216_
      and_217_ = (sleep and not next(dispatched_tasks))
    end
    if and_217_ then
      local t = _216_
      local t0 = (t - time())
      if (t0 > 0) then
        sleep(t0)
        process_messages("manual")
      else
      end
      return true
    else
      local _ = _216_
      if next(dispatched_tasks) then
        process_messages("manual")
        return true
      else
        return nil
      end
    end
  end
  local function _3c_21_21(port)
    assert(main_thread_3f(), "<!! used not on the main thread")
    local val = nil
    local function _222_(_241)
      val = _241
      return nil
    end
    take_21(port, _222_)
    while ((val == nil) and not port.closed and try_sleep()) do
    end
    if ((nil == val) and not port.closed) then
      error(("The " .. tostring(port) .. " is not ready and there are no scheduled tasks." .. " Value will never arrive."), 2)
    else
    end
    return val
  end
  local function _3c_21(port)
    assert(not main_thread_3f(), "<! used not in (go ...) block")
    assert(chan_3f(port), "expected a channel as first argument")
    local _224_ = port["take!"](port, fhnop)
    if (nil ~= _224_) then
      local retb = _224_
      return retb[1]
    else
      return nil
    end
  end
  local function put_21(port, val, ...)
    assert(chan_3f(port), "expected a channel as first argument")
    local _226_ = select("#", ...)
    if (_226_ == 0) then
      local _227_ = port["put!"](port, val, fhnop)
      if (nil ~= _227_) then
        local retb = _227_
        return retb[1]
      else
        local _ = _227_
        return true
      end
    elseif (_226_ == 1) then
      return put_21(port, val, ..., true)
    elseif (_226_ == 2) then
      local fn1, on_caller_3f = ...
      local _229_ = port["put!"](port, val, fn_handler(fn1))
      if (nil ~= _229_) then
        local retb = _229_
        local ret = retb[1]
        if on_caller_3f then
          fn1(ret)
        else
          local function _230_()
            return fn1(ret)
          end
          dispatch(_230_)
        end
        return ret
      else
        local _ = _229_
        return true
      end
    else
      return nil
    end
  end
  local function _3e_21_21(port, val)
    assert(main_thread_3f(), ">!! used not on the main thread")
    local not_done, res = true
    local function _234_(_241)
      not_done, res = false, _241
      return nil
    end
    put_21(port, val, _234_)
    while (not_done and try_sleep(port)) do
    end
    if (not_done and not port.closed) then
      error(("The " .. tostring(port) .. " is not ready and there are no scheduled tasks." .. " Value was sent but there's no one to receive it"), 2)
    else
    end
    return res
  end
  local function _3e_21(port, val)
    assert(not main_thread_3f(), ">! used not in (go ...) block")
    local _236_ = port["put!"](port, val, fhnop)
    if (nil ~= _236_) then
      local retb = _236_
      return retb[1]
    else
      return nil
    end
  end
  local function close_21(port)
    assert(chan_3f(port), "expected a channel")
    return port:close()
  end
  local function go_2a(fn1)
    local c = chan(1)
    do
      local _238_, _239_ = nil, nil
      local function _240_()
        do
          local _241_ = fn1()
          if (nil ~= _241_) then
            local val = _241_
            _3e_21(c, val)
          else
          end
        end
        return close_21(c)
      end
      _238_, _239_ = c_2fresume(c_2fcreate(_240_))
      if ((_238_ == false) and (nil ~= _239_)) then
        local msg = _239_
        c["err-handler"](c, msg)
        close_21(c)
      else
      end
    end
    return c
  end
  local function random_array(n)
    local ids
    do
      local tbl_21_auto = {}
      local i_22_auto = 0
      for i = 1, n do
        local val_23_auto = i
        if (nil ~= val_23_auto) then
          i_22_auto = (i_22_auto + 1)
          tbl_21_auto[i_22_auto] = val_23_auto
        else
        end
      end
      ids = tbl_21_auto
    end
    for i = n, 2, -1 do
      local j = m_2frandom(i)
      local ti = ids[i]
      ids[i] = ids[j]
      ids[j] = ti
    end
    return ids
  end
  local function alt_flag()
    local atom = {flag = true}
    local _245_ = {}
    do
      do
        local _246_ = Handler["active?"]
        if (nil ~= _246_) then
          local f_3_auto = _246_
          local function _247_(_)
            return atom.flag
          end
          _245_["active?"] = _247_
        else
          local _ = _246_
          error("Protocol Handler doesn't define method active?")
        end
      end
      do
        local _249_ = Handler["blockable?"]
        if (nil ~= _249_) then
          local f_3_auto = _249_
          local function _250_(_)
            return true
          end
          _245_["blockable?"] = _250_
        else
          local _ = _249_
          error("Protocol Handler doesn't define method blockable?")
        end
      end
      local _252_ = Handler.commit
      if (nil ~= _252_) then
        local f_3_auto = _252_
        local function _253_(_)
          atom.flag = false
          return true
        end
        _245_["commit"] = _253_
      else
        local _ = _252_
        error("Protocol Handler doesn't define method commit")
      end
    end
    local function _255_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Handler" .. ">")
    end
    return setmetatable({}, {__fennelview = _255_, __index = _245_, name = "reify"})
  end
  local function alt_handler(flag, cb)
    local _256_ = {}
    do
      do
        local _257_ = Handler["active?"]
        if (nil ~= _257_) then
          local f_3_auto = _257_
          local function _258_(_)
            return flag["active?"](flag)
          end
          _256_["active?"] = _258_
        else
          local _ = _257_
          error("Protocol Handler doesn't define method active?")
        end
      end
      do
        local _260_ = Handler["blockable?"]
        if (nil ~= _260_) then
          local f_3_auto = _260_
          local function _261_(_)
            return true
          end
          _256_["blockable?"] = _261_
        else
          local _ = _260_
          error("Protocol Handler doesn't define method blockable?")
        end
      end
      local _263_ = Handler.commit
      if (nil ~= _263_) then
        local f_3_auto = _263_
        local function _264_(_)
          flag:commit()
          return cb
        end
        _256_["commit"] = _264_
      else
        local _ = _263_
        error("Protocol Handler doesn't define method commit")
      end
    end
    local function _266_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Handler" .. ">")
    end
    return setmetatable({}, {__fennelview = _266_, __index = _256_, name = "reify"})
  end
  local function alts_21(ports, ...)
    assert(not main_thread_3f(), "called alts! on the main thread")
    assert((#ports > 0), "alts must have at least one channel operation")
    local n = #ports
    local arglen = select("#", ...)
    local no_def = {}
    local opts
    do
      local _267_, _268_ = select("#", ...), ...
      if (_267_ == 0) then
        opts = {default = no_def}
      else
        local and_269_ = ((_267_ == 1) and (nil ~= _268_))
        if and_269_ then
          local t = _268_
          and_269_ = ("table" == type(t))
        end
        if and_269_ then
          local t = _268_
          local res = {default = no_def}
          for k, v in pairs(t) do
            res[k] = v
            res = res
          end
          opts = res
        else
          local _ = _267_
          local res = {default = no_def}
          for i = 1, arglen, 2 do
            local k, v = select(i, ...)
            res[k] = v
            res = res
          end
          opts = res
        end
      end
    end
    local ids = random_array(n)
    local res_ch = chan(promise_buffer())
    local flag = alt_flag()
    local done = nil
    for i = 1, n do
      if done then break end
      local id
      if (opts and opts.priority) then
        id = i
      else
        id = ids[i]
      end
      local retb, port = nil, nil
      do
        local _273_ = ports[id]
        local and_274_ = ((_G.type(_273_) == "table") and true and true)
        if and_274_ then
          local _3fc = _273_[1]
          local _3fv = _273_[2]
          and_274_ = chan_3f(_3fc)
        end
        if and_274_ then
          local _3fc = _273_[1]
          local _3fv = _273_[2]
          local function _276_(_241)
            put_21(res_ch, {_241, _3fc})
            return close_21(res_ch)
          end
          retb, port = _3fc["put!"](_3fc, _3fv, alt_handler(flag, _276_), true), _3fc
        else
          local and_277_ = true
          if and_277_ then
            local _3fc = _273_
            and_277_ = chan_3f(_3fc)
          end
          if and_277_ then
            local _3fc = _273_
            local function _279_(_241)
              put_21(res_ch, {_241, _3fc})
              return close_21(res_ch)
            end
            retb, port = _3fc["take!"](_3fc, alt_handler(flag, _279_), true), _3fc
          else
            local _ = _273_
            retb, port = error(("expected a channel: " .. tostring(_)))
          end
        end
      end
      if (nil ~= retb) then
        _3e_21(res_ch, {retb[1], port})
        done = true
      else
      end
    end
    if (flag["active?"](flag) and (no_def ~= opts.default)) then
      flag:commit()
      return {opts.default, "default"}
    else
      return _3c_21(res_ch)
    end
  end
  local function offer_21(port, val)
    assert(chan_3f(port), "expected a channel as first argument")
    if (next(port.takes) or (port.buf and not port.buf["full?"](port.buf))) then
      local _283_ = port["put!"](port, val, fhnop)
      if (nil ~= _283_) then
        local retb = _283_
        return retb[1]
      else
        return nil
      end
    else
      return nil
    end
  end
  local function poll_21(port)
    assert(chan_3f(port), "expected a channel")
    if (next(port.puts) or (port.buf and (nil ~= next(port.buf.buf)))) then
      local _286_ = port["take!"](port, fhnop)
      if (nil ~= _286_) then
        local retb = _286_
        return retb[1]
      else
        return nil
      end
    else
      return nil
    end
  end
  local function pipe(from, to, ...)
    local close_3f
    if (select("#", ...) == 0) then
      close_3f = true
    else
      close_3f = ...
    end
    local _let_290_ = require("lib.async")
    local go_1_auto = _let_290_["go"]
    local function _291_()
      local function recur()
        local val = _3c_21(from)
        if (nil == val) then
          if close_3f then
            return close_21(to)
          else
            return nil
          end
        else
          _3e_21(to, val)
          return recur()
        end
      end
      return recur()
    end
    return go_1_auto(_291_)
  end
  local function pipeline_2a(n, to, xf, from, close_3f, err_handler, kind)
    local jobs = chan(n)
    local results = chan(n)
    local finishes = ((kind == "async") and chan(n))
    local process
    local function _294_(job)
      if (job == nil) then
        close_21(results)
        return nil
      elseif ((_G.type(job) == "table") and (nil ~= job[1]) and (nil ~= job[2])) then
        local v = job[1]
        local p = job[2]
        local res = chan(1, xf, err_handler)
        do
          local _let_295_ = require("lib.async")
          local go_1_auto = _let_295_["go"]
          local function _296_()
            _3e_21(res, v)
            return close_21(res)
          end
          go_1_auto(_296_)
        end
        put_21(p, res)
        return true
      else
        return nil
      end
    end
    process = _294_
    local async
    local function _298_(job)
      if (job == nil) then
        close_21(results)
        close_21(finishes)
        return nil
      elseif ((_G.type(job) == "table") and (nil ~= job[1]) and (nil ~= job[2])) then
        local v = job[1]
        local p = job[2]
        local res = chan(1)
        xf(v, res)
        put_21(p, res)
        return true
      else
        return nil
      end
    end
    async = _298_
    for _ = 1, n do
      if (kind == "compute") then
        local _let_300_ = require("lib.async")
        local go_1_auto = _let_300_["go"]
        local function _301_()
          local function recur()
            local job = _3c_21(jobs)
            if process(job) then
              return recur()
            else
              return nil
            end
          end
          return recur()
        end
        go_1_auto(_301_)
      elseif (kind == "async") then
        local _let_303_ = require("lib.async")
        local go_1_auto = _let_303_["go"]
        local function _304_()
          local function recur()
            local job = _3c_21(jobs)
            if async(job) then
              _3c_21(finishes)
              return recur()
            else
              return nil
            end
          end
          return recur()
        end
        go_1_auto(_304_)
      else
      end
    end
    do
      local _let_307_ = require("lib.async")
      local go_1_auto = _let_307_["go"]
      local function _308_()
        local function recur()
          local _309_ = _3c_21(from)
          if (_309_ == nil) then
            return close_21(jobs)
          elseif (nil ~= _309_) then
            local v = _309_
            local p = chan(1)
            _3e_21(jobs, {v, p})
            _3e_21(results, p)
            return recur()
          else
            return nil
          end
        end
        return recur()
      end
      go_1_auto(_308_)
    end
    local _let_311_ = require("lib.async")
    local go_1_auto = _let_311_["go"]
    local function _312_()
      local function recur()
        local _313_ = _3c_21(results)
        if (_313_ == nil) then
          if close_3f then
            return close_21(to)
          else
            return nil
          end
        elseif (nil ~= _313_) then
          local p = _313_
          local _315_ = _3c_21(p)
          if (nil ~= _315_) then
            local res = _315_
            local function loop_2a()
              local _316_ = _3c_21(res)
              if (nil ~= _316_) then
                local val = _316_
                _3e_21(to, val)
                return loop_2a()
              else
                return nil
              end
            end
            loop_2a()
            if finishes then
              _3e_21(finishes, "done")
            else
            end
            return recur()
          else
            return nil
          end
        else
          return nil
        end
      end
      return recur()
    end
    return go_1_auto(_312_)
  end
  local function pipeline_async(n, to, af, from, ...)
    local close_3f
    if (select("#", ...) == 0) then
      close_3f = true
    else
      close_3f = ...
    end
    return pipeline_2a(n, to, af, from, close_3f, nil, "async")
  end
  local function pipeline(n, to, xf, from, ...)
    local close_3f, err_handler = nil, nil
    if (select("#", ...) == 0) then
      close_3f, err_handler = true
    else
      close_3f, err_handler = ...
    end
    return pipeline_2a(n, to, xf, from, close_3f, err_handler, "compute")
  end
  local function split(p, ch, t_buf_or_n, f_buf_or_n)
    local tc = chan(t_buf_or_n)
    local fc = chan(f_buf_or_n)
    do
      local _let_323_ = require("lib.async")
      local go_1_auto = _let_323_["go"]
      local function _324_()
        local function recur()
          local v = _3c_21(ch)
          if (nil == v) then
            close_21(tc)
            return close_21(fc)
          else
            local _325_
            if p(v) then
              _325_ = tc
            else
              _325_ = fc
            end
            if _3e_21(_325_, v) then
              return recur()
            else
              return nil
            end
          end
        end
        return recur()
      end
      go_1_auto(_324_)
    end
    return {tc, fc}
  end
  local function reduce(f, init, ch)
    local _let_330_ = require("lib.async")
    local go_1_auto = _let_330_["go"]
    local function _331_()
      local _2_329_ = init
      local ret = _2_329_
      local function recur(ret0)
        local v = _3c_21(ch)
        if (nil == v) then
          return ret0
        else
          local res = f(ret0, v)
          if reduced_3f(res) then
            return res:unbox()
          else
            return recur(res)
          end
        end
      end
      return recur(_2_329_)
    end
    return go_1_auto(_331_)
  end
  local function transduce(xform, f, init, ch)
    local f0 = xform(f)
    local _let_334_ = require("lib.async")
    local go_1_auto = _let_334_["go"]
    local function _335_()
      local ret = _3c_21(reduce(f0, init, ch))
      return f0(ret)
    end
    return go_1_auto(_335_)
  end
  local function onto_chan_21(ch, coll, ...)
    local close_3f
    if (select("#", ...) == 0) then
      close_3f = true
    else
      close_3f = ...
    end
    local _let_337_ = require("lib.async")
    local go_1_auto = _let_337_["go"]
    local function _338_()
      for _, v in ipairs(coll) do
        _3e_21(ch, v)
      end
      if close_3f then
        close_21(ch)
      else
      end
      return ch
    end
    return go_1_auto(_338_)
  end
  local function bounded_length(bound, t)
    return m_2fmin(bound, #t)
  end
  local function to_chan_21(coll)
    local ch = chan(bounded_length(100, coll))
    onto_chan_21(ch, coll)
    return ch
  end
  local function pipeline_unordered_2a(n, to, xf, from, close_3f, err_handler, kind)
    local closes
    local function _340_()
      local tbl_21_auto = {}
      local i_22_auto = 0
      for _ = 1, (n - 1) do
        local val_23_auto = "close"
        if (nil ~= val_23_auto) then
          i_22_auto = (i_22_auto + 1)
          tbl_21_auto[i_22_auto] = val_23_auto
        else
        end
      end
      return tbl_21_auto
    end
    closes = to_chan_21(_340_())
    local process
    local function _342_(v, p)
      local res = chan(1, xf, err_handler)
      local _let_343_ = require("lib.async")
      local go_1_auto = _let_343_["go"]
      local function _344_()
        _3e_21(res, v)
        close_21(res)
        local function loop()
          local _345_ = _3c_21(res)
          if (nil ~= _345_) then
            local v0 = _345_
            put_21(p, v0)
            return loop()
          else
            return nil
          end
        end
        loop()
        return close_21(p)
      end
      return go_1_auto(_344_)
    end
    process = _342_
    for _ = 1, n do
      local _let_347_ = require("lib.async")
      local go_1_auto = _let_347_["go"]
      local function _348_()
        local function recur()
          local _349_ = _3c_21(from)
          if (nil ~= _349_) then
            local v = _349_
            local c = chan(1)
            if (kind == "compute") then
              local _let_350_ = require("lib.async")
              local go_1_auto0 = _let_350_["go"]
              local function _351_()
                return process(v, c)
              end
              go_1_auto0(_351_)
            elseif (kind == "async") then
              local _let_352_ = require("lib.async")
              local go_1_auto0 = _let_352_["go"]
              local function _353_()
                return xf(v, c)
              end
              go_1_auto0(_353_)
            else
            end
            local function loop()
              local _355_ = _3c_21(c)
              if (nil ~= _355_) then
                local res = _355_
                if _3e_21(to, res) then
                  return loop()
                else
                  return nil
                end
              else
                local _0 = _355_
                return true
              end
            end
            if loop() then
              return recur()
            else
              return nil
            end
          else
            local _0 = _349_
            if (close_3f and (nil == _3c_21(closes))) then
              return close_21(to)
            else
              return nil
            end
          end
        end
        return recur()
      end
      go_1_auto(_348_)
    end
    return nil
  end
  local function pipeline_unordered(n, to, xf, from, ...)
    local close_3f, err_handler = nil, nil
    if (select("#", ...) == 0) then
      close_3f, err_handler = true
    else
      close_3f, err_handler = ...
    end
    return pipeline_unordered_2a(n, to, xf, from, close_3f, err_handler, "compute")
  end
  local function pipeline_async_unordered(n, to, af, from, ...)
    local close_3f
    if (select("#", ...) == 0) then
      close_3f = true
    else
      close_3f = ...
    end
    return pipeline_unordered_2a(n, to, af, from, close_3f, nil, "async")
  end
  local function muxch_2a(_)
    return _["muxch*"](_)
  end
  local _local_363_ = {["muxch*"] = muxch_2a}
  local muxch_2a0 = _local_363_["muxch*"]
  local Mux = _local_363_
  local function tap_2a(_, ch, close_3f)
    _G.assert((nil ~= close_3f), "Missing argument close? on ./lib/async.fnl:1339")
    _G.assert((nil ~= ch), "Missing argument ch on ./lib/async.fnl:1339")
    return _["tap*"](_, ch, close_3f)
  end
  local function untap_2a(_, ch)
    _G.assert((nil ~= ch), "Missing argument ch on ./lib/async.fnl:1340")
    return _["untap*"](_, ch)
  end
  local function untap_all_2a(_)
    return _["untap-all*"](_)
  end
  local _local_364_ = {["tap*"] = tap_2a, ["untap*"] = untap_2a, ["untap-all*"] = untap_all_2a}
  local tap_2a0 = _local_364_["tap*"]
  local untap_2a0 = _local_364_["untap*"]
  local untap_all_2a0 = _local_364_["untap-all*"]
  local Mult = _local_364_
  local function mult(ch)
    local dctr = nil
    local atom = {cs = {}}
    local m
    do
      local _365_ = {}
      do
        do
          local _366_ = Mux["muxch*"]
          if (nil ~= _366_) then
            local f_3_auto = _366_
            local function _367_(_)
              return ch
            end
            _365_["muxch*"] = _367_
          else
            local _ = _366_
            error("Protocol Mux doesn't define method muxch*")
          end
        end
        do
          local _369_ = Mult["tap*"]
          if (nil ~= _369_) then
            local f_3_auto = _369_
            local function _370_(_, ch0, close_3f)
              atom["cs"][ch0] = close_3f
              return nil
            end
            _365_["tap*"] = _370_
          else
            local _ = _369_
            error("Protocol Mult doesn't define method tap*")
          end
        end
        do
          local _372_ = Mult["untap*"]
          if (nil ~= _372_) then
            local f_3_auto = _372_
            local function _373_(_, ch0)
              atom["cs"][ch0] = nil
              return nil
            end
            _365_["untap*"] = _373_
          else
            local _ = _372_
            error("Protocol Mult doesn't define method untap*")
          end
        end
        local _375_ = Mult["untap-all*"]
        if (nil ~= _375_) then
          local f_3_auto = _375_
          local function _376_(_)
            atom["cs"] = {}
            return nil
          end
          _365_["untap-all*"] = _376_
        else
          local _ = _375_
          error("Protocol Mult doesn't define method untap-all*")
        end
      end
      local function _378_(_241)
        return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Mux, Mult" .. ">")
      end
      m = setmetatable({}, {__fennelview = _378_, __index = _365_, name = "reify"})
    end
    local dchan = chan(1)
    local done
    local function _379_(_)
      dctr = (dctr - 1)
      if (0 == dctr) then
        return put_21(dchan, true)
      else
        return nil
      end
    end
    done = _379_
    do
      local _let_381_ = require("lib.async")
      local go_1_auto = _let_381_["go"]
      local function _382_()
        local function recur()
          local val = _3c_21(ch)
          if (nil == val) then
            for c, close_3f in pairs(atom.cs) do
              if close_3f then
                close_21(c)
              else
              end
            end
            return nil
          else
            local chs
            do
              local tbl_21_auto = {}
              local i_22_auto = 0
              for k in pairs(atom.cs) do
                local val_23_auto = k
                if (nil ~= val_23_auto) then
                  i_22_auto = (i_22_auto + 1)
                  tbl_21_auto[i_22_auto] = val_23_auto
                else
                end
              end
              chs = tbl_21_auto
            end
            dctr = #chs
            for _, c in ipairs(chs) do
              if not put_21(c, val, done) then
                untap_2a0(m, c)
              else
              end
            end
            if next(chs) then
              _3c_21(dchan)
            else
            end
            return recur()
          end
        end
        return recur()
      end
      go_1_auto(_382_)
    end
    return m
  end
  local function tap(mult0, ch, ...)
    local close_3f
    if (select("#", ...) == 0) then
      close_3f = true
    else
      close_3f = ...
    end
    tap_2a0(mult0, ch, close_3f)
    return ch
  end
  local function untap(mult0, ch)
    return untap_2a0(mult0, ch)
  end
  local function untap_all(mult0)
    return untap_all_2a0(mult0)
  end
  local function admix_2a(_, ch)
    _G.assert((nil ~= ch), "Missing argument ch on ./lib/async.fnl:1403")
    return _["admix*"](_, ch)
  end
  local function solo_mode_2a(_, mode)
    _G.assert((nil ~= mode), "Missing argument mode on ./lib/async.fnl:1407")
    return _["solo-mode*"](_, mode)
  end
  local function toggle_2a(_, state_map)
    _G.assert((nil ~= state_map), "Missing argument state-map on ./lib/async.fnl:1406")
    return _["toggle*"](_, state_map)
  end
  local function unmix_2a(_, ch)
    _G.assert((nil ~= ch), "Missing argument ch on ./lib/async.fnl:1404")
    return _["unmix*"](_, ch)
  end
  local function unmix_all_2a(_)
    return _["unmix-all*"](_)
  end
  local _local_389_ = {["admix*"] = admix_2a, ["solo-mode*"] = solo_mode_2a, ["toggle*"] = toggle_2a, ["unmix*"] = unmix_2a, ["unmix-all*"] = unmix_all_2a}
  local admix_2a0 = _local_389_["admix*"]
  local solo_mode_2a0 = _local_389_["solo-mode*"]
  local toggle_2a0 = _local_389_["toggle*"]
  local unmix_2a0 = _local_389_["unmix*"]
  local unmix_all_2a0 = _local_389_["unmix-all*"]
  local Mix = _local_389_
  local function mix(out)
    local atom = {cs = {}, ["solo-mode"] = "mute"}
    local solo_modes = {mute = true, pause = true}
    local change = chan(sliding_buffer(1))
    local changed
    local function _390_()
      return put_21(change, true)
    end
    changed = _390_
    local pick
    local function _391_(attr, chs)
      local tbl_16_auto = {}
      for c, v in pairs(chs) do
        local k_17_auto, v_18_auto = nil, nil
        if v[attr] then
          k_17_auto, v_18_auto = c, true
        else
          k_17_auto, v_18_auto = nil
        end
        if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
          tbl_16_auto[k_17_auto] = v_18_auto
        else
        end
      end
      return tbl_16_auto
    end
    pick = _391_
    local calc_state
    local function _394_()
      local chs = atom.cs
      local mode = atom["solo-mode"]
      local solos = pick("solo", chs)
      local pauses = pick("pause", chs)
      local _395_
      do
        local tmp_9_auto
        if ((mode == "pause") and next(solos)) then
          local tbl_21_auto = {}
          local i_22_auto = 0
          for k in pairs(solos) do
            local val_23_auto = k
            if (nil ~= val_23_auto) then
              i_22_auto = (i_22_auto + 1)
              tbl_21_auto[i_22_auto] = val_23_auto
            else
            end
          end
          tmp_9_auto = tbl_21_auto
        else
          local tbl_21_auto = {}
          local i_22_auto = 0
          for k in pairs(chs) do
            local val_23_auto
            if not pauses[k] then
              val_23_auto = k
            else
              val_23_auto = nil
            end
            if (nil ~= val_23_auto) then
              i_22_auto = (i_22_auto + 1)
              tbl_21_auto[i_22_auto] = val_23_auto
            else
            end
          end
          tmp_9_auto = tbl_21_auto
        end
        t_2finsert(tmp_9_auto, change)
        _395_ = tmp_9_auto
      end
      return {solos = solos, mutes = pick("mute", chs), reads = _395_}
    end
    calc_state = _394_
    local m
    do
      local _400_ = {}
      do
        do
          local _401_ = Mux["muxch*"]
          if (nil ~= _401_) then
            local f_3_auto = _401_
            local function _402_(_)
              return out
            end
            _400_["muxch*"] = _402_
          else
            local _ = _401_
            error("Protocol Mux doesn't define method muxch*")
          end
        end
        do
          local _404_ = Mix["admix*"]
          if (nil ~= _404_) then
            local f_3_auto = _404_
            local function _405_(_, ch)
              atom.cs[ch] = {}
              return changed()
            end
            _400_["admix*"] = _405_
          else
            local _ = _404_
            error("Protocol Mix doesn't define method admix*")
          end
        end
        do
          local _407_ = Mix["unmix*"]
          if (nil ~= _407_) then
            local f_3_auto = _407_
            local function _408_(_, ch)
              atom.cs[ch] = nil
              return changed()
            end
            _400_["unmix*"] = _408_
          else
            local _ = _407_
            error("Protocol Mix doesn't define method unmix*")
          end
        end
        do
          local _410_ = Mix["unmix-all*"]
          if (nil ~= _410_) then
            local f_3_auto = _410_
            local function _411_(_)
              atom.cs = {}
              return changed()
            end
            _400_["unmix-all*"] = _411_
          else
            local _ = _410_
            error("Protocol Mix doesn't define method unmix-all*")
          end
        end
        do
          local _413_ = Mix["toggle*"]
          if (nil ~= _413_) then
            local f_3_auto = _413_
            local function _414_(_, state_map)
              atom.cs = merge_with(merge_2a, atom.cs, state_map)
              return changed()
            end
            _400_["toggle*"] = _414_
          else
            local _ = _413_
            error("Protocol Mix doesn't define method toggle*")
          end
        end
        local _416_ = Mix["solo-mode*"]
        if (nil ~= _416_) then
          local f_3_auto = _416_
          local function _417_(_, mode)
            if not solo_modes[mode] then
              local _418_
              do
                local tbl_21_auto = {}
                local i_22_auto = 0
                for k in pairs(solo_modes) do
                  local val_23_auto = k
                  if (nil ~= val_23_auto) then
                    i_22_auto = (i_22_auto + 1)
                    tbl_21_auto[i_22_auto] = val_23_auto
                  else
                  end
                end
                _418_ = tbl_21_auto
              end
              assert(false, ("mode must be one of: " .. t_2fconcat(_418_, ", ")))
            else
            end
            atom["solo-mode"] = mode
            return changed()
          end
          _400_["solo-mode*"] = _417_
        else
          local _ = _416_
          error("Protocol Mix doesn't define method solo-mode*")
        end
      end
      local function _422_(_241)
        return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Mux, Mix" .. ">")
      end
      m = setmetatable({}, {__fennelview = _422_, __index = _400_, name = "reify"})
    end
    do
      local _let_424_ = require("lib.async")
      local go_1_auto = _let_424_["go"]
      local function _425_()
        local _2_423_ = calc_state()
        local solos = _2_423_["solos"]
        local mutes = _2_423_["mutes"]
        local reads = _2_423_["reads"]
        local state = _2_423_
        local function recur(_426_)
          local solos0 = _426_["solos"]
          local mutes0 = _426_["mutes"]
          local reads0 = _426_["reads"]
          local state0 = _426_
          local _let_427_ = alts_21(reads0)
          local v = _let_427_[1]
          local c = _let_427_[2]
          local res = _let_427_
          if ((nil == v) or (c == change)) then
            if (nil == v) then
              atom.cs[c] = nil
            else
            end
            return recur(calc_state())
          else
            if (solos0[c] or (not next(solos0) and not mutes0[c])) then
              if _3e_21(out, v) then
                return recur(state0)
              else
                return nil
              end
            else
              return recur(state0)
            end
          end
        end
        return recur(_2_423_)
      end
      go_1_auto(_425_)
    end
    return m
  end
  local function admix(mix0, ch)
    return admix_2a0(mix0, ch)
  end
  local function unmix(mix0, ch)
    return unmix_2a0(mix0, ch)
  end
  local function unmix_all(mix0)
    return unmix_all_2a0(mix0)
  end
  local function toggle(mix0, state_map)
    return toggle_2a0(mix0, state_map)
  end
  local function solo_mode(mix0, mode)
    return solo_mode_2a0(mix0, mode)
  end
  local function sub_2a(_, v, ch, close_3f)
    _G.assert((nil ~= close_3f), "Missing argument close? on ./lib/async.fnl:1508")
    _G.assert((nil ~= ch), "Missing argument ch on ./lib/async.fnl:1508")
    _G.assert((nil ~= v), "Missing argument v on ./lib/async.fnl:1508")
    return _["sub*"](_, v, ch, close_3f)
  end
  local function unsub_2a(_, v, ch)
    _G.assert((nil ~= ch), "Missing argument ch on ./lib/async.fnl:1509")
    _G.assert((nil ~= v), "Missing argument v on ./lib/async.fnl:1509")
    return _["unsub*"](_, v, ch)
  end
  local function unsub_all_2a(_, v)
    _G.assert((nil ~= v), "Missing argument v on ./lib/async.fnl:1510")
    return _["unsub-all*"](_, v)
  end
  local _local_432_ = {["sub*"] = sub_2a, ["unsub*"] = unsub_2a, ["unsub-all*"] = unsub_all_2a}
  local sub_2a0 = _local_432_["sub*"]
  local unsub_2a0 = _local_432_["unsub*"]
  local unsub_all_2a0 = _local_432_["unsub-all*"]
  local Pub = _local_432_
  local function pub(ch, topic_fn, buf_fn)
    local buf_fn0
    local or_433_ = buf_fn
    if not or_433_ then
      local function _434_()
        return nil
      end
      or_433_ = _434_
    end
    buf_fn0 = or_433_
    local atom = {mults = {}}
    local ensure_mult
    local function _435_(topic)
      local _436_ = atom.mults[topic]
      if (nil ~= _436_) then
        local m = _436_
        return m
      elseif (_436_ == nil) then
        local mults = atom.mults
        local m = mult(chan(buf_fn0(topic)))
        do
          mults[topic] = m
        end
        return m
      else
        return nil
      end
    end
    ensure_mult = _435_
    local p
    do
      local _438_ = {}
      do
        do
          local _439_ = Mux["muxch*"]
          if (nil ~= _439_) then
            local f_3_auto = _439_
            local function _440_(_)
              return ch
            end
            _438_["muxch*"] = _440_
          else
            local _ = _439_
            error("Protocol Mux doesn't define method muxch*")
          end
        end
        do
          local _442_ = Pub["sub*"]
          if (nil ~= _442_) then
            local f_3_auto = _442_
            local function _443_(_, topic, ch0, close_3f)
              local m = ensure_mult(topic)
              return tap_2a0(m, ch0, close_3f)
            end
            _438_["sub*"] = _443_
          else
            local _ = _442_
            error("Protocol Pub doesn't define method sub*")
          end
        end
        do
          local _445_ = Pub["unsub*"]
          if (nil ~= _445_) then
            local f_3_auto = _445_
            local function _446_(_, topic, ch0)
              local _447_ = atom.mults[topic]
              if (nil ~= _447_) then
                local m = _447_
                return untap_2a0(m, ch0)
              else
                return nil
              end
            end
            _438_["unsub*"] = _446_
          else
            local _ = _445_
            error("Protocol Pub doesn't define method unsub*")
          end
        end
        local _450_ = Pub["unsub-all*"]
        if (nil ~= _450_) then
          local f_3_auto = _450_
          local function _451_(_, topic)
            if topic then
              atom["mults"][topic] = nil
              return nil
            else
              atom["mults"] = {}
              return nil
            end
          end
          _438_["unsub-all*"] = _451_
        else
          local _ = _450_
          error("Protocol Pub doesn't define method unsub-all*")
        end
      end
      local function _454_(_241)
        return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Mux, Pub" .. ">")
      end
      p = setmetatable({}, {__fennelview = _454_, __index = _438_, name = "reify"})
    end
    do
      local _let_455_ = require("lib.async")
      local go_1_auto = _let_455_["go"]
      local function _456_()
        local function recur()
          local val = _3c_21(ch)
          if (nil == val) then
            for _, m in pairs(atom.mults) do
              close_21(muxch_2a0(m))
            end
            return nil
          else
            local topic = topic_fn(val)
            do
              local _457_ = atom.mults[topic]
              if (nil ~= _457_) then
                local m = _457_
                if not _3e_21(muxch_2a0(m), val) then
                  atom["mults"][topic] = nil
                else
                end
              else
              end
            end
            return recur()
          end
        end
        return recur()
      end
      go_1_auto(_456_)
    end
    return p
  end
  local function sub(pub0, topic, ch, ...)
    local close_3f
    if (select("#", ...) == 0) then
      close_3f = true
    else
      close_3f = ...
    end
    return sub_2a0(pub0, topic, ch, close_3f)
  end
  local function unsub(pub0, topic, ch)
    return unsub_2a0(pub0, topic, ch)
  end
  local function unsub_all(pub0, topic)
    return unsub_all_2a0(pub0, topic)
  end
  local function map(f, chs, buf_or_n)
    local dctr = nil
    local out = chan(buf_or_n)
    local cnt = #chs
    local rets = {n = cnt}
    local dchan = chan(1)
    local done
    do
      local tbl_21_auto = {}
      local i_22_auto = 0
      for i = 1, cnt do
        local val_23_auto
        local function _462_(ret)
          rets[i] = ret
          dctr = (dctr - 1)
          if (0 == dctr) then
            return put_21(dchan, rets)
          else
            return nil
          end
        end
        val_23_auto = _462_
        if (nil ~= val_23_auto) then
          i_22_auto = (i_22_auto + 1)
          tbl_21_auto[i_22_auto] = val_23_auto
        else
        end
      end
      done = tbl_21_auto
    end
    if (0 == cnt) then
      close_21(out)
    else
      local _let_465_ = require("lib.async")
      local go_1_auto = _let_465_["go"]
      local function _466_()
        local function recur()
          dctr = cnt
          for i = 1, cnt do
            local _467_ = pcall(take_21, chs[i], done[i])
            if (_467_ == false) then
              dctr = (dctr - 1)
            else
            end
          end
          local rets0 = _3c_21(dchan)
          local _469_
          do
            local res = false
            for i = 1, rets0.n do
              if res then break end
              res = (nil == rets0[i])
            end
            _469_ = res
          end
          if _469_ then
            return close_21(out)
          else
            _3e_21(out, f(t_2funpack(rets0)))
            return recur()
          end
        end
        return recur()
      end
      go_1_auto(_466_)
    end
    return out
  end
  local function merge(chs, buf_or_n)
    local out = chan(buf_or_n)
    do
      local _let_473_ = require("lib.async")
      local go_1_auto = _let_473_["go"]
      local function _474_()
        local _2_472_ = chs
        local cs = _2_472_
        local function recur(cs0)
          if (#cs0 > 0) then
            local _let_475_ = alts_21(cs0)
            local v = _let_475_[1]
            local c = _let_475_[2]
            if (nil == v) then
              local function _476_()
                local tbl_21_auto = {}
                local i_22_auto = 0
                for _, c_2a in ipairs(cs0) do
                  local val_23_auto
                  if (c_2a ~= c) then
                    val_23_auto = c_2a
                  else
                    val_23_auto = nil
                  end
                  if (nil ~= val_23_auto) then
                    i_22_auto = (i_22_auto + 1)
                    tbl_21_auto[i_22_auto] = val_23_auto
                  else
                  end
                end
                return tbl_21_auto
              end
              return recur(_476_())
            else
              _3e_21(out, v)
              return recur(cs0)
            end
          else
            return close_21(out)
          end
        end
        return recur(_2_472_)
      end
      go_1_auto(_474_)
    end
    return out
  end
  local function into(t, ch)
    local function _481_(_241, _242)
      _241[(1 + #_241)] = _242
      return _241
    end
    return reduce(_481_, t, ch)
  end
  local function take(n, ch, buf_or_n)
    local out = chan(buf_or_n)
    do
      local _let_482_ = require("lib.async")
      local go_1_auto = _let_482_["go"]
      local function _483_()
        local done = false
        for i = 1, n do
          if done then break end
          local _484_ = _3c_21(ch)
          if (nil ~= _484_) then
            local v = _484_
            _3e_21(out, v)
          elseif (_484_ == nil) then
            done = true
          else
          end
        end
        return close_21(out)
      end
      go_1_auto(_483_)
    end
    return out
  end
  return {buffer = buffer, ["dropping-buffer"] = dropping_buffer, ["sliding-buffer"] = sliding_buffer, ["promise-buffer"] = promise_buffer, ["unblocking-buffer?"] = unblocking_buffer_3f, ["main-thread?"] = main_thread_3f, chan = chan, ["chan?"] = chan_3f, ["promise-chan"] = promise_chan, ["take!"] = take_21, ["<!!"] = _3c_21_21, ["<!"] = _3c_21, timeout = timeout, ["put!"] = put_21, [">!!"] = _3e_21_21, [">!"] = _3e_21, ["close!"] = close_21, go = go_2a, ["alts!"] = alts_21, ["offer!"] = offer_21, ["poll!"] = poll_21, pipe = pipe, ["pipeline-async"] = pipeline_async, pipeline = pipeline, ["pipeline-async-unordered"] = pipeline_async_unordered, ["pipeline-unordered"] = pipeline_unordered, reduce = reduce, reduced = reduced, ["reduced?"] = reduced_3f, transduce = transduce, split = split, ["onto-chan!"] = onto_chan_21, ["to-chan!"] = to_chan_21, mult = mult, tap = tap, untap = untap, ["untap-all"] = untap_all, mix = mix, admix = admix, unmix = unmix, ["unmix-all"] = unmix_all, toggle = toggle, ["solo-mode"] = solo_mode, pub = pub, sub = sub, unsub = unsub, ["unsub-all"] = unsub_all, map = map, merge = merge, into = into, take = take, buffers = {FixedBuffer = FixedBuffer, SlidingBuffer = SlidingBuffer, DroppingBuffer = DroppingBuffer, PromiseBuffer = PromiseBuffer}}
end
package.preload["http.utils"] = package.preload["http.utils"] or function(...)
  local _local_487_ = require("lib.async")
  local _3e_21 = _local_487_[">!"]
  local _3c_21 = _local_487_["<!"]
  local _3e_21_21 = _local_487_[">!!"]
  local _3c_21_21 = _local_487_["<!!"]
  local chan = _local_487_["chan"]
  local chan_3f = _local_487_["chan?"]
  local main_thread_3f = _local_487_["main-thread?"]
  local lower = string["lower"]
  local function _3c_21_3f(port)
    if main_thread_3f() then
      return _3c_21_21(port)
    else
      return _3c_21(port)
    end
  end
  local function _3e_21_3f(port, val)
    if main_thread_3f() then
      return _3e_21_21(port, val)
    else
      return _3e_21(port, val)
    end
  end
  local function make_tcp_client(socket_channel)
    local function _490_(_, pattern)
      local ch = chan()
      socket_channel["set-chunk-size"](socket_channel, pattern, ch)
      return _3c_21_3f(ch)
    end
    local function _491_(_, pattern, prefix)
      local ch = chan()
      return ((prefix or "") .. _3c_21_3f(ch))
    end
    local function _492_(_, data, ...)
      local function _495_(...)
        local _493_, _494_ = select("#", ...), ...
        if (_493_ == 0) then
          return data
        elseif ((_493_ == 1) and (nil ~= _494_)) then
          local i = _494_
          return data:sub(i, #data)
        else
          local _0 = _493_
          return data:sub(...)
        end
      end
      return _3e_21_3f(socket_channel, _495_(...))
    end
    local function _497_(_)
      return socket_channel:close()
    end
    local function _498_(_, data)
      return _3e_21_3f(socket_channel, data)
    end
    local function _499_(_241)
      return ("#<" .. tostring(_241):gsub("table", "tcp-client") .. ">")
    end
    return setmetatable({read = _490_, receive = _491_, send = _492_, close = _497_, write = _498_}, {__name = "tcp-client", __fennelview = _499_})
  end
  local function chunked_encoding_3f(transfer_encoding)
    local _500_ = lower((transfer_encoding or ""))
    local and_501_ = (nil ~= _500_)
    if and_501_ then
      local header = _500_
      and_501_ = (header:match("chunked[, ]") or header:match("chunked$"))
    end
    if and_501_ then
      local header = _500_
      return true
    else
      return nil
    end
  end
  return {["make-tcp-client"] = make_tcp_client, ["<!?"] = _3c_21_3f, [">!?"] = _3e_21_3f, ["chunked-encoding?"] = chunked_encoding_3f}
end
package.preload["http.parser"] = package.preload["http.parser"] or function(...)
  local _local_595_ = require("http.readers")
  local make_reader = _local_595_["make-reader"]
  local string_reader = _local_595_["string-reader"]
  local _local_606_ = require("http.headers")
  local decode_value = _local_606_["decode-value"]
  local capitalize_header = _local_606_["capitalize-header"]
  local _local_607_ = require("http.utils")
  local _3c_21_3f = _local_607_["<!?"]
  local chunked_encoding_3f = _local_607_["chunked-encoding?"]
  local _local_608_ = require("lib.async")
  local timeout = _local_608_["timeout"]
  local _local_766_ = require("http.body")
  local body_reader = _local_766_["body-reader"]
  local chunked_body_reader = _local_766_["chunked-body-reader"]
  local format = string["format"]
  local upper = string["upper"]
  local ceil = math["ceil"]
  local function parse_header(line)
    local _767_, _768_ = line:match(" *([^:]+) *: *(.*)")
    if ((nil ~= _767_) and (nil ~= _768_)) then
      local header = _767_
      local value = _768_
      return header, value
    else
      return nil
    end
  end
  local function read_headers(src, _3fheaders)
    local headers = (_3fheaders or {})
    local _770_ = src:read("*l")
    if ((_770_ == "\13") or (_770_ == "")) then
      return headers
    else
      local _3fline = _770_
      local function _773_()
        local _771_, _772_ = parse_header((_3fline or ""))
        if ((nil ~= _771_) and (nil ~= _772_)) then
          local header = _771_
          local value = _772_
          headers[header] = value
          return headers
        else
          return nil
        end
      end
      return read_headers(src, _773_())
    end
  end
  local function parse_response_status_line(status)
    local function loop(reader, fields, res)
      if ((_G.type(fields) == "table") and (nil ~= fields[1])) then
        local field = fields[1]
        local fields0 = {select(2, (table.unpack or _G.unpack)(fields))}
        local part = reader()
        local function _776_()
          if (field == "protocol-version") then
            local name, major, minor = part:match("([^/]+)/(%d).(%d)")
            res[field] = {name = name, major = tonumber(major), minor = tonumber(minor)}
            return res
          else
            local _ = field
            res[field] = decode_value(part)
            return res
          end
        end
        return loop(reader, fields0, _776_())
      else
        local _ = fields
        local reason = status:gsub(format("%s/%s.%s +%s +", res["protocol-version"].name, res["protocol-version"].major, res["protocol-version"].minor, res.status), "")
        res["reason-phrase"] = reason
        return res
      end
    end
    return loop(status:gmatch("([^ ]+)"), {"protocol-version", "status"}, {})
  end
  local function read_response_status_line(src)
    local _778_ = src:read("*l")
    if (nil ~= _778_) then
      local line = _778_
      return parse_response_status_line(line)
    else
      local _ = _778_
      return error("status line was not received from server")
    end
  end
  local function parse_http_response(src, _780_)
    local as = _780_["as"]
    local start = _780_["start"]
    local time = _780_["time"]
    local method = _780_["method"]
    local status = read_response_status_line(src)
    local headers = read_headers(src)
    local parsed_headers
    do
      local tbl_16_auto = {}
      for k, v in pairs(headers) do
        local k_17_auto, v_18_auto = capitalize_header(k), decode_value(v)
        if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
          tbl_16_auto[k_17_auto] = v_18_auto
        else
        end
      end
      parsed_headers = tbl_16_auto
    end
    local stream
    if chunked_encoding_3f(parsed_headers["Transfer-Encoding"]) then
      stream = chunked_body_reader(src)
    else
      stream = body_reader(src)
    end
    status["headers"] = headers
    status["parsed-headers"] = parsed_headers
    status["length"] = tonumber(parsed_headers["Content-Length"])
    status["http-client"] = src
    local _783_
    if (start and time) then
      _783_ = ceil((1000 * (time() - start)))
    else
      _783_ = nil
    end
    status["request-time"] = _783_
    local _785_
    if (upper((method or "")) ~= "HEAD") then
      if (as == "raw") then
        _785_ = stream:read((parsed_headers["Content-Length"] or "*a"))
      elseif ((as == "json") or (as == "stream")) then
        _785_ = stream
      else
        local _ = as
        _785_ = error(format("unsupported coersion method '%s'", as))
      end
    else
      _785_ = nil
    end
    status["body"] = _785_
    return status
  end
  local function parse_request_status_line(status)
    local function loop(reader, fields, res)
      if ((_G.type(fields) == "table") and (nil ~= fields[1])) then
        local field = fields[1]
        local fields0 = {select(2, (table.unpack or _G.unpack)(fields))}
        local part = reader()
        local function _791_()
          res[field] = decode_value(part)
          return res
        end
        return loop(reader, fields0, _791_())
      else
        local _ = fields
        return res
      end
    end
    return loop(status:gmatch("([^ ]+)"), {"method", "path", "http-version"}, {})
  end
  local function read_request_status_line(src)
    local _793_ = src:read("*l")
    if (nil ~= _793_) then
      local line = _793_
      return parse_request_status_line(line)
    else
      return nil
    end
  end
  local function parse_http_request(src)
    local status = read_request_status_line(src)
    local headers = read_headers(src)
    local parsed_headers
    do
      local tbl_16_auto = {}
      for k, v in pairs(headers) do
        local k_17_auto, v_18_auto = capitalize_header(k), decode_value(v)
        if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
          tbl_16_auto[k_17_auto] = v_18_auto
        else
        end
      end
      parsed_headers = tbl_16_auto
    end
    local stream
    if chunked_encoding_3f(parsed_headers["Transfer-Encoding"]) then
      stream = chunked_body_reader(src)
    else
      stream = body_reader(src)
    end
    if ((_G.type(status) == "table") and (nil ~= status.method)) then
      local method = status.method
      status["headers"] = headers
      local _797_
      if (upper((method or "")) ~= "HEAD") then
        _797_ = stream:read((parsed_headers["Content-Length"] or "*a"))
      else
        _797_ = nil
      end
      status["content"] = _797_
      return status
    else
      return nil
    end
  end
  local function parse_authority(authority)
    local userinfo = authority:match("([^@]+)@")
    local port = authority:match(":(%d+)")
    local host
    if userinfo then
      local _800_
      if port then
        _800_ = ":"
      else
        _800_ = ""
      end
      host = authority:match(("@([^:]+)" .. _800_))
    else
      local _802_
      if port then
        _802_ = ":"
      else
        _802_ = ""
      end
      host = authority:match(("([^:]+)" .. _802_))
    end
    return {userinfo = userinfo, port = port, host = host}
  end
  local function parse_url(url)
    local scheme = url:match("^([^:]+)://")
    local function _805_()
      if scheme then
        return url:match("//([^/]+)/?")
      else
        return url:match("^([^/]+)/?")
      end
    end
    local _let_806_ = parse_authority(_805_())
    local host = _let_806_["host"]
    local port = _let_806_["port"]
    local userinfo = _let_806_["userinfo"]
    local function _807_()
      if scheme then
        return {scheme, url}
      else
        return {"http", ("http://" .. url)}
      end
    end
    local _let_808_ = _807_()
    local scheme0 = _let_808_[1]
    local url0 = _let_808_[2]
    local port0
    local or_809_ = port
    if not or_809_ then
      if (scheme0 == "https") then
        or_809_ = 443
      elseif (scheme0 == "http") then
        or_809_ = 80
      else
        or_809_ = nil
      end
    end
    port0 = or_809_
    local path = url0:match("//[^/]+(/[^?#]*)")
    local query = url0:match("%?([^#]+)#?")
    local fragment = url0:match("#([^?]+)%??")
    return {scheme = scheme0, host = host, port = port0, userinfo = userinfo, path = path, query = query, fragment = fragment}
  end
  return {["parse-http-response"] = parse_http_response, ["parse-http-request"] = parse_http_request, ["parse-url"] = parse_url}
end
package.preload["http.readers"] = package.preload["http.readers"] or function(...)
  local function ok_3f(ok_3f0, ...)
    if ok_3f0 then
      return ...
    else
      return nil
    end
  end
  local Reader = {}
  local function make_reader(source, _506_)
    local read_bytes = _506_["read-bytes"]
    local read_line = _506_["read-line"]
    local close = _506_["close"]
    local peek = _506_["peek"]
    local len = _506_["length"]
    local close0
    if close then
      local function _507_(_, ...)
        return ok_3f(pcall(close, source, ...))
      end
      close0 = _507_
    else
      local function _508_()
        return nil
      end
      close0 = _508_
    end
    local _510_
    if read_bytes then
      local function _511_(_, pattern, ...)
        return read_bytes(source, pattern, ...)
      end
      _510_ = _511_
    else
      local function _512_()
        return nil
      end
      _510_ = _512_
    end
    local _514_
    if read_line then
      local function _515_()
        local function _516_(_, ...)
          return read_line(source, ...)
        end
        return _516_
      end
      _514_ = _515_
    else
      local function _517_()
        local function _518_()
          return nil
        end
        return _518_
      end
      _514_ = _517_
    end
    local _520_
    if peek then
      local function _521_(_, pattern, ...)
        return peek(source, pattern, ...)
      end
      _520_ = _521_
    else
      local function _522_()
        return nil
      end
      _520_ = _522_
    end
    local _524_
    if len then
      local function _525_()
        return len(source)
      end
      _524_ = _525_
    else
      local function _526_()
        return nil
      end
      _524_ = _526_
    end
    local _528_
    if len then
      local function _529_()
        return len(source)
      end
      _528_ = _529_
    else
      local function _530_()
        return nil
      end
      _528_ = _530_
    end
    local function _532_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "Reader:") .. ">")
    end
    return setmetatable({close = close0, read = _510_, lines = _514_, peek = _520_, length = _524_}, {__index = Reader, __close = close0, __len = _528_, __name = "Reader", __fennelview = _532_})
  end
  local open = io["open"]
  local function file_reader(file)
    local file0
    do
      local _533_ = type(file)
      if (_533_ == "string") then
        file0 = open(file, "r")
      else
        local _ = _533_
        file0 = file
      end
    end
    local open_3f
    local function _535_(_241)
      local function _536_(_2410)
        return _2410:read(0)
      end
      return (pcall(_536_, _241))
    end
    open_3f = _535_
    local function _537_(_241)
      if open_3f(_241) then
        return _241:close()
      else
        return nil
      end
    end
    local function _539_(f, pattern)
      if open_3f(f) then
        return f:read(pattern)
      else
        return nil
      end
    end
    local function _541_(f)
      local next_line
      if open_3f(f) then
        next_line = file0:lines()
      else
        next_line = nil
      end
      if open_3f(f) then
        return next_line()
      else
        return nil
      end
    end
    local function _544_(f, pattern)
      assert(("number" == type(pattern)), "expected number of bytes to peek")
      if open_3f(f) then
        local res = f:read(pattern)
        f:seek("cur", ( - pattern))
        return res
      else
        return nil
      end
    end
    local function _546_(f)
      if open_3f(f) then
        local current = f:seek("cur")
        local len = (f:seek("end") - current)
        f:seek("cur", ( - len))
        return len
      else
        return nil
      end
    end
    return make_reader(file0, {close = _537_, ["read-bytes"] = _539_, ["read-line"] = _541_, peek = _544_, length = _546_})
  end
  local max = math["max"]
  local function string_reader(string)
    assert(("string" == type(string)), "expected a string as first argument")
    local i, closed_3f = 1, false
    local len = #string
    local try_read_line
    local function _548_(s, pattern)
      local _549_, _550_, _551_ = s:find(pattern, i)
      if (true and (nil ~= _550_) and (nil ~= _551_)) then
        local _ = _549_
        local _end = _550_
        local s0 = _551_
        i = (_end + 1)
        return s0
      else
        return nil
      end
    end
    try_read_line = _548_
    local read_line
    local function _553_(s)
      if (i <= len) then
        return (try_read_line(s, "(.-)\13?\n") or try_read_line(s, "(.-)\13?$"))
      else
        return nil
      end
    end
    read_line = _553_
    local function _555_(_)
      if not closed_3f then
        i = (len + 1)
        closed_3f = true
        return closed_3f
      else
        return nil
      end
    end
    local function _557_(s, pattern)
      if (i <= len) then
        if ((pattern == "*l") or (pattern == "l")) then
          return read_line(s)
        elseif ((pattern == "*a") or (pattern == "a")) then
          return s:sub(i)
        else
          local and_558_ = (nil ~= pattern)
          if and_558_ then
            local bytes = pattern
            and_558_ = ("number" == type(bytes))
          end
          if and_558_ then
            local bytes = pattern
            local res = s:sub(i, (i + bytes + -1))
            i = (i + bytes)
            return res
          else
            return nil
          end
        end
      else
        return nil
      end
    end
    local function _562_(s, pattern)
      if (i <= len) then
        local and_563_ = (nil ~= pattern)
        if and_563_ then
          local bytes = pattern
          and_563_ = ("number" == type(bytes))
        end
        if and_563_ then
          local bytes = pattern
          local res = s:sub(i, (i + bytes + -1))
          return res
        else
          local _ = pattern
          return error("expected number of bytes to peek")
        end
      else
        return nil
      end
    end
    local function _567_(s)
      if not closed_3f then
        return max(0, (#s - (i - 1)))
      else
        return nil
      end
    end
    return make_reader(string, {close = _555_, ["read-bytes"] = _557_, ["read-line"] = read_line, peek = _562_, length = _567_})
  end
  local ltn_3f, ltn12 = pcall(require, "ltn12")
  local sink_2ftable = ltn12.sink["table"]
  local sink_2fnull = ltn12.sink["null"]
  local concat = table["concat"]
  local function ltn12_reader(source, step)
    local step0 = (step or ltn12.pump.step)
    local buffer = ""
    local closed_3f = false
    local function read(_, pattern)
      if not closed_3f then
        local rdr = string_reader(buffer)
        local content = rdr:read(pattern)
        local len = #(content or "")
        local data = {}
        local and_569_ = (nil ~= pattern)
        if and_569_ then
          local bytes = pattern
          and_569_ = ("number" == type(bytes))
        end
        if and_569_ then
          local bytes = pattern
          buffer = (rdr:read("*a") or "")
          if (len < pattern) then
            if step0(source, sink_2ftable(data)) then
              buffer = (buffer .. (data[1] or ""))
              local _571_ = read(_, (bytes - len))
              local and_572_ = (nil ~= _571_)
              if and_572_ then
                local data0 = _571_
                and_572_ = data0
              end
              if and_572_ then
                local data0 = _571_
                return ((content or "") .. data0)
              else
                local _0 = _571_
                return content
              end
            else
              return content
            end
          else
            return content
          end
        elseif ((pattern == "*a") or (pattern == "a")) then
          buffer = (rdr:read("*a") or "")
          while step0(source, sink_2ftable(data)) do
          end
          return ((content or "") .. concat(data))
        elseif ((pattern == "*l") or (pattern == "l")) then
          if buffer:match("\n") then
            buffer = (rdr:read("*a") or "")
            return content
          else
            if step0(source, sink_2ftable(data)) then
              buffer = (buffer .. (data[1] or ""))
              local _577_ = read(_, pattern)
              if (nil ~= _577_) then
                local data0 = _577_
                return ((content or "") .. data0)
              else
                local _0 = _577_
                return content
              end
            else
              buffer = (rdr:read("*a") or "")
              return content
            end
          end
        else
          return nil
        end
      else
        return nil
      end
    end
    local function _583_()
      while step0(source, sink_2fnull()) do
      end
      closed_3f = true
      return nil
    end
    local function _584_(_241)
      if not closed_3f then
        return read(_241, "*l")
      else
        return nil
      end
    end
    local function peek(_, bytes)
      if not closed_3f then
        local rdr = string_reader(buffer)
        local content = rdr:peek(bytes)
        local len = #(content or "")
        local data = {}
        if (len < bytes) then
          if step0(source, sink_2ftable(data)) then
            buffer = (buffer .. (data[1] or ""))
            local _586_ = peek(_, (bytes - len))
            local and_587_ = (nil ~= _586_)
            if and_587_ then
              local data0 = _586_
              and_587_ = data0
            end
            if and_587_ then
              local data0 = _586_
              return data0
            else
              local _0 = _586_
              return content
            end
          else
            return content
          end
        else
          return content
        end
      else
        return nil
      end
    end
    return make_reader(source, {close = _583_, ["read-bytes"] = read, ["read-line"] = _584_, peek = peek})
  end
  local function reader_3f(obj)
    local _593_ = getmetatable(obj)
    if ((_G.type(_593_) == "table") and (_593_.__index == Reader)) then
      return true
    else
      local _ = _593_
      return false
    end
  end
  return {["make-reader"] = make_reader, ["file-reader"] = file_reader, ["string-reader"] = string_reader, ["reader?"] = reader_3f, ["ltn12-reader"] = (ltn_3f and ltn12_reader)}
end
package.preload["http.headers"] = package.preload["http.headers"] or function(...)
  local lower = string["lower"]
  local gsub = string["gsub"]
  local upper = string["upper"]
  local concat = table["concat"]
  local function __3ekebab_case(str)
    local function _596_()
      local res,case_change_3f = "", false
      for c in str:gmatch(".") do
        local function _597_()
          local delim_3f = c:match("[-_ ]")
          local upper_3f = (c == c:upper())
          if delim_3f then
            return {(res .. "-"), nil}
          elseif (upper_3f and case_change_3f) then
            return {(res .. "-" .. c:lower()), nil}
          else
            return {(res .. c:lower()), (not upper_3f and true)}
          end
        end
        local _set_599_ = _597_()
        res = _set_599_[1]
        case_change_3f = _set_599_[2]
      end
      return {res, case_change_3f}
    end
    local _let_600_ = _596_()
    local res = _let_600_[1]
    return res
  end
  local function capitalize_header(header)
    local header0 = __3ekebab_case(header)
    local _601_
    do
      local tbl_21_auto = {}
      local i_22_auto = 0
      for word in header0:gmatch("[^-]+") do
        local val_23_auto = gsub(lower(word), "^%l", upper)
        if (nil ~= val_23_auto) then
          i_22_auto = (i_22_auto + 1)
          tbl_21_auto[i_22_auto] = val_23_auto
        else
        end
      end
      _601_ = tbl_21_auto
    end
    return concat(_601_, "-")
  end
  local function decode_value(value)
    local _603_ = tonumber(value)
    if (nil ~= _603_) then
      local n = _603_
      return n
    else
      local _ = _603_
      if (value == "true") then
        return true
      elseif (value == "false") then
        return false
      else
        local _0 = value
        return value
      end
    end
  end
  return {["decode-value"] = decode_value, ["capitalize-header"] = capitalize_header}
end
package.preload["http.body"] = package.preload["http.body"] or function(...)
  local _local_613_ = require("http.builder")
  local headers__3estring = _local_613_["headers->string"]
  local _local_614_ = require("http.readers")
  local reader_3f = _local_614_["reader?"]
  local file_reader = _local_614_["file-reader"]
  local string_reader = _local_614_["string-reader"]
  local make_reader = _local_614_["make-reader"]
  local _local_684_ = require("http.url")
  local urlencode = _local_684_["urlencode"]
  local _local_685_ = require("lib.async")
  local chan_3f = _local_685_["chan?"]
  local timeout = _local_685_["timeout"]
  local _local_686_ = require("http.utils")
  local _3c_21_3f = _local_686_["<!?"]
  local chunked_encoding_3f = _local_686_["chunked-encoding?"]
  local format = string.format
  local function get_chunk_data(src)
    if chan_3f(src) then
      return _3c_21_3f(src)
    elseif reader_3f(src) then
      return src:read(1024)
    else
      return error(("unsupported source type: " .. type(src)))
    end
  end
  local function format_chunk(src)
    local data_3f = get_chunk_data(src)
    local data = (data_3f or "")
    return not data_3f, format("%x\13\n%s\13\n", #data, data)
  end
  local function stream_chunks(dst, src)
    local last_chunk_3f, data = format_chunk(src)
    dst:write(data)
    if not last_chunk_3f then
      return stream_chunks(dst, src)
    else
      return nil
    end
  end
  local function stream_reader(dst, src, remaining)
    local _689_
    local function _690_()
      if (1024 < remaining) then
        return 1024
      else
        return remaining
      end
    end
    _689_ = src:read(_690_())
    if (nil ~= _689_) then
      local data = _689_
      dst:write(data)
      if (remaining > 0) then
        return stream_reader(dst, src, (remaining - #data))
      else
        return nil
      end
    else
      return nil
    end
  end
  local function stream_channel(dst, src, remaining)
    local _693_ = _3c_21_3f(src)
    if (nil ~= _693_) then
      local data = _693_
      local data0
      if (#data < remaining) then
        data0 = data
      else
        data0 = data:sub(1, remaining)
      end
      local remaining0 = (remaining - #data0)
      dst:write(data0)
      if (remaining0 > 0) then
        return stream_channel(dst, src, remaining0)
      else
        return nil
      end
    else
      return nil
    end
  end
  local function stream_body(dst, body, _697_)
    local transfer_encoding = _697_["transfer-encoding"]
    local content_length = _697_["content-length"]
    if body then
      if (("string" == type(transfer_encoding)) and chunked_encoding_3f(transfer_encoding) and (transfer_encoding:match("chunked[, ]") or transfer_encoding:match("chunked$"))) then
        return stream_chunks(dst, body)
      elseif (content_length and reader_3f(body)) then
        return stream_reader(dst, body, content_length)
      elseif (content_length and chan_3f(body)) then
        return stream_channel(dst, body, content_length)
      else
        return nil
      end
    else
      return nil
    end
  end
  local function guess_content_type(body)
    if (type(body) == "string") then
      return "text/plain; charset=UTF-8"
    elseif (chan_3f(body) or reader_3f(body)) then
      return "application/octet-stream"
    else
      return error(("Unsupported body type" .. type(body)), 2)
    end
  end
  local function guess_transfer_encoding(body)
    if (type(body) == "string") then
      return "8bit"
    elseif (chan_3f(body) or reader_3f(body)) then
      return "binary"
    else
      return error(("Unsupported body type" .. type(body)), 2)
    end
  end
  local function wrap_body(body)
    local _702_ = type(body)
    if (_702_ == "table") then
      if chan_3f(body) then
        return body
      elseif reader_3f(body) then
        return body
      else
        return body
      end
    elseif (_702_ == "userdata") then
      local _704_ = getmetatable(body)
      if ((_G.type(_704_) == "table") and (_704_.__name == "FILE*")) then
        return file_reader(body)
      else
        local _ = _704_
        return body
      end
    else
      local _ = _702_
      return body
    end
  end
  local function format_multipart_part(_707_, boundary)
    local name = _707_["name"]
    local filename = _707_["filename"]
    local filename_2a = _707_["filename*"]
    local content = _707_["content"]
    local content_length = _707_["length"]
    local headers = _707_["headers"]
    local mime_type = _707_["mime-type"]
    local content0 = wrap_body(content)
    local function _713_()
      local tbl_16_auto
      local _708_
      if filename then
        _708_ = format("; filename=%q", filename)
      else
        _708_ = ""
      end
      local function _710_()
        if filename_2a then
          return format("; filename*=%s", urlencode(filename_2a))
        else
          return ""
        end
      end
      local _711_
      if ("string" == type(content0)) then
        _711_ = #content0
      else
        _711_ = (content_length or content0:length())
      end
      tbl_16_auto = {["content-disposition"] = format("form-data; name=%q%s%s", name, _708_, _710_()), ["content-length"] = _711_, ["content-type"] = (mime_type or guess_content_type(content0)), ["content-transfer-encoding"] = guess_transfer_encoding(content0)}
      for k, v in pairs((headers or {})) do
        local k_17_auto, v_18_auto = k, v
        if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
          tbl_16_auto[k_17_auto] = v_18_auto
        else
        end
      end
      return tbl_16_auto
    end
    return format("--%s\13\n%s\13\n", boundary, headers__3estring(_713_()))
  end
  local function multipart_content_length(multipart, boundary)
    local _715_
    do
      local total = 0
      for _, _716_ in ipairs(multipart) do
        local content_length = _716_["length"]
        local name = _716_["name"]
        local content = _716_["content"]
        local part = _716_
        local content0 = wrap_body(content)
        local _717_
        if ("string" == type(content0)) then
          _717_ = (#content0 + 2)
        elseif reader_3f(content0) then
          _717_ = (2 + (content_length or content0:length() or error(format("can't determine length for multipart content %q", name), 2)))
        elseif (nil ~= content_length) then
          _717_ = (content_length + 2)
        else
          _717_ = error(format("missing length field on non-string multipart content %q", name), 2)
        end
        total = (total + #format_multipart_part(part, boundary) + _717_)
      end
      _715_ = total
    end
    return (_715_ + #format("--%s--\13\n", boundary))
  end
  local function stream_multipart(dst, multipart, boundary)
    for _, _719_ in ipairs(multipart) do
      local name = _719_["name"]
      local filename = _719_["filename"]
      local content = _719_["content"]
      local content_length = _719_["length"]
      local mime_type = _719_["mime-type"]
      local part = _719_
      assert((nil ~= content), "Multipart content cannot be nil")
      assert(name, "Multipart body must contain at least content and name")
      do
        local content0 = wrap_body(content)
        local _720_
        if ("string" == type(content0)) then
          _720_ = content0
        else
          _720_ = ""
        end
        dst:write((format_multipart_part(part, boundary) .. _720_))
        if ("string" ~= type(content0)) then
          stream_body(dst, content0, {["content-length"] = (content_length or content0:length())})
        else
        end
      end
      dst:write("\13\n")
    end
    return dst:write(format("--%s--\13\n", boundary))
  end
  local function body_reader(src)
    local buffer = ""
    local function _723_(src0, pattern)
      local rdr = string_reader(buffer)
      local buffer_content = rdr:read(pattern)
      local and_724_ = (nil ~= pattern)
      if and_724_ then
        local n = pattern
        and_724_ = ("number" == type(n))
      end
      if and_724_ then
        local n = pattern
        local len
        if buffer_content then
          len = #buffer_content
        else
          len = 0
        end
        local read_more_3f = (len < n)
        buffer = buffer:sub((len + 1))
        if read_more_3f then
          if buffer_content then
            return (buffer_content .. (src0:read((n - len)) or ""))
          else
            return src0:read((n - len))
          end
        else
          return buffer_content
        end
      elseif ((pattern == "*l") or (pattern == "l")) then
        local read_more_3f = not buffer:find("\n")
        if buffer_content then
          buffer = buffer:sub((#buffer_content + 2))
        else
        end
        if read_more_3f then
          if buffer_content then
            return (buffer_content .. (src0:read(pattern) or ""))
          else
            return src0:read(pattern)
          end
        else
          return buffer_content
        end
      elseif ((pattern == "*a") or (pattern == "a")) then
        buffer = ""
        local _732_ = src0:read(pattern)
        if (_732_ == nil) then
          if buffer_content then
            return buffer_content
          else
            return nil
          end
        elseif (nil ~= _732_) then
          local data = _732_
          return ((buffer_content or "") .. data)
        else
          return nil
        end
      else
        local _ = pattern
        return error(("unsupported pattern: " .. tostring(pattern)))
      end
    end
    local function _736_(src0)
      local rdr = string_reader(buffer)
      local buffer_content = rdr:read("*l")
      local read_more_3f = not buffer:find("\n")
      if buffer_content then
        buffer = buffer:sub((#buffer_content + 2))
      else
      end
      if read_more_3f then
        if buffer_content then
          return (buffer_content .. (src0:read("*l") or ""))
        else
          return src0:read("*l")
        end
      else
        return buffer_content
      end
    end
    local function _740_(src0)
      return src0:close()
    end
    local function _741_(src0, bytes)
      assert(("number" == type(bytes)), "expected number of bytes to peek")
      local rdr = string_reader(buffer)
      local content = (rdr:read(bytes) or "")
      local len = #content
      if (bytes == len) then
        return content
      else
        local data = src0:read((bytes - len))
        buffer = (buffer .. (data or ""))
        return buffer
      end
    end
    return make_reader(src, {["read-bytes"] = _723_, ["read-line"] = _736_, close = _740_, peek = _741_})
  end
  local function read_chunk_size(src)
    local _743_ = src:read("*l")
    if ((_743_ == "") or (_743_ == "\13")) then
      return read_chunk_size(src)
    elseif (nil ~= _743_) then
      local line = _743_
      local _744_ = line:match("%s*([0-9a-fA-F]+)")
      if (nil ~= _744_) then
        local size = _744_
        return tonumber(("0x" .. size))
      else
        local _ = _744_
        return error(format("line missing chunk size: %s", line))
      end
    else
      local _ = _743_
      return error("source was exchausted while reading chunk size")
    end
  end
  local function chunked_body_reader(src)
    local buffer = ""
    local chunk_size = nil
    local more_3f = true
    local read_in_progress_3f = false
    local function read_next_chunk()
      while read_in_progress_3f do
        _3c_21_3f(timeout(10))
      end
      if more_3f then
        read_in_progress_3f = true
        chunk_size = read_chunk_size(src)
        if (chunk_size > 0) then
          buffer = (buffer .. (src:read(chunk_size) or ""))
        else
          local function read_entity_headers(line)
            if ((line == "") or (line == "\13")) then
              more_3f = false
              return nil
            else
              local _ = line
              return read_entity_headers(src:read("*l"))
            end
          end
          read_entity_headers()
        end
        read_in_progress_3f = false
      else
      end
      return (chunk_size > 0), string_reader(buffer)
    end
    local function read_bytes(_, pattern)
      local number_3f = ("number" == type(pattern))
      local rdr = string_reader(buffer)
      local _750_, _751_ = pattern, number_3f
      if ((_750_ == "*l") or (_750_ == "l") or (true and (_751_ == true))) then
        local read_more_3f
        if number_3f then
          read_more_3f = (#buffer < pattern)
        else
          read_more_3f = buffer:find("\n", nil, true)
        end
        if read_more_3f then
          local _753_, _754_ = read_next_chunk()
          if (_753_ == true) then
            return read_bytes(_, pattern)
          elseif ((_753_ == false) and (nil ~= _754_)) then
            local rdr0 = _754_
            local content = rdr0:read(pattern)
            buffer = (rdr0:read("*a") or "")
            return content
          else
            return nil
          end
        else
          local content = rdr:read(pattern)
          buffer = (rdr:read("*a") or "")
          return content
        end
      elseif ((_750_ == "*a") or (_750_ == "a")) then
        while read_next_chunk() do
        end
        local rdr0 = string_reader(buffer)
        buffer = ""
        return rdr0:read("*a")
      else
        local _0 = _750_
        return error(("unsupported pattern: " .. tostring(pattern)))
      end
    end
    local function read_line(src0)
      local rdr = string_reader(buffer)
      local has_newline_3f = buffer:find("\n", nil, true)
      if has_newline_3f then
        local _758_, _759_ = read_next_chunk()
        if (_758_ == true) then
          return read_line(src0)
        elseif ((_758_ == false) and (nil ~= _759_)) then
          local rdr0 = _759_
          local content = rdr0:read("*l")
          buffer = (rdr0:read("*a") or "")
          return content
        else
          return nil
        end
      else
        local content = rdr:read("*l")
        buffer = (rdr:read("*a") or "")
        return content
      end
    end
    local function peek(_, bytes)
      assert(("number" == type(bytes)), "expected number of bytes to peek")
      local rdr = string_reader(buffer)
      if (#buffer < bytes) then
        local _762_, _763_ = read_next_chunk()
        if (_762_ == true) then
          return peek(_, bytes)
        elseif ((_762_ == false) and (nil ~= _763_)) then
          local rdr0 = _763_
          return rdr0:peek(bytes)
        else
          return nil
        end
      else
        return rdr:peek(bytes)
      end
    end
    local function close(src0)
      return src0:close()
    end
    return make_reader(src, {["read-bytes"] = read_bytes, peek = peek, ["read-line"] = read_line, close = close})
  end
  return {["stream-body"] = stream_body, ["format-chunk"] = format_chunk, ["stream-multipart"] = stream_multipart, ["multipart-content-length"] = multipart_content_length, ["wrap-body"] = wrap_body, ["body-reader"] = body_reader, ["chunked-body-reader"] = chunked_body_reader}
end
package.preload["http.builder"] = package.preload["http.builder"] or function(...)
  local HTTP_VERSION = "HTTP/1.1"
  local _local_609_ = require("http.headers")
  local capitalize_header = _local_609_["capitalize-header"]
  local format = string["format"]
  local upper = string["upper"]
  local concat = table["concat"]
  local sort = table["sort"]
  local function header__3estring(header, value)
    return (capitalize_header(header) .. ": " .. tostring(value) .. "\13\n")
  end
  local function sort_headers(h1, h2)
    return (h1:match("^[^:]+") < h2:match("^[^:]+"))
  end
  local function headers__3estring(headers)
    if (headers and next(headers)) then
      local function _611_()
        local tmp_9_auto
        do
          local tbl_21_auto = {}
          local i_22_auto = 0
          for header, value in pairs(headers) do
            local val_23_auto = header__3estring(header, value)
            if (nil ~= val_23_auto) then
              i_22_auto = (i_22_auto + 1)
              tbl_21_auto[i_22_auto] = val_23_auto
            else
            end
          end
          tmp_9_auto = tbl_21_auto
        end
        sort(tmp_9_auto, sort_headers)
        return tmp_9_auto
      end
      return concat(_611_())
    else
      return nil
    end
  end
  local function build_http_request(method, request_target, _3fheaders, _3fcontent)
    return format("%s %s %s\13\n%s\13\n%s", upper(method), request_target, HTTP_VERSION, (headers__3estring(_3fheaders) or ""), (_3fcontent or ""))
  end
  local function build_http_response(status, reason, _3fheaders, _3fcontent)
    return format("%s %s %s\13\n%s\13\n%s", HTTP_VERSION, tostring(status), reason, (headers__3estring(_3fheaders) or ""), (_3fcontent or ""))
  end
  return {["build-http-response"] = build_http_response, ["build-http-request"] = build_http_request, ["headers->string"] = headers__3estring}
end
package.preload["http.url"] = package.preload["http.url"] or function(...)
  local concat = table["concat"]
  local insert = table["insert"]
  local sort = table["sort"]
  local function urlencode(str, allowed_char_pattern)
    assert(("string" == type(str)), "expected string as a first argument")
    local function _615_(_241)
      return ("%%%X"):format(_241:byte())
    end
    return (str:gsub((allowed_char_pattern or "[^%w._~-]"), _615_))
  end
  local function sequential_3f(val, _3fmax)
    local and_616_ = ("table" == type(val))
    if and_616_ then
      local _617_ = #val
      if (_617_ == 0) then
        and_616_ = false
      elseif (nil ~= _617_) then
        local len = _617_
        local max = (_3fmax or len)
        local _622_ = next(val, max)
        local and_624_ = (nil ~= _622_)
        if and_624_ then
          local k = _622_
          and_624_ = ("number" == type(k))
        end
        if and_624_ then
          local k = _622_
          and_616_ = sequential_3f(val, k)
        elseif (_622_ == nil) then
          and_616_ = true
        else
          local _ = _622_
          and_616_ = false
        end
      else
        and_616_ = nil
      end
    end
    return and_616_
  end
  local function multi_param_entries(key, vals)
    local key0 = urlencode(tostring(key))
    local tbl_21_auto = {}
    local i_22_auto = 0
    for _, v in pairs(vals) do
      local val_23_auto = (key0 .. "=" .. urlencode(tostring(v)))
      if (nil ~= val_23_auto) then
        i_22_auto = (i_22_auto + 1)
        tbl_21_auto[i_22_auto] = val_23_auto
      else
      end
    end
    return tbl_21_auto
  end
  local function sort_query_params(_632_, _633_)
    local k1 = _632_[1]
    local k2 = _633_[1]
    return (k1 < k2)
  end
  local function generate_query_string(params)
    if params then
      local ordered
      do
        local tmp_9_auto
        do
          local tbl_21_auto = {}
          local i_22_auto = 0
          for k, v in pairs(params) do
            local val_23_auto = {k, v}
            if (nil ~= val_23_auto) then
              i_22_auto = (i_22_auto + 1)
              tbl_21_auto[i_22_auto] = val_23_auto
            else
            end
          end
          tmp_9_auto = tbl_21_auto
        end
        sort(tmp_9_auto, sort_query_params)
        ordered = tmp_9_auto
      end
      local _635_
      do
        local res = {}
        for _, _636_ in ipairs(ordered) do
          local k = _636_[1]
          local v = _636_[2]
          if sequential_3f(v) then
            for _0, param in ipairs(multi_param_entries(k, v)) do
              insert(res, param)
            end
          else
            insert(res, (urlencode(tostring(k)) .. "=" .. urlencode(tostring(v))))
          end
          res = res
        end
        _635_ = res
      end
      return concat(_635_, "&")
    else
      return nil
    end
  end
  local function merge_query_params(_3fquery_a, _3fquery_b)
    if ((nil ~= _3fquery_a) or (nil ~= _3fquery_b)) then
      local query
      do
        local tbl_16_auto = {}
        for k, v in pairs((_3fquery_a or {})) do
          local k_17_auto, v_18_auto = k, v
          if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
            tbl_16_auto[k_17_auto] = v_18_auto
          else
          end
        end
        query = tbl_16_auto
      end
      for k, v in pairs((_3fquery_b or {})) do
        local _640_ = query[k]
        if ((_G.type(_640_) == "table") and (nil ~= _640_[1])) then
          local val = _640_[1]
          local t = _640_
          local _641_
          if sequential_3f(v) then
            local tbl_19_auto = t
            for _, val0 in ipairs(v) do
              local val_20_auto = val0
              table.insert(tbl_19_auto, val_20_auto)
            end
            _641_ = tbl_19_auto
          else
            insert(t, v)
            _641_ = t
          end
          query[k] = _641_
          query = query
        elseif (nil ~= _640_) then
          local val = _640_
          local _644_
          if sequential_3f(v) then
            local tbl_19_auto = {val}
            for _, val_2a in ipairs(v) do
              local val_20_auto = val_2a
              table.insert(tbl_19_auto, val_20_auto)
            end
            _644_ = tbl_19_auto
          else
            _644_ = {val, v}
          end
          query[k] = _644_
          query = query
        elseif (_640_ == nil) then
          query[k] = v
          query = query
        else
          query = nil
        end
      end
      return query
    else
      return nil
    end
  end
  local function parse_query_string(query)
    if query then
      local res = {}
      for key_value in query:gmatch("[^&]+") do
        local k, v = key_value:match("([^=]+)=?(.*)")
        local _650_
        do
          local _649_ = res[k]
          if ((_G.type(_649_) == "table") and (nil ~= _649_[1])) then
            local val = _649_[1]
            local t = _649_
            insert(t, v)
            _650_ = t
          elseif (nil ~= _649_) then
            local val = _649_
            _650_ = {val, v}
          elseif (_649_ == nil) then
            _650_ = v
          else
            _650_ = nil
          end
        end
        res[k] = _650_
        res = res
      end
      return res
    else
      return nil
    end
  end
  local function parse_authority(authority)
    local userinfo = authority:match("([^@]+)@")
    local port = authority:match(":(%d+)")
    local host
    if userinfo then
      local _656_
      if port then
        _656_ = ":"
      else
        _656_ = ""
      end
      host = authority:match(("@([^:?#]+)" .. _656_))
    else
      local _658_
      if port then
        _658_ = ":"
      else
        _658_ = ""
      end
      host = authority:match(("([^:?#]+)" .. _658_))
    end
    return {userinfo = userinfo, port = port, host = host}
  end
  local function url__3estring(_661_)
    local scheme = _661_["scheme"]
    local host = _661_["host"]
    local port = _661_["port"]
    local userinfo = _661_["userinfo"]
    local path = _661_["path"]
    local query = _661_["query"]
    local fragment = _661_["fragment"]
    local _662_
    if userinfo then
      _662_ = (userinfo .. "@")
    else
      _662_ = ""
    end
    local _664_
    if port then
      _664_ = (":" .. port)
    else
      _664_ = ""
    end
    local _667_
    do
      local _666_ = generate_query_string(query)
      if (nil ~= _666_) then
        local query0 = _666_
        _667_ = ("?" .. query0)
      else
        local _ = _666_
        _667_ = ""
      end
    end
    local _671_
    if fragment then
      _671_ = ("#" .. fragment)
    else
      _671_ = ""
    end
    return (scheme .. "://" .. _662_ .. host .. _664_ .. (path or "") .. _667_ .. _671_)
  end
  local function parse_url(url)
    local scheme = url:match("^([^:]+)://")
    local function _673_()
      if scheme then
        return url:match("//([^/]+)/?")
      else
        return url:match("^([^/]+)/?")
      end
    end
    local _let_674_ = parse_authority(_673_())
    local host = _let_674_["host"]
    local port = _let_674_["port"]
    local userinfo = _let_674_["userinfo"]
    local function _675_()
      if scheme then
        return {scheme, url}
      else
        return {"http", ("http://" .. url)}
      end
    end
    local _let_676_ = _675_()
    local scheme0 = _let_676_[1]
    local url0 = _let_676_[2]
    local port0
    local or_677_ = port
    if not or_677_ then
      if (scheme0 == "https") then
        or_677_ = 443
      elseif (scheme0 == "http") then
        or_677_ = 80
      else
        or_677_ = nil
      end
    end
    port0 = or_677_
    local path = url0:match("//[^/]+(/[^?#]*)")
    local query = parse_query_string(url0:match("%?([^#]+)#?"))
    local fragment = url0:match("#([^?]+)%??")
    return setmetatable({scheme = scheme0, host = host, port = port0, userinfo = userinfo, path = path, query = query, fragment = fragment}, {__tostring = url__3estring})
  end
  local function format_path(_681_, query_params)
    local path = _681_["path"]
    local query = _681_["query"]
    local fragment = _681_["fragment"]
    local _682_
    if (query or query_params) then
      _682_ = ("?" .. generate_query_string(merge_query_params(query, query_params)))
    else
      _682_ = ""
    end
    return ((path or "/") .. _682_)
  end
  return {urlencode = urlencode, ["parse-url"] = parse_url, ["format-path"] = format_path}
end
package.preload["http.tcp"] = package.preload["http.tcp"] or function(...)
  local _local_815_ = require("lib.async")
  local chan = _local_815_["chan"]
  local _3c_21 = _local_815_["<!"]
  local _3e_21 = _local_815_[">!"]
  local offer_21 = _local_815_["offer!"]
  local timeout = _local_815_["timeout"]
  local close_21 = _local_815_["close!"]
  local _local_816_ = require("http.utils")
  local _3e_21_3f = _local_816_[">!?"]
  local _local_817_ = require("socket")
  local s_2fselect = _local_817_["select"]
  local s_2fconnect = _local_817_["connect"]
  local socket = _local_817_
  local function chunk_setter(ch)
    local function set_chunk_size(_, pattern_or_size, out)
      return _3e_21_3f(ch, {pattern_or_size, out})
    end
    return set_chunk_size
  end
  local function socket__3echan(client, xform, err_handler)
    local recv = chan(1024, xform, err_handler)
    local next_chunk = chan()
    local close
    local function _818_(self)
      recv["close!"](recv)
      self.closed = true
      return nil
    end
    close = _818_
    local c
    local function _819_(_, val, handler, enqueue_3f)
      return recv["put!"](recv, val, handler, enqueue_3f)
    end
    local function _820_()
      return nil
    end
    local function _821_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "SocketChannel:") .. ">")
    end
    c = setmetatable({puts = recv.puts, takes = nil, ["put!"] = _819_, ["take!"] = _820_, ["close!"] = close, close = close, ["set-chunk-size"] = chunk_setter(next_chunk)}, {__index = getmetatable(next_chunk).__index, __name = "SocketChannel", __fennelview = _821_})
    do
      local _let_824_ = require("lib.async")
      local go_1_auto = _let_824_["go"]
      local function _825_()
        local _2_822_ = _3c_21(recv)
        local data = _2_822_
        local _4_823_ = 0
        local i = _4_823_
        local function recur(data0, i0)
          if (nil ~= data0) then
            local _826_, _827_ = s_2fselect(nil, {client}, 0)
            if (true and ((_G.type(_827_) == "table") and (nil ~= _827_[1]))) then
              local _ = _826_
              local s = _827_[1]
              local _828_, _829_, _830_ = s:send(data0, i0)
              if ((_828_ == nil) and (_829_ == "timeout") and (nil ~= _830_)) then
                local j = _830_
                _3c_21(timeout(10))
                return recur(data0, j)
              elseif ((_828_ == nil) and (_829_ == "closed")) then
                s:close()
                return close_21(c)
              else
                local _0 = _828_
                return recur(_3c_21(recv), 0)
              end
            else
              local _ = _826_
              _3c_21(timeout(10))
              return recur(data0, i0)
            end
          else
            return nil
          end
        end
        return recur(_2_822_, _4_823_)
      end
      go_1_auto(_825_)
    end
    do
      local _let_836_ = require("lib.async")
      local go_1_auto = _let_836_["go"]
      local function _837_()
        local _2_834_ = _3c_21(next_chunk)
        local chunk_size = _2_834_[1]
        local out = _2_834_[2]
        local _4_835_ = ""
        local partial_data = _4_835_
        local function recur(_838_, partial_data0)
          local chunk_size0 = _838_[1]
          local out0 = _838_[2]
          local _839_, _840_, _841_ = client:receive(chunk_size0)
          if (nil ~= _839_) then
            local data = _839_
            _3e_21(out0, (partial_data0 .. data))
            return recur(_3c_21(next_chunk), "")
          else
            local and_842_ = ((_839_ == nil) and (_840_ == "closed") and true)
            if and_842_ then
              local _3fdata = _841_
              and_842_ = ((_3fdata == nil) or (_3fdata == ""))
            end
            if and_842_ then
              local _3fdata = _841_
              client:close()
              return close_21(c)
            elseif ((_839_ == nil) and (_840_ == "closed") and (nil ~= _841_)) then
              local data = _841_
              client:close()
              _3e_21(out0, data)
              return close_21(c)
            else
              local and_844_ = ((_839_ == nil) and (_840_ == "timeout") and true)
              if and_844_ then
                local _3fdata = _841_
                and_844_ = ((_3fdata == nil) or (_3fdata == ""))
              end
              if and_844_ then
                local _3fdata = _841_
                _3c_21(timeout(10))
                return recur({chunk_size0, out0}, partial_data0)
              elseif ((_839_ == nil) and (_840_ == "timeout") and (nil ~= _841_)) then
                local data = _841_
                _3c_21(timeout(10))
                local _846_ = (("number" == type(chunk_size0)) and (chunk_size0 - #data))
                if (nil ~= _846_) then
                  local chunk_size_2a = _846_
                  return recur({chunk_size_2a, out0}, (partial_data0 .. data))
                else
                  local _ = _846_
                  return recur({chunk_size0, out0}, (partial_data0 .. data))
                end
              else
                return nil
              end
            end
          end
        end
        return recur(_2_834_, _4_835_)
      end
      go_1_auto(_837_)
    end
    return c
  end
  local function chan0(_849_, xform, err_handler)
    local host = _849_["host"]
    local port = _849_["port"]
    assert(socket, "tcp module requires luasocket")
    local host0 = (host or "localhost")
    local function _850_(...)
      local _851_, _852_ = ...
      if (nil ~= _851_) then
        local client = _851_
        local function _853_(...)
          local _854_, _855_ = ...
          if true then
            local _ = _854_
            return socket__3echan(client, xform, err_handler)
          elseif ((_854_ == nil) and (nil ~= _855_)) then
            local err = _855_
            return error(err)
          else
            return nil
          end
        end
        return _853_(client:settimeout(0))
      elseif ((_851_ == nil) and (nil ~= _852_)) then
        local err = _852_
        return error(err)
      else
        return nil
      end
    end
    return _850_(s_2fconnect(host0, port))
  end
  return {chan = chan0, ["socket->chan"] = socket__3echan}
end
package.preload["http.uuid"] = package.preload["http.uuid"] or function(...)
  local m_2fmod = (math.fmod or math.mod)
  local m_2ffloor = math["floor"]
  local m_2frandom = math["random"]
  local s_2fsub = string["sub"]
  local s_2fformat = string["format"]
  local function num__3ebs(num)
    local result, num0 = "", num
    if (num0 == 0) then
      return 0
    else
      while (num0 > 0) do
        result = (m_2fmod(num0, 2) .. result)
        num0 = m_2ffloor((num0 * 0.5))
      end
      return result
    end
  end
  local function bs__3enum(num)
    if (num == "0") then
      return 0
    else
      local index, result = 0, 0
      for p = #tostring(num), 1, -1 do
        local this_val = s_2fsub(num, p, p)
        if (this_val == "1") then
          result = (result + (2 ^ index))
        else
        end
        index = (index + 1)
      end
      return result
    end
  end
  local function padbits(num, bits)
    if (#tostring(num) == bits) then
      return num
    else
      local num0 = num
      for i = 1, (bits - #tostring(num0)) do
        num0 = ("0" .. num0)
      end
      return num0
    end
  end
  local function random_uuid()
    m_2frandom()
    local time_low_a = m_2frandom(0, 65535)
    local time_low_b = m_2frandom(0, 65535)
    local time_mid = m_2frandom(0, 65535)
    local time_hi = padbits(num__3ebs(m_2frandom(0, 4095)), 12)
    local time_hi_and_version = bs__3enum(("0100" .. time_hi))
    local clock_seq_hi_res = ("10" .. padbits(num__3ebs(m_2frandom(0, 63)), 6))
    local clock_seq_low = padbits(num__3ebs(m_2frandom(0, 255)), 8)
    local clock_seq = bs__3enum((clock_seq_hi_res .. clock_seq_low))
    local node = {nil, nil, nil, nil, nil, nil}
    for i = 1, 6 do
      node[i] = m_2frandom(0, 255)
    end
    local guid = ""
    do
      guid = (guid .. padbits(s_2fformat("%x", time_low_a), 4))
      guid = (guid .. padbits(s_2fformat("%x", time_low_b), 4) .. "-")
      guid = (guid .. padbits(s_2fformat("%x", time_mid), 4) .. "-")
      guid = (guid .. padbits(s_2fformat("%x", time_hi_and_version), 4) .. "-")
      guid = (guid .. padbits(s_2fformat("%x", clock_seq), 4) .. "-")
    end
    for i = 1, 6 do
      guid = (guid .. padbits(s_2fformat("%x", node[i]), 2))
    end
    return guid
  end
  return {["random-uuid"] = random_uuid}
end
package.preload["http.json"] = package.preload["http.json"] or function(...)
  local _local_868_ = require("http.readers")
  local reader_3f = _local_868_["reader?"]
  local string_reader = _local_868_["string-reader"]
  local make_reader = _local_868_["make-reader"]
  local concat = table["concat"]
  local gsub = string["gsub"]
  local format = string["format"]
  local function string_3f(val)
    return (("string" == type(val)) and {string = val})
  end
  local function number_3f(val)
    return (("number" == type(val)) and {number = val})
  end
  local function object_3f(val)
    return (("table" == type(val)) and {object = val})
  end
  local function array_3f(val, _3fmax)
    local and_869_ = object_3f(val)
    if and_869_ then
      local _870_ = #val
      if (_870_ == 0) then
        and_869_ = false
      elseif (nil ~= _870_) then
        local len = _870_
        local max = (_3fmax or len)
        local _875_ = next(val, max)
        local and_877_ = (nil ~= _875_)
        if and_877_ then
          local k = _875_
          and_877_ = ("number" == type(k))
        end
        if and_877_ then
          local k = _875_
          and_869_ = array_3f(val, k)
        elseif (_875_ == nil) then
          and_869_ = {n = max, array = val}
        else
          local _ = _875_
          and_869_ = false
        end
      else
        and_869_ = nil
      end
    end
    return and_869_
  end
  local function function_3f(val)
    return (("function" == type(val)) and {["function"] = val})
  end
  local function guess(val)
    return (array_3f(val) or object_3f(val) or string_3f(val) or number_3f(val) or function_3f(val) or val)
  end
  local function escape_string(str)
    local escs
    local function _884_(_241, _242)
      return ("\\%03d"):format(_242:byte())
    end
    escs = setmetatable({["\7"] = "\\a", ["\8"] = "\\b", ["\12"] = "\\f", ["\11"] = "\\v", ["\13"] = "\\r", ["\t"] = "\\t", ["\\"] = "\\\\", ["\""] = "\\\"", ["\n"] = "\\n"}, {__index = _884_})
    return ("\"" .. str:gsub("[%c\\\"]", escs) .. "\"")
  end
  local function encode(val)
    local _885_ = guess(val)
    if ((_G.type(_885_) == "table") and (nil ~= _885_.array) and (nil ~= _885_.n)) then
      local array = _885_.array
      local n = _885_.n
      local _886_
      do
        local tbl_21_auto = {}
        local i_22_auto = 0
        for i = 1, n do
          local val_23_auto = encode(array[i])
          if (nil ~= val_23_auto) then
            i_22_auto = (i_22_auto + 1)
            tbl_21_auto[i_22_auto] = val_23_auto
          else
          end
        end
        _886_ = tbl_21_auto
      end
      return ("[" .. concat(_886_, ", ") .. "]")
    elseif ((_G.type(_885_) == "table") and (nil ~= _885_.object)) then
      local object = _885_.object
      local _888_
      do
        local tbl_21_auto = {}
        local i_22_auto = 0
        for k, v in pairs(object) do
          local val_23_auto = (encode(k) .. ": " .. encode(v))
          if (nil ~= val_23_auto) then
            i_22_auto = (i_22_auto + 1)
            tbl_21_auto[i_22_auto] = val_23_auto
          else
          end
        end
        _888_ = tbl_21_auto
      end
      return ("{" .. concat(_888_, ", ") .. "}")
    elseif ((_G.type(_885_) == "table") and (nil ~= _885_.string)) then
      local s = _885_.string
      return escape_string(s)
    elseif ((_G.type(_885_) == "table") and (nil ~= _885_.number)) then
      local n = _885_.number
      return gsub(tostring(n), ",", ".")
    elseif ((_G.type(_885_) == "table") and (nil ~= _885_["function"])) then
      local f = _885_["function"]
      return error(("JSON encoding error: don't know how to encode function value: " .. tostring(f)))
    elseif (_885_ == true) then
      return "true"
    elseif (_885_ == false) then
      return "false"
    elseif (_885_ == nil) then
      return "null"
    else
      local _ = _885_
      return escape_string(tostring(val))
    end
  end
  local function skip_space(rdr)
    local function loop()
      local _891_ = rdr:peek(1)
      local and_892_ = (nil ~= _891_)
      if and_892_ then
        local c = _891_
        and_892_ = c:match("[ \t\n]")
      end
      if and_892_ then
        local c = _891_
        return loop(rdr:read(1))
      else
        return nil
      end
    end
    return loop()
  end
  local function parse_num(rdr)
    local function loop(numbers)
      local _895_ = rdr:peek(1)
      local and_896_ = (nil ~= _895_)
      if and_896_ then
        local n = _895_
        and_896_ = n:match("[-0-9.eE+]")
      end
      if and_896_ then
        local n = _895_
        rdr:read(1)
        return loop((numbers .. n))
      else
        local _ = _895_
        return tonumber(numbers)
      end
    end
    return loop(rdr:read(1))
  end
  local _escapable = {["\""] = "\"", ["'"] = "'", ["\\"] = "\\", b = "\8", f = "\12", n = "\n", r = "\13", t = "\t"}
  local function parse_string(rdr)
    rdr:read(1)
    local function loop(chars, escaped_3f)
      local ch = rdr:read(1)
      if (ch == "\\") then
        if escaped_3f then
          return loop((chars .. ch), false)
        else
          local _899_ = rdr:peek(1)
          local and_900_ = (nil ~= _899_)
          if and_900_ then
            local c = _899_
            and_900_ = _escapable[c]
          end
          if and_900_ then
            local c = _899_
            return loop(chars, true)
          else
            local and_902_ = (_899_ == "u")
            if and_902_ then
              and_902_ = (_G.utf8 and (rdr:peek(5) or ""):match("u%x%x%x%x"))
            end
            if and_902_ then
              return loop((chars .. _G.utf8.char(tonumber(("0x" .. rdr:read(5):match("u(%x%x%x%x)"))))))
            elseif (nil ~= _899_) then
              local c = _899_
              rdr:read(1)
              return loop((chars .. c), false)
            else
              return nil
            end
          end
        end
      elseif (ch == "\"") then
        if escaped_3f then
          return loop((chars .. ch), false)
        else
          return chars
        end
      elseif (ch == nil) then
        return error("JSON parse error: unterminated string")
      else
        local and_907_ = (nil ~= ch)
        if and_907_ then
          local c = ch
          and_907_ = (escaped_3f and _escapable[c])
        end
        if and_907_ then
          local c = ch
          return loop((chars .. _escapable[c]), false)
        else
          local _ = ch
          return loop((chars .. ch), false)
        end
      end
    end
    return loop("", false)
  end
  local function parse_obj(rdr, parse)
    rdr:read(1)
    local function loop(obj)
      skip_space(rdr)
      local _910_ = rdr:peek(1)
      if (_910_ == "}") then
        rdr:read(1)
        return obj
      else
        local _ = _910_
        local key = parse()
        skip_space(rdr)
        local _911_ = rdr:peek(1)
        if (_911_ == ":") then
          local _0 = rdr:read(1)
          local value = parse()
          obj[key] = value
          skip_space(rdr)
          local _912_ = rdr:peek(1)
          if (_912_ == ",") then
            rdr:read(1)
            return loop(obj)
          elseif (_912_ == "}") then
            rdr:read(1)
            return obj
          else
            local _1 = _912_
            return error(("JSON parse error: expected ',' or '}' after the value: " .. encode(value) .. ", got " .. _1))
          end
        else
          local _0 = _911_
          return error(("JSON parse error: expected colon after the key: " .. encode(key) .. ", got " .. _0))
        end
      end
    end
    return loop({})
  end
  local function parse_arr(rdr, parse)
    rdr:read(1)
    local len = 0
    local function loop(arr)
      skip_space(rdr)
      local _916_ = rdr:peek(1)
      if (_916_ == "]") then
        rdr:read(1)
        return arr
      else
        local _ = _916_
        local val = parse()
        len = (1 + len)
        arr[len] = val
        skip_space(rdr)
        local _917_ = rdr:peek(1)
        if (_917_ == ",") then
          rdr:read(1)
          return loop(arr)
        elseif (_917_ == "]") then
          rdr:read(1)
          return arr
        else
          local _0 = _917_
          return error(("JSON parse error: expected ',' or ']' after the value: " .. encode(val) .. ", got " .. _0))
        end
      end
    end
    return loop({})
  end
  local function decode(data)
    local rdr
    if reader_3f(data) then
      rdr = data
    elseif string_3f(data) then
      rdr = string_reader(data)
    else
      rdr = error("expected a reader, or a string as input", 2)
    end
    local function loop()
      local _921_ = rdr:peek(1)
      if (_921_ == "{") then
        return parse_obj(rdr, loop)
      elseif (_921_ == "[") then
        return parse_arr(rdr, loop)
      elseif (_921_ == "\"") then
        return parse_string(rdr)
      else
        local and_922_ = (_921_ == "t")
        if and_922_ then
          and_922_ = ("true" == rdr:peek(4))
        end
        if and_922_ then
          rdr:read(4)
          return true
        else
          local and_924_ = (_921_ == "f")
          if and_924_ then
            and_924_ = ("false" == rdr:peek(5))
          end
          if and_924_ then
            rdr:read(5)
            return false
          else
            local and_926_ = (_921_ == "n")
            if and_926_ then
              and_926_ = ("null" == rdr:peek(4))
            end
            if and_926_ then
              rdr:read(4)
              return nil
            else
              local and_928_ = (nil ~= _921_)
              if and_928_ then
                local c = _921_
                and_928_ = c:match("[ \t\n]")
              end
              if and_928_ then
                local c = _921_
                return loop(skip_space(rdr))
              else
                local and_930_ = (nil ~= _921_)
                if and_930_ then
                  local n = _921_
                  and_930_ = n:match("[-0-9]")
                end
                if and_930_ then
                  local n = _921_
                  return parse_num(rdr)
                elseif (_921_ == nil) then
                  return error("JSON parse error: end of stream")
                elseif (nil ~= _921_) then
                  local c = _921_
                  return error(format("JSON parse error: unexpected token ('%s' (code %d))", c, c:byte()))
                else
                  return nil
                end
              end
            end
          end
        end
      end
    end
    return loop()
  end
  local function _933_(_, value)
    return encode(value)
  end
  return setmetatable({encode = encode, decode = decode}, {__call = _933_})
end
return setmetatable({client = require("http.client"), json = require("http.json"), readers = require("http.readers")}, {__index = setmetatable(require("http.client"), {__index = {__VERSION = "0.0.84"}})})