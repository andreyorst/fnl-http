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
  local _local_490_ = require("http.async-extras")
  local _3e_21_3f = _local_490_[">!?"]
  local _3c_21_3f = _local_490_["<!?"]
  local http_parser = require("http.parser")
  local _local_720_ = require("http.tcp")
  local chan = _local_720_["chan"]
  local _local_721_ = require("http.readers")
  local reader_3f = _local_721_["reader?"]
  local file_reader = _local_721_["file-reader"]
  local _local_726_ = require("http.builder")
  local build_http_request = _local_726_["build-http-request"]
  local _local_769_ = require("http.body")
  local stream_body = _local_769_["stream-body"]
  local format_chunk = _local_769_["format-chunk"]
  local wrap_body = _local_769_["wrap-body"]
  local multipart_content_length = _local_769_["multipart-content-length"]
  local stream_multipart = _local_769_["stream-multipart"]
  local _local_774_ = require("http.uuid")
  local random_uuid = _local_774_["random-uuid"]
  local _local_841_ = require("http.json")
  local decode = _local_841_["decode"]
  local format = string["format"]
  local lower = string["lower"]
  local upper = string["upper"]
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
  local function prepare_headers(_843_)
    local body = _843_["body"]
    local headers = _843_["headers"]
    local multipart = _843_["multipart"]
    local mime_subtype = _843_["mime-subtype"]
    local _arg_844_ = _843_["url"]
    local host = _arg_844_["host"]
    local port = _arg_844_["port"]
    local headers0
    do
      local tbl_16_auto
      local _845_
      if port then
        _845_ = (":" .. port)
      else
        _845_ = ""
      end
      local _847_
      if (type(body) == "string") then
        _847_ = #body
      elseif reader_3f(body) then
        _847_ = body:length()
      else
        _847_ = nil
      end
      local _850_
      do
        local _849_ = type(body)
        if ((_849_ == "string") or (_849_ == "nil")) then
          _850_ = nil
        else
          local _ = _849_
          _850_ = "chunked"
        end
      end
      local _854_
      if multipart then
        _854_ = ("multipart/" .. (mime_subtype or "form-data") .. "; boundary=------------" .. random_uuid())
      else
        _854_ = nil
      end
      tbl_16_auto = {host = (host .. _845_), ["content-length"] = _847_, ["transfer-encoding"] = _850_, ["content-type"] = _854_}
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
  local function format_path(_859_)
    local path = _859_["path"]
    local query = _859_["query"]
    local fragment = _859_["fragment"]
    local _860_
    if query then
      _860_ = ("?" .. query)
    else
      _860_ = ""
    end
    local _862_
    if fragment then
      _862_ = ("?" .. fragment)
    else
      _862_ = ""
    end
    return ((path or "/") .. _860_ .. _862_)
  end
  local function make_client(opts)
    local or_864_ = opts["http-client"]
    if not or_864_ then
      local tmp_9_auto
      local function _867_()
        if opts["async?"] then
          local function _866_(err)
            opts["on-raise"](err)
            return nil
          end
          return _866_
        else
          return nil
        end
      end
      tmp_9_auto = chan(opts.url, nil, _867_())
      local function _868_(src, pattern)
        src["set-chunk-size"](src, pattern)
        return _3c_21_3f(src)
      end
      tmp_9_auto["read"] = _868_
      local function _869_(src, pattern, prefix)
        src["set-chunk-size"](src, pattern)
        return ((prefix or "") .. _3c_21_3f(src))
      end
      tmp_9_auto["receive"] = _869_
      local function _870_(ch, data, ...)
        local function _873_(...)
          local _871_, _872_ = select("#", ...), ...
          if (_871_ == 0) then
            return data
          elseif ((_871_ == 1) and (nil ~= _872_)) then
            local i = _872_
            return data:sub(i, #data)
          else
            local _ = _871_
            return data:sub(...)
          end
        end
        return _3e_21_3f(ch, _873_(...))
      end
      tmp_9_auto["send"] = _870_
      tmp_9_auto["write"] = _3e_21_3f
      or_864_ = tmp_9_auto
    end
    return or_864_
  end
  local non_error_statuses = {[200] = true, [201] = true, [202] = true, [203] = true, [204] = true, [205] = true, [206] = true, [207] = true, [300] = true, [301] = true, [302] = true, [303] = true, [304] = true, [307] = true}
  local function try_coerce_body(response, opts)
    if ("table" == type(response)) then
      local _875_, _876_ = opts.as, response.body
      if ((_875_ == "json") and (nil ~= _876_)) then
        local body = _876_
        return pcall(decode, body)
      elseif (true and true) then
        local _ = _875_
        local _3fbody = _876_
        return true, _3fbody
      else
        return nil
      end
    else
      return response
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
    if ok_3f then
      response["parsed-headers"] = nil
      response["body"] = body
      response0 = response
    else
      response0 = body
    end
    if ((opts["throw-errors?"] and not non_error_statuses[response0.status]) or not ok_3f) then
      return raise_2a(response0, opts)
    else
      return respond_2a(response0, opts)
    end
  end
  local function raise(response, opts)
    local ok_3f, body = try_coerce_body(response, opts)
    local response0
    if ok_3f then
      response["parsed-headers"] = nil
      response["body"] = body
      response0 = response
    else
      response0 = body
    end
    do
      response0["parsed-headers"] = nil
      response0["body"] = body
    end
    return raise_2a(response0, opts)
  end
  local function redirect_3f(status)
    return ((300 <= status) and (status <= 399))
  end
  local function reuse_client_3f(_884_)
    local body = _884_["body"]
    local http_client = _884_["http-client"]
    local headers = _884_["headers"]
    local len = _884_["length"]
    if reader_3f(body) then
      if len then
        body:read(len)
      elseif http_parser["chunked-encoding?"](headers["Transfer-Encoding"]) then
        body:read("*a")
      else
      end
    else
    end
    local _887_ = lower(headers.Connection)
    if (_887_ == "keep-alive") then
      return http_client
    else
      local _ = _887_
      if reader_3f(body) then
        body:read("*a")
      else
      end
      http_client:close()
      return nil
    end
  end
  local function redirect(response, opts, request_fn, location, method)
    local function _891_()
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
      tmp_9_auto["url"] = http_parser["parse-url"](location)
      tmp_9_auto["max-redirects"] = (opts["max-redirects"] - 1)
      return tmp_9_auto
    end
    return request_fn(_891_())
  end
  local function follow_redirects(_892_, _893_, request_fn)
    local status = _892_["status"]
    local headers = _892_["headers"]
    local response = _892_
    local method = _893_["method"]
    local throw_errors_3f = _893_["throw-errors?"]
    local max_redirects = _893_["max-redirects"]
    local force_redirects_3f = _893_["force-redirects?"]
    local opts = _893_
    if (not opts["follow-redirects?"] or not redirect_3f(status)) then
      return respond(response, opts)
    else
      local _894_ = headers.Location
      if (_894_ == nil) then
        return respond(response, opts)
      elseif (nil ~= _894_) then
        local location = _894_
        if (max_redirects <= 0) then
          if opts["throw-errors?"] then
            return raise("too many redirecs", opts)
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
      local _900_ = opts.multipart
      if (nil ~= _900_) then
        local parts = _900_
        stream_multipart(client0, parts, get_boundary(headers))
      else
      end
    end
    if opts["async?"] then
      local _902_, _903_ = pcall(http_parser["parse-http-response"], client0, opts)
      if ((_902_ == true) and (nil ~= _903_)) then
        local resp = _903_
        return follow_redirects(resp, opts, request_fn)
      elseif (true and (nil ~= _903_)) then
        local _ = _902_
        local err = _903_
        return opts["on-raise"](err)
      else
        return nil
      end
    else
      return follow_redirects(http_parser["parse-http-response"](client0, opts), opts, request_fn)
    end
  end
  local function request_2a(opts)
    local body = wrap_body(opts.body)
    local headers = prepare_headers(opts)
    local req
    local function _906_()
      if (headers["transfer-encoding"] == "chunked") then
        return nil
      elseif ("string" == type(body)) then
        return body
      else
        return nil
      end
    end
    req = build_http_request(opts.method, format_path(opts.url), headers, _906_())
    local client0 = make_client(opts)
    assert((not opts["async?"] or (opts["on-response"] and opts["on-raise"])), "If async? is true, on-response and on-raise callbacks must be passed")
    opts.start = (opts.start or gettime())
    if opts["async?"] then
      local _let_907_ = require("lib.async")
      local go_1_auto = _let_907_["go"]
      local function _908_()
        return process_request(client0, req, body, headers, opts, request_2a)
      end
      return go_1_auto(_908_)
    else
      return process_request(client0, req, body, headers, opts, request_2a)
    end
  end
  client.request = function(method, url, opts, on_response, on_raise)
    local function _911_()
      local tmp_9_auto
      do
        local tbl_16_auto = {as = "raw", time = gettime, ["throw-errors?"] = true, ["follow-redirects?"] = true, ["max-redirects"] = math.huge, url = http_parser["parse-url"](url), ["on-response"] = on_response, ["on-raise"] = on_raise, ["async?"] = false}
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
    return request_2a(_911_())
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
    _G.assert((nil ~= close_3f), "Missing argument close? on ./lib/async.fnl:1341")
    _G.assert((nil ~= ch), "Missing argument ch on ./lib/async.fnl:1341")
    return _["tap*"](_, ch, close_3f)
  end
  local function untap_2a(_, ch)
    _G.assert((nil ~= ch), "Missing argument ch on ./lib/async.fnl:1342")
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
    _G.assert((nil ~= ch), "Missing argument ch on ./lib/async.fnl:1405")
    return _["admix*"](_, ch)
  end
  local function solo_mode_2a(_, mode)
    _G.assert((nil ~= mode), "Missing argument mode on ./lib/async.fnl:1409")
    return _["solo-mode*"](_, mode)
  end
  local function toggle_2a(_, state_map)
    _G.assert((nil ~= state_map), "Missing argument state-map on ./lib/async.fnl:1408")
    return _["toggle*"](_, state_map)
  end
  local function unmix_2a(_, ch)
    _G.assert((nil ~= ch), "Missing argument ch on ./lib/async.fnl:1406")
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
    _G.assert((nil ~= close_3f), "Missing argument close? on ./lib/async.fnl:1510")
    _G.assert((nil ~= ch), "Missing argument ch on ./lib/async.fnl:1510")
    _G.assert((nil ~= v), "Missing argument v on ./lib/async.fnl:1510")
    return _["sub*"](_, v, ch, close_3f)
  end
  local function unsub_2a(_, v, ch)
    _G.assert((nil ~= ch), "Missing argument ch on ./lib/async.fnl:1511")
    _G.assert((nil ~= v), "Missing argument v on ./lib/async.fnl:1511")
    return _["unsub*"](_, v, ch)
  end
  local function unsub_all_2a(_, v)
    _G.assert((nil ~= v), "Missing argument v on ./lib/async.fnl:1512")
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
package.preload["http.async-extras"] = package.preload["http.async-extras"] or function(...)
  local _local_487_ = require("lib.async")
  local _3e_21 = _local_487_[">!"]
  local _3c_21 = _local_487_["<!"]
  local _3e_21_21 = _local_487_[">!!"]
  local _3c_21_21 = _local_487_["<!!"]
  local chan_3f = _local_487_["chan?"]
  local main_thread_3f = _local_487_["main-thread?"]
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
  return {["<!?"] = _3c_21_3f, [">!?"] = _3e_21_3f}
end
package.preload["http.parser"] = package.preload["http.parser"] or function(...)
  local _local_577_ = require("http.readers")
  local make_reader = _local_577_["make-reader"]
  local string_reader = _local_577_["string-reader"]
  local _local_588_ = require("http.headers")
  local decode_value = _local_588_["decode-value"]
  local capitalize_header = _local_588_["capitalize-header"]
  local format = string["format"]
  local lower = string["lower"]
  local upper = string["upper"]
  local ceil = math["ceil"]
  local function parse_header(line)
    local _589_, _590_ = line:match(" *([^:]+) *: *(.*)")
    if ((nil ~= _589_) and (nil ~= _590_)) then
      local header = _589_
      local value = _590_
      return header, value
    else
      return nil
    end
  end
  local function read_headers(src, _3fheaders)
    local headers = (_3fheaders or {})
    local line = src:read("*l")
    if ((line == "\13") or (line == "")) then
      return headers
    else
      local _ = line
      local function _594_()
        local _592_, _593_ = parse_header((line or ""))
        if ((nil ~= _592_) and (nil ~= _593_)) then
          local header = _592_
          local value = _593_
          headers[header] = value
          return headers
        else
          return nil
        end
      end
      return read_headers(src, _594_())
    end
  end
  local function parse_response_status_line(status)
    if status then
      local function loop(reader, fields, res)
        if ((_G.type(fields) == "table") and (nil ~= fields[1])) then
          local field = fields[1]
          local fields0 = {select(2, (table.unpack or _G.unpack)(fields))}
          local part = reader()
          local function _597_()
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
          return loop(reader, fields0, _597_())
        else
          local _ = fields
          local reason = status:gsub(format("%s/%s.%s +%s +", res["protocol-version"].name, res["protocol-version"].major, res["protocol-version"].minor, res.status), "")
          res["reason-phrase"] = reason
          return res
        end
      end
      return loop(status:gmatch("([^ ]+)"), {"protocol-version", "status"}, {})
    else
      return error("status line was not received from server")
    end
  end
  local function read_response_status_line(src)
    return parse_response_status_line(src:read("*l"))
  end
  local function body_reader(src)
    local buffer = ""
    local function _600_(src0, pattern)
      local rdr = string_reader(buffer)
      local buffer_content = rdr:read(pattern)
      local and_601_ = (nil ~= pattern)
      if and_601_ then
        local n = pattern
        and_601_ = ("number" == type(n))
      end
      if and_601_ then
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
        local _609_ = src0:read(pattern)
        if (_609_ == nil) then
          if buffer_content then
            return buffer_content
          else
            return nil
          end
        elseif (nil ~= _609_) then
          local data = _609_
          return ((buffer_content or "") .. data)
        else
          return nil
        end
      else
        local _ = pattern
        return error(tostring(pattern))
      end
    end
    local function _613_(src0)
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
    local function _617_(src0)
      return src0:close()
    end
    local function _618_(src0, bytes)
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
    return make_reader(src, {["read-bytes"] = _600_, ["read-line"] = _613_, close = _617_, peek = _618_})
  end
  local function read_chunk_size(src)
    local _620_ = src:read("*l")
    if (_620_ == "") then
      return read_chunk_size(src)
    elseif (nil ~= _620_) then
      local line = _620_
      local _621_ = line:match("%s*([0-9a-fA-F]+)")
      if (nil ~= _621_) then
        local size = _621_
        return tonumber(("0x" .. size))
      else
        local _ = _621_
        return error(format("line missing chunk size: %q", line))
      end
    else
      return nil
    end
  end
  local function chunked_body_reader(src, initial_chunk)
    local chunk_size = initial_chunk
    local buffer = (src:read(chunk_size) or "")
    local more_3f = true
    local function read_more()
      if more_3f then
        chunk_size = read_chunk_size(src)
        if (chunk_size > 0) then
          buffer = (buffer .. (src:read(chunk_size) or ""))
        else
          more_3f = false
        end
      else
      end
      return (chunk_size > 0), string_reader(buffer)
    end
    local function _626_(_, pattern)
      local rdr = string_reader(buffer)
      local and_627_ = (nil ~= pattern)
      if and_627_ then
        local n = pattern
        and_627_ = ("number" == type(n))
      end
      if and_627_ then
        local n = pattern
        local buffer_content = rdr:read(pattern)
        local len
        if buffer_content then
          len = #buffer_content
        else
          len = 0
        end
        local read_more_3f = (len < n)
        buffer = buffer:sub((len + 1))
        if read_more_3f then
          local _0, rdr0 = read_more()
          if buffer_content then
            return (buffer_content .. (rdr0:read((n - len)) or ""))
          else
            return rdr0:read((n - len))
          end
        else
          return buffer_content
        end
      elseif ((pattern == "*l") or (pattern == "l")) then
        local buffer_content = rdr:read("*l")
        local _0, read_more_3f = not buffer:find("\n")
        if buffer_content then
          buffer = buffer:sub((#buffer_content + 2))
        else
        end
        if read_more_3f then
          local rdr0 = read_more()
          if buffer_content then
            return (buffer_content .. (rdr0:read("*l") or ""))
          else
            return rdr0:read("*l")
          end
        else
          return buffer_content
        end
      elseif ((pattern == "*a") or (pattern == "a")) then
        local buffer_content = rdr:read("*a")
        buffer = ""
        while read_more() do
        end
        local rdr0 = string_reader(buffer)
        buffer = ""
        local _635_ = rdr0:read("*a")
        if (_635_ == nil) then
          if buffer_content then
            return buffer_content
          else
            return nil
          end
        elseif (nil ~= _635_) then
          local data = _635_
          return ((buffer_content or "") .. data)
        else
          return nil
        end
      else
        local _0 = pattern
        return error(tostring(pattern))
      end
    end
    local function _639_(src0)
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
    local function _643_(src0)
      return src0:close()
    end
    local function _644_(_, bytes)
      assert(("number" == type(bytes)), "expected number of bytes to peek")
      local rdr = string_reader(buffer)
      local content = (rdr:read(bytes) or "")
      local len = #content
      if (bytes == len) then
        return content
      else
        local _0, rdr0 = read_more()
        local data = rdr0:read((bytes - len))
        buffer = (buffer .. (data or ""))
        return buffer
      end
    end
    return make_reader(src, {["read-bytes"] = _626_, ["read-line"] = _639_, close = _643_, peek = _644_})
  end
  local function chunked_encoding_3f(transfer_encoding)
    local _646_ = lower((transfer_encoding or ""))
    local and_647_ = (nil ~= _646_)
    if and_647_ then
      local header = _646_
      and_647_ = (header:match("chunked[, ]") or header:match("chunked$"))
    end
    if and_647_ then
      local header = _646_
      return true
    else
      return nil
    end
  end
  local function parse_http_response(src, _650_)
    local as = _650_["as"]
    local start = _650_["start"]
    local time = _650_["time"]
    local method = _650_["method"]
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
    local chunk_size
    if chunked_encoding_3f(parsed_headers["Transfer-Encoding"]) then
      chunk_size = read_chunk_size(src)
    else
      chunk_size = nil
    end
    local stream
    if chunk_size then
      stream = chunked_body_reader(src, chunk_size)
    else
      stream = body_reader(src)
    end
    status["headers"] = headers
    status["parsed-headers"] = parsed_headers
    status["length"] = tonumber(parsed_headers["Content-Length"])
    status["http-client"] = src
    local _654_
    if (start and time) then
      _654_ = ceil((1000 * (time() - start)))
    else
      _654_ = nil
    end
    status["request-time"] = _654_
    local _656_
    if (upper((method or "")) ~= "HEAD") then
      if (as == "raw") then
        _656_ = stream:read((parsed_headers["Content-Length"] or "*a"))
      elseif ((as == "json") or (as == "stream")) then
        _656_ = stream
      else
        local _ = as
        _656_ = error(format("unsupported coersion method '%s'", as))
      end
    else
      _656_ = nil
    end
    status["body"] = _656_
    return status
  end
  local function parse_request_status_line(status)
    local function loop(reader, fields, res)
      if ((_G.type(fields) == "table") and (nil ~= fields[1])) then
        local field = fields[1]
        local fields0 = {select(2, (table.unpack or _G.unpack)(fields))}
        local part = reader()
        local function _662_()
          res[field] = decode_value(part)
          return res
        end
        return loop(reader, fields0, _662_())
      else
        local _ = fields
        return res
      end
    end
    return loop(status:gmatch("([^ ]+)"), {"method", "path", "http-version"}, {})
  end
  local function read_request_status_line(src)
    return parse_request_status_line(src:read("*l"))
  end
  local function parse_http_request(src)
    local status = read_request_status_line(src)
    local headers = read_headers(src)
    status["headers"] = headers
    status["content"] = src:read("*a")
    return status
  end
  local function parse_authority(authority)
    local userinfo = authority:match("([^@]+)@")
    local port = authority:match(":(%d+)")
    local host
    if userinfo then
      local _664_
      if port then
        _664_ = ":"
      else
        _664_ = ""
      end
      host = authority:match(("@([^:]+)" .. _664_))
    else
      local _666_
      if port then
        _666_ = ":"
      else
        _666_ = ""
      end
      host = authority:match(("([^:]+)" .. _666_))
    end
    return {userinfo = userinfo, port = port, host = host}
  end
  local function parse_url(url)
    local scheme = url:match("^([^:]+)://")
    local function _669_()
      if scheme then
        return url:match("//([^/]+)/?")
      else
        return url:match("^([^/]+)/?")
      end
    end
    local _let_670_ = parse_authority(_669_())
    local host = _let_670_["host"]
    local port = _let_670_["port"]
    local userinfo = _let_670_["userinfo"]
    local function _671_()
      if scheme then
        return {scheme, url}
      else
        return {"http", ("http://" .. url)}
      end
    end
    local _let_672_ = _671_()
    local scheme0 = _let_672_[1]
    local url0 = _let_672_[2]
    local port0
    local or_673_ = port
    if not or_673_ then
      if (scheme0 == "https") then
        or_673_ = 443
      elseif (scheme0 == "http") then
        or_673_ = 80
      else
        or_673_ = nil
      end
    end
    port0 = or_673_
    local path = url0:match("//[^/]+(/[^?#]*)")
    local query = url0:match("%?([^#]+)#?")
    local fragment = url0:match("#([^?]+)%??")
    return {scheme = scheme0, host = host, port = port0, userinfo = userinfo, path = path, query = query, fragment = fragment}
  end
  return {["parse-http-response"] = parse_http_response, ["parse-http-request"] = parse_http_request, ["chunked-encoding?"] = chunked_encoding_3f, ["parse-url"] = parse_url}
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
  local function make_reader(source, _492_)
    local read_bytes = _492_["read-bytes"]
    local read_line = _492_["read-line"]
    local close = _492_["close"]
    local peek = _492_["peek"]
    local len = _492_["length"]
    local close0
    if close then
      local function _493_(_, ...)
        return ok_3f(pcall(close, source, ...))
      end
      close0 = _493_
    else
      local function _494_()
        return nil
      end
      close0 = _494_
    end
    local _496_
    if read_bytes then
      local function _497_(_, pattern, ...)
        return read_bytes(source, pattern, ...)
      end
      _496_ = _497_
    else
      local function _498_()
        return nil
      end
      _496_ = _498_
    end
    local _500_
    if read_line then
      local function _501_()
        local function _502_(_, ...)
          return read_line(source, ...)
        end
        return _502_
      end
      _500_ = _501_
    else
      local function _503_()
        local function _504_()
          return nil
        end
        return _504_
      end
      _500_ = _503_
    end
    local _506_
    if peek then
      local function _507_(_, pattern, ...)
        return peek(source, pattern, ...)
      end
      _506_ = _507_
    else
      local function _508_()
        return nil
      end
      _506_ = _508_
    end
    local _510_
    if len then
      local function _511_()
        return len(source)
      end
      _510_ = _511_
    else
      local function _512_()
        return nil
      end
      _510_ = _512_
    end
    local function _514_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "Reader:") .. ">")
    end
    return setmetatable({close = close0, read = _496_, lines = _500_, peek = _506_, length = _510_}, {__index = Reader, __close = close0, __name = "Reader", __fennelview = _514_})
  end
  local open = io["open"]
  local function file_reader(file)
    local file0
    do
      local _515_ = type(file)
      if (_515_ == "string") then
        file0 = open(file, "r")
      else
        local _ = _515_
        file0 = file
      end
    end
    local open_3f
    local function _517_(_241)
      local function _518_(_2410)
        return _2410:read(0)
      end
      return (pcall(_518_, _241))
    end
    open_3f = _517_
    local function _519_(_241)
      if open_3f(_241) then
        return _241:close()
      else
        return nil
      end
    end
    local function _521_(f, pattern)
      if open_3f(f) then
        return f:read(pattern)
      else
        return nil
      end
    end
    local function _523_(f)
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
    local function _526_(f, pattern)
      assert(("number" == type(pattern)), "expected number of bytes to peek")
      if open_3f(f) then
        local res = f:read(pattern)
        f:seek("cur", ( - pattern))
        return res
      else
        return nil
      end
    end
    local function _528_(f)
      if open_3f(f) then
        local current = f:seek("cur")
        local len = (f:seek("end") - current)
        f:seek("cur", ( - len))
        return len
      else
        return nil
      end
    end
    return make_reader(file0, {close = _519_, ["read-bytes"] = _521_, ["read-line"] = _523_, peek = _526_, length = _528_})
  end
  local max = math["max"]
  local function string_reader(string)
    local i, closed_3f = 1, false
    local len = #string
    local try_read_line
    local function _530_(s, pattern)
      local _531_, _532_, _533_ = s:find(pattern, i)
      if (true and (nil ~= _532_) and (nil ~= _533_)) then
        local _ = _531_
        local _end = _532_
        local s0 = _533_
        i = (_end + 1)
        return s0
      else
        return nil
      end
    end
    try_read_line = _530_
    local read_line
    local function _535_(s)
      if (i <= len) then
        return (try_read_line(s, "(.-)\13?\n") or try_read_line(s, "(.-)\13?$"))
      else
        return nil
      end
    end
    read_line = _535_
    local function _537_(_)
      if not closed_3f then
        i = (len + 1)
        closed_3f = true
        return closed_3f
      else
        return nil
      end
    end
    local function _539_(s, pattern)
      if (i <= len) then
        if ((pattern == "*l") or (pattern == "l")) then
          return read_line(s)
        elseif ((pattern == "*a") or (pattern == "a")) then
          return s:sub(i)
        else
          local and_540_ = (nil ~= pattern)
          if and_540_ then
            local bytes = pattern
            and_540_ = ("number" == type(bytes))
          end
          if and_540_ then
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
    local function _544_(s, pattern)
      if (i <= len) then
        local and_545_ = (nil ~= pattern)
        if and_545_ then
          local bytes = pattern
          and_545_ = ("number" == type(bytes))
        end
        if and_545_ then
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
    local function _549_(s)
      if not closed_3f then
        return max(0, (#s - (i - 1)))
      else
        return nil
      end
    end
    return make_reader(string, {close = _537_, ["read-bytes"] = _539_, ["read-line"] = read_line, peek = _544_, length = _549_})
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
        local and_551_ = (nil ~= pattern)
        if and_551_ then
          local bytes = pattern
          and_551_ = ("number" == type(bytes))
        end
        if and_551_ then
          local bytes = pattern
          buffer = (rdr:read("*a") or "")
          if (len < pattern) then
            if step0(source, sink_2ftable(data)) then
              buffer = (buffer .. (data[1] or ""))
              local _553_ = read(_, (bytes - len))
              local and_554_ = (nil ~= _553_)
              if and_554_ then
                local data0 = _553_
                and_554_ = data0
              end
              if and_554_ then
                local data0 = _553_
                return ((content or "") .. data0)
              else
                local _0 = _553_
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
              local _559_ = read(_, pattern)
              if (nil ~= _559_) then
                local data0 = _559_
                return ((content or "") .. data0)
              else
                local _0 = _559_
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
    local function _565_()
      while step0(source, sink_2fnull()) do
      end
      closed_3f = true
      return nil
    end
    local function _566_(_241)
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
            local _568_ = peek(_, (bytes - len))
            local and_569_ = (nil ~= _568_)
            if and_569_ then
              local data0 = _568_
              and_569_ = data0
            end
            if and_569_ then
              local data0 = _568_
              return data0
            else
              local _0 = _568_
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
    return make_reader(source, {close = _565_, ["read-bytes"] = read, ["read-line"] = _566_, peek = peek})
  end
  local function reader_3f(obj)
    local _575_ = getmetatable(obj)
    if ((_G.type(_575_) == "table") and (_575_.__index == Reader)) then
      return true
    else
      local _ = _575_
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
    local function _578_()
      local res,case_change_3f = "", false
      for c in str:gmatch(".") do
        local function _579_()
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
        local _set_581_ = _579_()
        res = _set_581_[1]
        case_change_3f = _set_581_[2]
      end
      return {res, case_change_3f}
    end
    local _let_582_ = _578_()
    local res = _let_582_[1]
    return res
  end
  local function capitalize_header(header)
    local header0 = __3ekebab_case(header)
    local _583_
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
      _583_ = tbl_21_auto
    end
    return concat(_583_, "-")
  end
  local function decode_value(value)
    local _585_ = tonumber(value)
    if (nil ~= _585_) then
      local n = _585_
      return n
    else
      local _ = _585_
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
package.preload["http.tcp"] = package.preload["http.tcp"] or function(...)
  local _local_677_ = require("lib.async")
  local chan = _local_677_["chan"]
  local _3c_21 = _local_677_["<!"]
  local _3e_21 = _local_677_[">!"]
  local offer_21 = _local_677_["offer!"]
  local timeout = _local_677_["timeout"]
  local close_21 = _local_677_["close!"]
  local _local_678_ = require("socket")
  local s_2fselect = _local_678_["select"]
  local s_2fconnect = _local_678_["connect"]
  local socket = _local_678_
  local function set_chunk_size(self, pattern_or_size)
    self["chunk-size"] = pattern_or_size
    return nil
  end
  local function socket_channel(client, xform, err_handler)
    local recv = chan(1024, xform, err_handler)
    local resp = chan(1024, xform, err_handler)
    local ready = chan()
    local close
    local function _679_(self)
      recv["close!"](recv)
      resp["close!"](resp)
      self.closed = true
      return nil
    end
    close = _679_
    local c
    local function _680_(_, val, handler, enqueue_3f)
      return recv["put!"](recv, val, handler, enqueue_3f)
    end
    local function _681_(_, handler, enqueue_3f)
      offer_21(ready, "ready")
      return resp["take!"](resp, handler, enqueue_3f)
    end
    local function _682_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "SocketChannel:") .. ">")
    end
    c = setmetatable({puts = recv.puts, takes = resp.takes, ["put!"] = _680_, ["take!"] = _681_, ["close!"] = close, close = close, ["chunk-size"] = 1024, ["set-chunk-size"] = set_chunk_size}, {__index = getmetatable(ready).__index, __name = "SocketChannel", __fennelview = _682_})
    do
      local _let_685_ = require("lib.async")
      local go_1_auto = _let_685_["go"]
      local function _686_()
        local _2_683_ = _3c_21(recv)
        local data = _2_683_
        local _4_684_ = 0
        local i = _4_684_
        local function recur(data0, i0)
          if (nil ~= data0) then
            local _687_, _688_ = s_2fselect(nil, {client}, 0)
            if (true and ((_G.type(_688_) == "table") and (nil ~= _688_[1]))) then
              local _ = _687_
              local s = _688_[1]
              local _689_, _690_, _691_ = s:send(data0, i0)
              if ((_689_ == nil) and (_690_ == "timeout") and (nil ~= _691_)) then
                local j = _691_
                _3c_21(timeout(10))
                return recur(data0, j)
              elseif ((_689_ == nil) and (_690_ == "closed")) then
                s:close()
                return close_21(c)
              else
                local _0 = _689_
                return recur(_3c_21(recv), 0)
              end
            else
              local _ = _687_
              _3c_21(timeout(10))
              return recur(data0, i0)
            end
          else
            return nil
          end
        end
        return recur(_2_683_, _4_684_)
      end
      go_1_auto(_686_)
    end
    do
      local _let_698_ = require("lib.async")
      local go_1_auto = _let_698_["go"]
      local function _699_()
        local _2_695_ = true
        local wait_3f = _2_695_
        local _4_696_ = ""
        local part = _4_696_
        local _6_697_ = nil
        local remaining = _6_697_
        local function recur(wait_3f0, part0, remaining0)
          if wait_3f0 then
            _3c_21(ready)
          else
          end
          local size = (remaining0 or c["chunk-size"])
          local _701_, _702_, _703_ = client:receive(size, "")
          if (nil ~= _701_) then
            local data = _701_
            _3e_21(resp, (part0 .. data))
            return recur(true, "", nil)
          else
            local and_704_ = ((_701_ == nil) and (_702_ == "closed") and true)
            if and_704_ then
              local _3fdata = _703_
              and_704_ = ((_3fdata == nil) or (_3fdata == ""))
            end
            if and_704_ then
              local _3fdata = _703_
              client:close()
              return close_21(c)
            elseif ((_701_ == nil) and (_702_ == "closed") and (nil ~= _703_)) then
              local data = _703_
              client:close()
              _3e_21(resp, data)
              return close_21(c)
            else
              local and_706_ = ((_701_ == nil) and (_702_ == "timeout") and true)
              if and_706_ then
                local _3fdata = _703_
                and_706_ = ((_3fdata == nil) or (_3fdata == ""))
              end
              if and_706_ then
                local _3fdata = _703_
                _3c_21(timeout(10))
                return recur(false, part0, remaining0)
              elseif ((_701_ == nil) and (_702_ == "timeout") and (nil ~= _703_)) then
                local data = _703_
                local bytes_3f = ("number" == type(size))
                local remaining1
                if bytes_3f then
                  remaining1 = (size - #data)
                else
                  remaining1 = size
                end
                _3c_21(timeout(10))
                if bytes_3f then
                  return recur((remaining1 == 0), (part0 .. data), ((remaining1 > 0) and remaining1))
                else
                  return recur(false, (part0 .. data), remaining1)
                end
              else
                return nil
              end
            end
          end
        end
        return recur(_2_695_, _4_696_, _6_697_)
      end
      go_1_auto(_699_)
    end
    return c
  end
  local function chan0(_711_, xform, err_handler)
    local host = _711_["host"]
    local port = _711_["port"]
    assert(socket, "tcp module requires luasocket")
    local host0 = (host or "localhost")
    local function _712_(...)
      local _713_, _714_ = ...
      if (nil ~= _713_) then
        local client = _713_
        local function _715_(...)
          local _716_, _717_ = ...
          if true then
            local _ = _716_
            return socket_channel(client, xform, err_handler)
          elseif ((_716_ == nil) and (nil ~= _717_)) then
            local err = _717_
            return error(err)
          else
            return nil
          end
        end
        return _715_(client:settimeout(0))
      elseif ((_713_ == nil) and (nil ~= _714_)) then
        local err = _714_
        return error(err)
      else
        return nil
      end
    end
    return _712_(s_2fconnect(host0, port))
  end
  return {chan = chan0}
end
package.preload["http.builder"] = package.preload["http.builder"] or function(...)
  local HTTP_VERSION = "HTTP/1.1"
  local _local_722_ = require("http.headers")
  local capitalize_header = _local_722_["capitalize-header"]
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
      local function _724_()
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
      return concat(_724_())
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
package.preload["http.body"] = package.preload["http.body"] or function(...)
  local _local_727_ = require("http.builder")
  local headers__3estring = _local_727_["headers->string"]
  local _local_728_ = require("http.readers")
  local reader_3f = _local_728_["reader?"]
  local file_reader = _local_728_["file-reader"]
  local _local_729_ = require("http.parser")
  local chunked_encoding_3f = _local_729_["chunked-encoding?"]
  local _local_730_ = require("lib.async")
  local chan_3f = _local_730_["chan?"]
  local _local_731_ = require("http.async-extras")
  local _3c_21_3f = _local_731_["<!?"]
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
    local _734_
    local function _735_()
      if (1024 < remaining) then
        return 1024
      else
        return remaining
      end
    end
    _734_ = src:read(_735_())
    if (nil ~= _734_) then
      local data = _734_
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
    local _738_ = _3c_21_3f(src)
    if (nil ~= _738_) then
      local data = _738_
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
  local function stream_body(dst, body, _742_)
    local transfer_encoding = _742_["transfer-encoding"]
    local content_length = _742_["content-length"]
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
    local _747_ = type(body)
    if (_747_ == "table") then
      if chan_3f(body) then
        return body
      elseif reader_3f(body) then
        return body
      else
        return body
      end
    elseif (_747_ == "userdata") then
      local _749_ = getmetatable(body)
      if ((_G.type(_749_) == "table") and (_749_.__name == "FILE*")) then
        return file_reader(body)
      else
        local _ = _749_
        return body
      end
    else
      local _ = _747_
      return body
    end
  end
  local function urlencode_string(str)
    local function _752_(_241)
      return ("%%%X"):format(_241:byte())
    end
    return (str:gsub("[^%w]", _752_))
  end
  local function format_multipart_part(_753_, boundary)
    local name = _753_["name"]
    local filename = _753_["filename"]
    local filename_2a = _753_["filename*"]
    local content = _753_["content"]
    local content_length = _753_["length"]
    local headers = _753_["headers"]
    local mime_type = _753_["mime-type"]
    local content0 = wrap_body(content)
    local function _759_()
      local tbl_16_auto
      local _754_
      if filename then
        _754_ = format("; filename=%q", filename)
      else
        _754_ = ""
      end
      local function _756_()
        if filename_2a then
          return format("; filename*=%s", urlencode_string(filename_2a))
        else
          return ""
        end
      end
      local _757_
      if ("string" == type(content0)) then
        _757_ = #content0
      else
        _757_ = (content_length or content0:length())
      end
      tbl_16_auto = {["content-disposition"] = format("form-data; name=%q%s%s", name, _754_, _756_()), ["content-length"] = _757_, ["content-type"] = (mime_type or guess_content_type(content0)), ["content-transfer-encoding"] = guess_transfer_encoding(content0)}
      for k, v in pairs((headers or {})) do
        local k_17_auto, v_18_auto = k, v
        if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
          tbl_16_auto[k_17_auto] = v_18_auto
        else
        end
      end
      return tbl_16_auto
    end
    return format("--%s\13\n%s\13\n", boundary, headers__3estring(_759_()))
  end
  local function multipart_content_length(multipart, boundary)
    local _761_
    do
      local total = 0
      for _, _762_ in ipairs(multipart) do
        local content_length = _762_["length"]
        local name = _762_["name"]
        local content = _762_["content"]
        local part = _762_
        local content0 = wrap_body(content)
        local _763_
        if ("string" == type(content0)) then
          _763_ = (#content0 + 2)
        elseif reader_3f(content0) then
          _763_ = (2 + (content_length or content0:length() or error(format("can't determine length for multipart content %q", name), 2)))
        elseif (nil ~= content_length) then
          _763_ = (content_length + 2)
        else
          _763_ = error(format("missing length field on non-string multipart content %q", name), 2)
        end
        total = (total + #format_multipart_part(part, boundary) + _763_)
      end
      _761_ = total
    end
    return (_761_ + #format("--%s--\13\n", boundary))
  end
  local function stream_multipart(dst, multipart, boundary)
    for _, _765_ in ipairs(multipart) do
      local name = _765_["name"]
      local filename = _765_["filename"]
      local content = _765_["content"]
      local content_length = _765_["length"]
      local mime_type = _765_["mime-type"]
      local part = _765_
      assert((nil ~= content), "Multipart content cannot be nil")
      assert(name, "Multipart body must contain at least content and name")
      do
        local content0 = wrap_body(content)
        local _766_
        if ("string" == type(content0)) then
          _766_ = content0
        else
          _766_ = ""
        end
        dst:write((format_multipart_part(part, boundary) .. _766_))
        if ("string" ~= type(content0)) then
          stream_body(dst, content0, {["content-length"] = (content_length or content0:length())})
        else
        end
      end
      dst:write("\13\n")
    end
    return dst:write(format("--%s--\13\n", boundary))
  end
  return {["stream-body"] = stream_body, ["format-chunk"] = format_chunk, ["stream-multipart"] = stream_multipart, ["multipart-content-length"] = multipart_content_length, ["wrap-body"] = wrap_body}
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
  local _local_775_ = require("http.readers")
  local reader_3f = _local_775_["reader?"]
  local string_reader = _local_775_["string-reader"]
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
    local and_776_ = object_3f(val)
    if and_776_ then
      local _777_ = #val
      if (_777_ == 0) then
        and_776_ = false
      elseif (nil ~= _777_) then
        local len = _777_
        local max = (_3fmax or len)
        local _782_ = next(val, max)
        local and_784_ = (nil ~= _782_)
        if and_784_ then
          local k = _782_
          and_784_ = ("number" == type(k))
        end
        if and_784_ then
          local k = _782_
          and_776_ = array_3f(val, k)
        elseif (_782_ == nil) then
          and_776_ = {n = max, array = val}
        else
          local _ = _782_
          and_776_ = false
        end
      else
        and_776_ = nil
      end
    end
    return and_776_
  end
  local function function_3f(val)
    return (("function" == type(val)) and {["function"] = val})
  end
  local function guess(val)
    return (array_3f(val) or object_3f(val) or string_3f(val) or number_3f(val) or function_3f(val) or val)
  end
  local function escape_string(str)
    local escs
    local function _791_(_241, _242)
      return ("\\%03d"):format(_242:byte())
    end
    escs = setmetatable({["\7"] = "\\a", ["\8"] = "\\b", ["\12"] = "\\f", ["\11"] = "\\v", ["\13"] = "\\r", ["\t"] = "\\t", ["\\"] = "\\\\", ["\""] = "\\\"", ["\n"] = "\\n"}, {__index = _791_})
    return ("\"" .. str:gsub("[%c\\\"]", escs) .. "\"")
  end
  local function encode(val)
    local _792_ = guess(val)
    if ((_G.type(_792_) == "table") and (nil ~= _792_.array) and (nil ~= _792_.n)) then
      local array = _792_.array
      local n = _792_.n
      local _793_
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
        _793_ = tbl_21_auto
      end
      return ("[" .. concat(_793_, ", ") .. "]")
    elseif ((_G.type(_792_) == "table") and (nil ~= _792_.object)) then
      local object = _792_.object
      local _795_
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
        _795_ = tbl_21_auto
      end
      return ("{" .. concat(_795_, ", ") .. "}")
    elseif ((_G.type(_792_) == "table") and (nil ~= _792_.string)) then
      local s = _792_.string
      return escape_string(s)
    elseif ((_G.type(_792_) == "table") and (nil ~= _792_.number)) then
      local n = _792_.number
      return gsub(tostring(n), ",", ".")
    elseif ((_G.type(_792_) == "table") and (nil ~= _792_["function"])) then
      local f = _792_["function"]
      return error(("JSON encoding error: don't know how to encode function value: " .. tostring(f)))
    elseif (_792_ == true) then
      return "true"
    elseif (_792_ == false) then
      return "false"
    elseif (_792_ == nil) then
      return "null"
    else
      local _ = _792_
      return escape_string(tostring(val))
    end
  end
  local function skip_space(rdr)
    local function loop()
      local _798_ = rdr:peek(1)
      local and_799_ = (nil ~= _798_)
      if and_799_ then
        local c = _798_
        and_799_ = c:match("[ \t\n]")
      end
      if and_799_ then
        local c = _798_
        return loop(rdr:read(1))
      else
        return nil
      end
    end
    return loop()
  end
  local function parse_num(rdr)
    local function loop(numbers)
      local _802_ = rdr:peek(1)
      local and_803_ = (nil ~= _802_)
      if and_803_ then
        local n = _802_
        and_803_ = n:match("[-0-9.eE+]")
      end
      if and_803_ then
        local n = _802_
        rdr:read(1)
        return loop((numbers .. n))
      else
        local _ = _802_
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
          local _806_ = rdr:peek(1)
          local and_807_ = (nil ~= _806_)
          if and_807_ then
            local c = _806_
            and_807_ = _escapable[c]
          end
          if and_807_ then
            local c = _806_
            return loop(chars, true)
          else
            local and_809_ = (_806_ == "u")
            if and_809_ then
              and_809_ = (_G.utf8 and (rdr:peek(5) or ""):match("u%x%x%x%x"))
            end
            if and_809_ then
              return loop((chars .. _G.utf8.char(tonumber(("0x" .. rdr:read(5):match("u(%x%x%x%x)"))))))
            elseif (nil ~= _806_) then
              local c = _806_
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
        local and_814_ = (nil ~= ch)
        if and_814_ then
          local c = ch
          and_814_ = (escaped_3f and _escapable[c])
        end
        if and_814_ then
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
      local _817_ = rdr:peek(1)
      if (_817_ == "}") then
        rdr:read(1)
        return obj
      else
        local _ = _817_
        local key = parse()
        skip_space(rdr)
        local _818_ = rdr:peek(1)
        if (_818_ == ":") then
          local _0 = rdr:read(1)
          local value = parse()
          obj[key] = value
          skip_space(rdr)
          local _819_ = rdr:peek(1)
          if (_819_ == ",") then
            rdr:read(1)
            return loop(obj)
          elseif (_819_ == "}") then
            rdr:read(1)
            return obj
          else
            local _1 = _819_
            return error(("JSON parse error: expected ',' or '}' after the value: " .. encode(value)))
          end
        else
          local _0 = _818_
          return error(("JSON parse error: expected colon after the key: " .. encode(key)))
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
      local _823_ = rdr:peek(1)
      if (_823_ == "]") then
        rdr:read(1)
        return arr
      else
        local _ = _823_
        local val = parse()
        len = (1 + len)
        arr[len] = val
        skip_space(rdr)
        local _824_ = rdr:peek(1)
        if (_824_ == ",") then
          rdr:read(1)
          return loop(arr)
        elseif (_824_ == "]") then
          rdr:read(1)
          return arr
        else
          local _0 = _824_
          return error(("JSON parse error: expected ',' or ']' after the value: " .. encode(val)))
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
      local _828_ = rdr:peek(1)
      if (_828_ == "{") then
        return parse_obj(rdr, loop)
      elseif (_828_ == "[") then
        return parse_arr(rdr, loop)
      elseif (_828_ == "\"") then
        return parse_string(rdr)
      else
        local and_829_ = (_828_ == "t")
        if and_829_ then
          and_829_ = ("true" == rdr:peek(4))
        end
        if and_829_ then
          rdr:read(4)
          return true
        else
          local and_831_ = (_828_ == "f")
          if and_831_ then
            and_831_ = ("false" == rdr:peek(5))
          end
          if and_831_ then
            rdr:read(5)
            return false
          else
            local and_833_ = (_828_ == "n")
            if and_833_ then
              and_833_ = ("null" == rdr:peek(4))
            end
            if and_833_ then
              rdr:read(4)
              return nil
            else
              local and_835_ = (nil ~= _828_)
              if and_835_ then
                local c = _828_
                and_835_ = c:match("[ \t\n]")
              end
              if and_835_ then
                local c = _828_
                return loop(skip_space(rdr))
              else
                local and_837_ = (nil ~= _828_)
                if and_837_ then
                  local n = _828_
                  and_837_ = n:match("[-0-9]")
                end
                if and_837_ then
                  local n = _828_
                  return parse_num(rdr)
                elseif (_828_ == nil) then
                  return error("JSON parse error: end of stream")
                elseif (nil ~= _828_) then
                  local c = _828_
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
  local function _840_(_, value)
    return encode(value)
  end
  return setmetatable({encode = encode, decode = decode}, {__call = _840_})
end
return setmetatable({client = require("http.client"), json = require("http.json"), readers = require("http.readers")}, {__index = setmetatable(require("http.client"), {__index = {__VERSION = "0.0.58"}})})