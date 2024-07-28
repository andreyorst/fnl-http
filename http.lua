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
  local socket = require("socket")
  local _local_485_ = require("lib.async")
  local _3e_21 = _local_485_[">!"]
  local _3c_21 = _local_485_["<!"]
  local _3e_21_21 = _local_485_[">!!"]
  local _3c_21_21 = _local_485_["<!!"]
  local chan_3f = _local_485_["chan?"]
  local _local_489_ = require("http.async-extras")
  local _3e_21_3f = _local_489_[">!?"]
  local _3c_21_3f = _local_489_["<!?"]
  local http_parser = require("http.parser")
  local tcp = require("http.tcp")
  local _local_785_ = require("http.readers")
  local reader_3f = _local_785_["reader?"]
  local file_reader = _local_785_["file-reader"]
  local _local_790_ = require("http.builder")
  local build_http_request = _local_790_["build-http-request"]
  local _local_827_ = require("http.body")
  local stream_body = _local_827_["stream-body"]
  local format_chunk = _local_827_["format-chunk"]
  local wrap_body = _local_827_["wrap-body"]
  local multipart_content_length = _local_827_["multipart-content-length"]
  local stream_multipart = _local_827_["stream-multipart"]
  local _local_832_ = require("http.uuid")
  local random_uuid = _local_832_["random-uuid"]
  local client = {}
  local function get_boundary(headers)
    local boundary = nil
    for header, value in pairs(headers) do
      if boundary then break end
      if ("content-type" == string.lower(header)) then
        boundary = string.match(value, "boundary=([^;]+)")
      else
        boundary = nil
      end
    end
    return boundary
  end
  local function prepare_headers(host, port, _834_)
    local body = _834_["body"]
    local headers = _834_["headers"]
    local multipart = _834_["multipart"]
    local mime_subtype = _834_["mime-subtype"]
    local headers0
    do
      local tbl_16_auto
      local _835_
      if port then
        _835_ = (":" .. port)
      else
        _835_ = ""
      end
      local _837_
      if (type(body) == "string") then
        _837_ = #body
      elseif reader_3f(body) then
        _837_ = body:length()
      else
        _837_ = nil
      end
      local _840_
      do
        local _839_ = type(body)
        if ((_839_ == "string") or (_839_ == "nil")) then
          _840_ = nil
        else
          local _ = _839_
          _840_ = "chunked"
        end
      end
      local _844_
      if multipart then
        _844_ = ("multipart/" .. (mime_subtype or "form-data") .. "; boundary=------------" .. random_uuid())
      else
        _844_ = nil
      end
      tbl_16_auto = {host = (host .. _835_), ["content-length"] = _837_, ["transfer-encoding"] = _840_, ["content-type"] = _844_}
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
  local function format_path(_849_)
    local path = _849_["path"]
    local query = _849_["query"]
    local fragment = _849_["fragment"]
    local _850_
    if query then
      _850_ = ("?" .. query)
    else
      _850_ = ""
    end
    local _852_
    if fragment then
      _852_ = ("?" .. fragment)
    else
      _852_ = ""
    end
    return ((path or "/") .. _850_ .. _852_)
  end
  local function wrap_client(chan)
    local function _854_(src, pattern)
      src["set-chunk-size"](src, pattern)
      return _3c_21_3f(src)
    end
    chan["read"] = _854_
    local function _855_(src, pattern, prefix)
      src["set-chunk-size"](src, pattern)
      return ((prefix or "") .. _3c_21_3f(src))
    end
    chan["receive"] = _855_
    local function _856_(ch, data, ...)
      local function _859_(...)
        local _857_, _858_ = select("#", ...), ...
        if (_857_ == 0) then
          return data
        elseif ((_857_ == 1) and (nil ~= _858_)) then
          local i = _858_
          return string.sub(data, i, #data)
        else
          local _ = _857_
          return string.sub(data, ...)
        end
      end
      return _3e_21_3f(ch, _859_(...))
    end
    chan["send"] = _856_
    chan["write"] = _3e_21_3f
    return chan
  end
  client.request = function(method, url, _3fopts, _3fon_response, _3fon_raise)
    local _let_861_ = http_parser["parse-url"](url)
    local host = _let_861_["host"]
    local port = _let_861_["port"]
    local parsed = _let_861_
    local opts
    do
      local tbl_16_auto = {as = "raw", time = socket.gettime, ["throw-errors?"] = true, ["async?"] = false}
      for k, v in pairs((_3fopts or {})) do
        local k_17_auto, v_18_auto = k, v
        if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
          tbl_16_auto[k_17_auto] = v_18_auto
        else
        end
      end
      opts = tbl_16_auto
    end
    local body = wrap_body(opts.body)
    local headers = prepare_headers(host, port, opts)
    local req
    local function _863_()
      if opts.multipart then
        return nil
      elseif (body and (headers["transfer-encoding"] == "chunked")) then
        local _, data = format_chunk(body)
        return data
      elseif ("string" == type(body)) then
        return body
      else
        return nil
      end
    end
    req = build_http_request(method, format_path(parsed), headers, _863_())
    local client0
    local function _865_()
      if opts["async?"] then
        local function _864_(err)
          _3fon_raise(err)
          return nil
        end
        return _864_
      else
        return nil
      end
    end
    client0 = wrap_client(tcp.chan(parsed, nil, _865_()))
    if opts["async?"] then
      assert((_3fon_response and _3fon_raise), "If :async? is true, you must pass on-response and on-raise callbacks")
    else
    end
    if opts["async?"] then
      local _let_867_ = require("lib.async")
      local go_1_auto = _let_867_["go"]
      local function _868_()
        opts.start = socket.gettime()
        client0:write(req)
        do
          local _869_ = opts.multipart
          if (nil ~= _869_) then
            local multipart = _869_
            stream_multipart(client0, multipart, get_boundary(headers))
          else
            local _ = _869_
            stream_body(client0, body, headers)
          end
        end
        local _871_, _872_ = pcall(http_parser["parse-http-response"], client0, opts)
        if ((_871_ == true) and (nil ~= _872_)) then
          local resp = _872_
          return _3fon_response(resp)
        elseif (true and (nil ~= _872_)) then
          local _ = _871_
          local err = _872_
          return _3fon_raise(err)
        else
          return nil
        end
      end
      return go_1_auto(_868_)
    else
      opts.start = socket.gettime()
      client0:write(req)
      do
        local _874_ = opts.multipart
        if (nil ~= _874_) then
          local multipart = _874_
          stream_multipart(client0, multipart, get_boundary(headers))
        else
          local _ = _874_
          stream_body(client0, body, headers)
        end
      end
      return http_parser["parse-http-response"](client0, opts)
    end
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
  local or_1_ = package.preload.reduced
  if not or_1_ then
    local function _2_()
      local Reduced
      local function _4_(_3_, view, options, indent)
        local x = _3_[1]
        return ("#<reduced: " .. view(x, options, (11 + indent)) .. ">")
      end
      local function _6_(_5_)
        local x = _5_[1]
        return x
      end
      local function _8_(_7_)
        local x = _7_[1]
        return ("reduced: " .. tostring(x))
      end
      Reduced = {__fennelview = _4_, __index = {unbox = _6_}, __name = "reduced", __tostring = _8_}
      local function reduced(value)
        return setmetatable({value}, Reduced)
      end
      local function reduced_3f(value)
        return rawequal(getmetatable(value), Reduced)
      end
      return {is_reduced = reduced_3f, reduced = reduced, ["reduced?"] = reduced_3f}
    end
    or_1_ = _2_
  end
  package.preload.reduced = or_1_
  local _local_9_ = require("reduced")
  local reduced = _local_9_["reduced"]
  local reduced_3f = _local_9_["reduced?"]
  local gethook, sethook = nil, nil
  do
    local _10_ = _G.debug
    if ((_G.type(_10_) == "table") and (nil ~= _10_.gethook) and (nil ~= _10_.sethook)) then
      local gethook0 = _10_.gethook
      local sethook0 = _10_.sethook
      gethook, sethook = gethook0, sethook0
    else
      local _ = _10_
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
    local _12_, _13_ = c_2frunning()
    if (_12_ == nil) then
      return true
    elseif (true and (_13_ == true)) then
      local _ = _12_
      return true
    else
      local _ = _12_
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
        local _18_ = res[k]
        if (nil ~= _18_) then
          local e = _18_
          k_17_auto, v_18_auto = k, f(e, v)
        elseif (_18_ == nil) then
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
  local _local_21_ = {["active?"] = active_3f, ["blockable?"] = blockable_3f, commit = commit}
  local active_3f0 = _local_21_["active?"]
  local blockable_3f0 = _local_21_["blockable?"]
  local commit0 = _local_21_["commit"]
  local Handler = _local_21_
  local function fn_handler(f, ...)
    local blockable
    if (0 == select("#", ...)) then
      blockable = true
    else
      blockable = ...
    end
    local _23_ = {}
    do
      do
        local _24_ = Handler["active?"]
        if (nil ~= _24_) then
          local f_3_auto = _24_
          local function _25_(_)
            return true
          end
          _23_["active?"] = _25_
        else
          local _ = _24_
          error("Protocol Handler doesn't define method active?")
        end
      end
      do
        local _27_ = Handler["blockable?"]
        if (nil ~= _27_) then
          local f_3_auto = _27_
          local function _28_(_)
            return blockable
          end
          _23_["blockable?"] = _28_
        else
          local _ = _27_
          error("Protocol Handler doesn't define method blockable?")
        end
      end
      local _30_ = Handler.commit
      if (nil ~= _30_) then
        local f_3_auto = _30_
        local function _31_(_)
          return f
        end
        _23_["commit"] = _31_
      else
        local _ = _30_
        error("Protocol Handler doesn't define method commit")
      end
    end
    local function _33_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Handler" .. ">")
    end
    return setmetatable({}, {__fennelview = _33_, __index = _23_, name = "reify"})
  end
  local fhnop
  local function _34_()
    return nil
  end
  fhnop = fn_handler(_34_)
  local socket
  do
    local _35_, _36_ = pcall(require, "socket")
    if ((_35_ == true) and (nil ~= _36_)) then
      local s = _36_
      socket = s
    else
      local _ = _35_
      socket = nil
    end
  end
  local posix
  do
    local _38_, _39_ = pcall(require, "posix")
    if ((_38_ == true) and (nil ~= _39_)) then
      local p = _39_
      posix = p
    else
      local _ = _38_
      posix = nil
    end
  end
  local time, sleep, time_type = nil, nil, nil
  local _42_
  do
    local t_41_ = socket
    if (nil ~= t_41_) then
      t_41_ = t_41_.gettime
    else
    end
    _42_ = t_41_
  end
  if _42_ then
    local sleep0 = socket.sleep
    local function _44_(_241)
      return sleep0((_241 / 1000))
    end
    time, sleep, time_type = socket.gettime, _44_, "socket"
  else
    local _46_
    do
      local t_45_ = posix
      if (nil ~= t_45_) then
        t_45_ = t_45_.clock_gettime
      else
      end
      _46_ = t_45_
    end
    if _46_ then
      local gettime = posix.clock_gettime
      local nanosleep = posix.nanosleep
      local function _48_()
        local s, ns = gettime()
        return (s + (ns / 1000000000))
      end
      local function _49_(_241)
        local s, ms = m_2fmodf((_241 / 1000))
        return nanosleep(s, (1000000 * 1000 * ms))
      end
      time, sleep, time_type = _48_, _49_, "posix"
    else
      time, sleep, time_type = os.time, nil, "lua"
    end
  end
  local difftime
  local function _51_(_241, _242)
    return (_241 - _242)
  end
  difftime = _51_
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
  local _local_52_ = {["add!"] = add_21, ["close-buf!"] = close_buf_21, ["full?"] = full_3f, ["remove!"] = remove_21}
  local add_210 = _local_52_["add!"]
  local close_buf_210 = _local_52_["close-buf!"]
  local full_3f0 = _local_52_["full?"]
  local remove_210 = _local_52_["remove!"]
  local Buffer = _local_52_
  local FixedBuffer
  local function _54_(_53_)
    local buffer = _53_["buf"]
    local size = _53_["size"]
    return (#buffer >= size)
  end
  local function _56_(_55_)
    local buffer = _55_["buf"]
    return #buffer
  end
  local function _58_(_57_, val)
    local buffer = _57_["buf"]
    local this = _57_
    assert((val ~= nil), "value must not be nil")
    buffer[(1 + #buffer)] = val
    return this
  end
  local function _60_(_59_)
    local buffer = _59_["buf"]
    if (#buffer > 0) then
      return t_2fremove(buffer, 1)
    else
      return nil
    end
  end
  local function _62_(_)
    return nil
  end
  FixedBuffer = {type = Buffer, ["full?"] = _54_, length = _56_, ["add!"] = _58_, ["remove!"] = _60_, ["close-buf!"] = _62_}
  local DroppingBuffer
  local function _63_()
    return false
  end
  local function _65_(_64_)
    local buffer = _64_["buf"]
    return #buffer
  end
  local function _67_(_66_, val)
    local buffer = _66_["buf"]
    local size = _66_["size"]
    local this = _66_
    assert((val ~= nil), "value must not be nil")
    if (#buffer < size) then
      buffer[(1 + #buffer)] = val
    else
    end
    return this
  end
  local function _70_(_69_)
    local buffer = _69_["buf"]
    if (#buffer > 0) then
      return t_2fremove(buffer, 1)
    else
      return nil
    end
  end
  local function _72_(_)
    return nil
  end
  DroppingBuffer = {type = Buffer, ["full?"] = _63_, length = _65_, ["add!"] = _67_, ["remove!"] = _70_, ["close-buf!"] = _72_}
  local SlidingBuffer
  local function _73_()
    return false
  end
  local function _75_(_74_)
    local buffer = _74_["buf"]
    return #buffer
  end
  local function _77_(_76_, val)
    local buffer = _76_["buf"]
    local size = _76_["size"]
    local this = _76_
    assert((val ~= nil), "value must not be nil")
    buffer[(1 + #buffer)] = val
    if (size < #buffer) then
      t_2fremove(buffer, 1)
    else
    end
    return this
  end
  local function _80_(_79_)
    local buffer = _79_["buf"]
    if (#buffer > 0) then
      return t_2fremove(buffer, 1)
    else
      return nil
    end
  end
  local function _82_(_)
    return nil
  end
  SlidingBuffer = {type = Buffer, ["full?"] = _73_, length = _75_, ["add!"] = _77_, ["remove!"] = _80_, ["close-buf!"] = _82_}
  local no_val = {}
  local PromiseBuffer
  local function _83_()
    return false
  end
  local function _84_(this)
    if rawequal(no_val, this.val) then
      return 0
    else
      return 1
    end
  end
  local function _86_(this, val)
    assert((val ~= nil), "value must not be nil")
    if rawequal(no_val, this.val) then
      this["val"] = val
    else
    end
    return this
  end
  local function _89_(_88_)
    local value = _88_["val"]
    return value
  end
  local function _91_(_90_)
    local value = _90_["val"]
    local this = _90_
    if rawequal(no_val, value) then
      this["val"] = nil
      return nil
    else
      return nil
    end
  end
  PromiseBuffer = {type = Buffer, val = no_val, ["full?"] = _83_, length = _84_, ["add!"] = _86_, ["remove!"] = _89_, ["close-buf!"] = _91_}
  local function buffer_2a(size, buffer_type)
    do local _ = (size and assert(("number" == type(size)), ("size must be a number: " .. tostring(size)))) end
    assert(not tostring(size):match("%."), "size must be integer")
    local function _93_(self)
      return self:length()
    end
    local function _94_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "buffer:") .. ">")
    end
    return setmetatable({size = size, buf = {}}, {__index = buffer_type, __name = "buffer", __len = _93_, __fennelview = _94_})
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
    local _96_ = (buffer_3f(buff) and getmetatable(buff).__index)
    if (_96_ == SlidingBuffer) then
      return true
    elseif (_96_ == DroppingBuffer) then
      return true
    elseif (_96_ == PromiseBuffer) then
      return true
    else
      local _ = _96_
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
      local _100_, _101_, _102_ = gethook(main_thread)
      if ((_100_ == hook) and true and true) then
        local _3fmask = _101_
        local _3fn = _102_
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
        local _106_ = next(dispatched_tasks)
        if (nil ~= _106_) then
          local f = _106_
          local _107_
          do
            pcall(f)
            _107_ = f
          end
          dispatched_tasks[_107_] = nil
          done = nil
        elseif (_106_ == nil) then
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
  local function put_active_3f(_112_)
    local handler = _112_[1]
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
  Channel.abort = function(_115_)
    local puts = _115_["puts"]
    local function recur()
      local putter = t_2fremove(puts, 1)
      if (nil ~= putter) then
        local put_handler = putter[1]
        local val = putter[2]
        if put_handler["active?"](put_handler) then
          local put_cb = put_handler:commit()
          local function _116_()
            return put_cb(true)
          end
          return dispatch(_116_)
        else
          return recur()
        end
      else
        return nil
      end
    end
    return recur
  end
  Channel["put!"] = function(_119_, val, handler, enqueue_3f)
    local buf = _119_["buf"]
    local closed = _119_["closed"]
    local this = _119_
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
            local function _120_()
              local function _121_()
                return ret(val0)
              end
              t_2finsert(takers, _121_)
              return takers
            end
            return recur(_120_())
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
        local function _128_()
          return take_cb(val)
        end
        dispatch(_128_)
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
            local _130_ = {}
            do
              do
                local _131_ = Handler["active?"]
                if (nil ~= _131_) then
                  local f_3_auto = _131_
                  local function _132_(_)
                    return handler["active?"](handler)
                  end
                  _130_["active?"] = _132_
                else
                  local _ = _131_
                  error("Protocol Handler doesn't define method active?")
                end
              end
              do
                local _134_ = Handler["blockable?"]
                if (nil ~= _134_) then
                  local f_3_auto = _134_
                  local function _135_(_)
                    return handler["blockable?"](handler)
                  end
                  _130_["blockable?"] = _135_
                else
                  local _ = _134_
                  error("Protocol Handler doesn't define method blockable?")
                end
              end
              local _137_ = Handler.commit
              if (nil ~= _137_) then
                local f_3_auto = _137_
                local function _138_(_)
                  local function _139_(...)
                    return c_2fresume(thunk, ...)
                  end
                  return _139_
                end
                _130_["commit"] = _138_
              else
                local _ = _137_
                error("Protocol Handler doesn't define method commit")
              end
            end
            local function _141_(_241)
              return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Handler" .. ">")
            end
            handler_2a = setmetatable({}, {__fennelview = _141_, __index = _130_, name = "reify"})
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
  Channel["take!"] = function(_147_, handler, enqueue_3f)
    local buf = _147_["buf"]
    local this = _147_
    if not handler["active?"](handler) then
      return nil
    elseif (not (nil == buf) and (#buf > 0)) then
      local _148_ = handler:commit()
      if (nil ~= _148_) then
        local take_cb = _148_
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
          local _let_152_ = recur({})
          local done_3f = _let_152_[1]
          local cbs = _let_152_[2]
          if done_3f then
            this:abort()
          else
          end
          for _, cb in ipairs(cbs) do
            local function _154_()
              return cb(true)
            end
            dispatch(_154_)
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
          local tgt_157_ = putter0[1]
          if (tgt_157_)["active?"](tgt_157_) then
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
        local function _160_()
          return put_cb(true)
        end
        dispatch(_160_)
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
          local function _164_(_241)
            return _241["active?"](_241)
          end
          cleanup_21(takes, _164_)
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
            local _166_ = {}
            do
              do
                local _167_ = Handler["active?"]
                if (nil ~= _167_) then
                  local f_3_auto = _167_
                  local function _168_(_)
                    return handler["active?"](handler)
                  end
                  _166_["active?"] = _168_
                else
                  local _ = _167_
                  error("Protocol Handler doesn't define method active?")
                end
              end
              do
                local _170_ = Handler["blockable?"]
                if (nil ~= _170_) then
                  local f_3_auto = _170_
                  local function _171_(_)
                    return handler["blockable?"](handler)
                  end
                  _166_["blockable?"] = _171_
                else
                  local _ = _170_
                  error("Protocol Handler doesn't define method blockable?")
                end
              end
              local _173_ = Handler.commit
              if (nil ~= _173_) then
                local f_3_auto = _173_
                local function _174_(_)
                  local function _175_(...)
                    return c_2fresume(thunk, ...)
                  end
                  return _175_
                end
                _166_["commit"] = _174_
              else
                local _ = _173_
                error("Protocol Handler doesn't define method commit")
              end
            end
            local function _177_(_241)
              return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Handler" .. ">")
            end
            handler_2a = setmetatable({}, {__fennelview = _177_, __index = _166_, name = "reify"})
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
            local function _185_()
              return take_cb(val)
            end
            dispatch(_185_)
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
    local _190_, _191_ = select("#", ...), ...
    if ((_190_ == 1) and true) then
      local _3fval = _191_
      return buf["add!"](buf, _3fval)
    elseif (_190_ == 0) then
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
    local function _195_(ch, err)
      local _196_ = err_handler0(err)
      if (nil ~= _196_) then
        local res = _196_
        return ch["put!"](ch, res, fhnop)
      else
        return nil
      end
    end
    handler = _195_
    local c = {puts = {}, takes = {}, buf = buffer0, ["err-handler"] = handler}
    c["add!"] = function(...)
      local _198_, _199_ = pcall(add_211, ...)
      if ((_198_ == true) and true) then
        local _ = _199_
        return _
      elseif ((_198_ == false) and (nil ~= _199_)) then
        local e = _199_
        return handler(c, e)
      else
        return nil
      end
    end
    local function _201_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "ManyToManyChannel:") .. ">")
    end
    return setmetatable(c, {__index = Channel, __name = "ManyToManyChannel", __fennelview = _201_})
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
        local function _203_()
          warned = false
          return nil
        end
        local tgt_204_ = timeout(10000)
        do end (tgt_204_)["take!"](tgt_204_, fn_handler(_203_))
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
    local or_207_ = timeouts[t]
    if not or_207_ then
      local c0 = chan()
      timeouts[t] = c0
      or_207_ = c0
    end
    c = or_207_
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
      local _210_ = port["take!"](port, fn_handler(fn1))
      if (nil ~= _210_) then
        local retb = _210_
        local val = retb[1]
        if on_caller_3f then
          fn1(val)
        else
          local function _211_()
            return fn1(val)
          end
          dispatch(_211_)
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
    local _215_ = timers[1]
    local and_216_ = (nil ~= _215_)
    if and_216_ then
      local t = _215_
      and_216_ = (sleep and not next(dispatched_tasks))
    end
    if and_216_ then
      local t = _215_
      local t0 = (t - time())
      if (t0 > 0) then
        sleep(t0)
        process_messages("manual")
      else
      end
      return true
    else
      local _ = _215_
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
    local function _221_(_241)
      val = _241
      return nil
    end
    take_21(port, _221_)
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
    local _223_ = port["take!"](port, fhnop)
    if (nil ~= _223_) then
      local retb = _223_
      return retb[1]
    else
      return nil
    end
  end
  local function put_21(port, val, ...)
    assert(chan_3f(port), "expected a channel as first argument")
    local _225_ = select("#", ...)
    if (_225_ == 0) then
      local _226_ = port["put!"](port, val, fhnop)
      if (nil ~= _226_) then
        local retb = _226_
        return retb[1]
      else
        local _ = _226_
        return true
      end
    elseif (_225_ == 1) then
      return put_21(port, val, ..., true)
    elseif (_225_ == 2) then
      local fn1, on_caller_3f = ...
      local _228_ = port["put!"](port, val, fn_handler(fn1))
      if (nil ~= _228_) then
        local retb = _228_
        local ret = retb[1]
        if on_caller_3f then
          fn1(ret)
        else
          local function _229_()
            return fn1(ret)
          end
          dispatch(_229_)
        end
        return ret
      else
        local _ = _228_
        return true
      end
    else
      return nil
    end
  end
  local function _3e_21_21(port, val)
    assert(main_thread_3f(), ">!! used not on the main thread")
    local not_done, res = true
    local function _233_(_241)
      not_done, res = false, _241
      return nil
    end
    put_21(port, val, _233_)
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
    local _235_ = port["put!"](port, val, fhnop)
    if (nil ~= _235_) then
      local retb = _235_
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
      local _237_, _238_ = nil, nil
      local function _239_()
        do
          local _240_ = fn1()
          if (nil ~= _240_) then
            local val = _240_
            _3e_21(c, val)
          else
          end
        end
        return close_21(c)
      end
      _237_, _238_ = c_2fresume(c_2fcreate(_239_))
      if ((_237_ == false) and (nil ~= _238_)) then
        local msg = _238_
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
    local _244_ = {}
    do
      do
        local _245_ = Handler["active?"]
        if (nil ~= _245_) then
          local f_3_auto = _245_
          local function _246_(_)
            return atom.flag
          end
          _244_["active?"] = _246_
        else
          local _ = _245_
          error("Protocol Handler doesn't define method active?")
        end
      end
      do
        local _248_ = Handler["blockable?"]
        if (nil ~= _248_) then
          local f_3_auto = _248_
          local function _249_(_)
            return true
          end
          _244_["blockable?"] = _249_
        else
          local _ = _248_
          error("Protocol Handler doesn't define method blockable?")
        end
      end
      local _251_ = Handler.commit
      if (nil ~= _251_) then
        local f_3_auto = _251_
        local function _252_(_)
          atom.flag = false
          return true
        end
        _244_["commit"] = _252_
      else
        local _ = _251_
        error("Protocol Handler doesn't define method commit")
      end
    end
    local function _254_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Handler" .. ">")
    end
    return setmetatable({}, {__fennelview = _254_, __index = _244_, name = "reify"})
  end
  local function alt_handler(flag, cb)
    local _255_ = {}
    do
      do
        local _256_ = Handler["active?"]
        if (nil ~= _256_) then
          local f_3_auto = _256_
          local function _257_(_)
            return flag["active?"](flag)
          end
          _255_["active?"] = _257_
        else
          local _ = _256_
          error("Protocol Handler doesn't define method active?")
        end
      end
      do
        local _259_ = Handler["blockable?"]
        if (nil ~= _259_) then
          local f_3_auto = _259_
          local function _260_(_)
            return true
          end
          _255_["blockable?"] = _260_
        else
          local _ = _259_
          error("Protocol Handler doesn't define method blockable?")
        end
      end
      local _262_ = Handler.commit
      if (nil ~= _262_) then
        local f_3_auto = _262_
        local function _263_(_)
          flag:commit()
          return cb
        end
        _255_["commit"] = _263_
      else
        local _ = _262_
        error("Protocol Handler doesn't define method commit")
      end
    end
    local function _265_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Handler" .. ">")
    end
    return setmetatable({}, {__fennelview = _265_, __index = _255_, name = "reify"})
  end
  local function alts_21(ports, ...)
    assert(not main_thread_3f(), "called alts! on the main thread")
    assert((#ports > 0), "alts must have at least one channel operation")
    local n = #ports
    local arglen = select("#", ...)
    local no_def = {}
    local opts
    do
      local _266_, _267_ = select("#", ...), ...
      if (_266_ == 0) then
        opts = {default = no_def}
      else
        local and_268_ = ((_266_ == 1) and (nil ~= _267_))
        if and_268_ then
          local t = _267_
          and_268_ = ("table" == type(t))
        end
        if and_268_ then
          local t = _267_
          local res = {default = no_def}
          for k, v in pairs(t) do
            res[k] = v
            res = res
          end
          opts = res
        else
          local _ = _266_
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
        local _272_ = ports[id]
        local and_273_ = ((_G.type(_272_) == "table") and true and true)
        if and_273_ then
          local _3fc = _272_[1]
          local _3fv = _272_[2]
          and_273_ = chan_3f(_3fc)
        end
        if and_273_ then
          local _3fc = _272_[1]
          local _3fv = _272_[2]
          local function _275_(_241)
            put_21(res_ch, {_241, _3fc})
            return close_21(res_ch)
          end
          retb, port = _3fc["put!"](_3fc, _3fv, alt_handler(flag, _275_), true), _3fc
        else
          local and_276_ = true
          if and_276_ then
            local _3fc = _272_
            and_276_ = chan_3f(_3fc)
          end
          if and_276_ then
            local _3fc = _272_
            local function _278_(_241)
              put_21(res_ch, {_241, _3fc})
              return close_21(res_ch)
            end
            retb, port = _3fc["take!"](_3fc, alt_handler(flag, _278_), true), _3fc
          else
            local _ = _272_
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
      local _282_ = port["put!"](port, val, fhnop)
      if (nil ~= _282_) then
        local retb = _282_
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
      local _285_ = port["take!"](port, fhnop)
      if (nil ~= _285_) then
        local retb = _285_
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
    local _let_289_ = require("lib.async")
    local go_1_auto = _let_289_["go"]
    local function _290_()
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
    return go_1_auto(_290_)
  end
  local function pipeline_2a(n, to, xf, from, close_3f, err_handler, kind)
    local jobs = chan(n)
    local results = chan(n)
    local finishes = ((kind == "async") and chan(n))
    local process
    local function _293_(job)
      if (job == nil) then
        close_21(results)
        return nil
      elseif ((_G.type(job) == "table") and (nil ~= job[1]) and (nil ~= job[2])) then
        local v = job[1]
        local p = job[2]
        local res = chan(1, xf, err_handler)
        do
          local _let_294_ = require("lib.async")
          local go_1_auto = _let_294_["go"]
          local function _295_()
            _3e_21(res, v)
            return close_21(res)
          end
          go_1_auto(_295_)
        end
        put_21(p, res)
        return true
      else
        return nil
      end
    end
    process = _293_
    local async
    local function _297_(job)
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
    async = _297_
    for _ = 1, n do
      if (kind == "compute") then
        local _let_299_ = require("lib.async")
        local go_1_auto = _let_299_["go"]
        local function _300_()
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
        go_1_auto(_300_)
      elseif (kind == "async") then
        local _let_302_ = require("lib.async")
        local go_1_auto = _let_302_["go"]
        local function _303_()
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
        go_1_auto(_303_)
      else
      end
    end
    do
      local _let_306_ = require("lib.async")
      local go_1_auto = _let_306_["go"]
      local function _307_()
        local function recur()
          local _308_ = _3c_21(from)
          if (_308_ == nil) then
            return close_21(jobs)
          elseif (nil ~= _308_) then
            local v = _308_
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
      go_1_auto(_307_)
    end
    local _let_310_ = require("lib.async")
    local go_1_auto = _let_310_["go"]
    local function _311_()
      local function recur()
        local _312_ = _3c_21(results)
        if (_312_ == nil) then
          if close_3f then
            return close_21(to)
          else
            return nil
          end
        elseif (nil ~= _312_) then
          local p = _312_
          local _314_ = _3c_21(p)
          if (nil ~= _314_) then
            local res = _314_
            local function loop_2a()
              local _315_ = _3c_21(res)
              if (nil ~= _315_) then
                local val = _315_
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
    return go_1_auto(_311_)
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
      local _let_322_ = require("lib.async")
      local go_1_auto = _let_322_["go"]
      local function _323_()
        local function recur()
          local v = _3c_21(ch)
          if (nil == v) then
            close_21(tc)
            return close_21(fc)
          else
            local _324_
            if p(v) then
              _324_ = tc
            else
              _324_ = fc
            end
            if _3e_21(_324_, v) then
              return recur()
            else
              return nil
            end
          end
        end
        return recur()
      end
      go_1_auto(_323_)
    end
    return {tc, fc}
  end
  local function reduce(f, init, ch)
    local _let_329_ = require("lib.async")
    local go_1_auto = _let_329_["go"]
    local function _330_()
      local _2_328_ = init
      local ret = _2_328_
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
      return recur(_2_328_)
    end
    return go_1_auto(_330_)
  end
  local function transduce(xform, f, init, ch)
    local f0 = xform(f)
    local _let_333_ = require("lib.async")
    local go_1_auto = _let_333_["go"]
    local function _334_()
      local ret = _3c_21(reduce(f0, init, ch))
      return f0(ret)
    end
    return go_1_auto(_334_)
  end
  local function onto_chan_21(ch, coll, ...)
    local close_3f
    if (select("#", ...) == 0) then
      close_3f = true
    else
      close_3f = ...
    end
    local _let_336_ = require("lib.async")
    local go_1_auto = _let_336_["go"]
    local function _337_()
      for _, v in ipairs(coll) do
        _3e_21(ch, v)
      end
      if close_3f then
        close_21(ch)
      else
      end
      return ch
    end
    return go_1_auto(_337_)
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
    local function _339_()
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
    closes = to_chan_21(_339_())
    local process
    local function _341_(v, p)
      local res = chan(1, xf, err_handler)
      local _let_342_ = require("lib.async")
      local go_1_auto = _let_342_["go"]
      local function _343_()
        _3e_21(res, v)
        close_21(res)
        local function loop()
          local _344_ = _3c_21(res)
          if (nil ~= _344_) then
            local v0 = _344_
            put_21(p, v0)
            return loop()
          else
            return nil
          end
        end
        loop()
        return close_21(p)
      end
      return go_1_auto(_343_)
    end
    process = _341_
    for _ = 1, n do
      local _let_346_ = require("lib.async")
      local go_1_auto = _let_346_["go"]
      local function _347_()
        local function recur()
          local _348_ = _3c_21(from)
          if (nil ~= _348_) then
            local v = _348_
            local c = chan(1)
            if (kind == "compute") then
              local _let_349_ = require("lib.async")
              local go_1_auto0 = _let_349_["go"]
              local function _350_()
                return process(v, c)
              end
              go_1_auto0(_350_)
            elseif (kind == "async") then
              local _let_351_ = require("lib.async")
              local go_1_auto0 = _let_351_["go"]
              local function _352_()
                return xf(v, c)
              end
              go_1_auto0(_352_)
            else
            end
            local function loop()
              local _354_ = _3c_21(c)
              if (nil ~= _354_) then
                local res = _354_
                if _3e_21(to, res) then
                  return loop()
                else
                  return nil
                end
              else
                local _0 = _354_
                return true
              end
            end
            if loop() then
              return recur()
            else
              return nil
            end
          else
            local _0 = _348_
            if (close_3f and (nil == _3c_21(closes))) then
              return close_21(to)
            else
              return nil
            end
          end
        end
        return recur()
      end
      go_1_auto(_347_)
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
  local _local_362_ = {["muxch*"] = muxch_2a}
  local muxch_2a0 = _local_362_["muxch*"]
  local Mux = _local_362_
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
  local _local_363_ = {["tap*"] = tap_2a, ["untap*"] = untap_2a, ["untap-all*"] = untap_all_2a}
  local tap_2a0 = _local_363_["tap*"]
  local untap_2a0 = _local_363_["untap*"]
  local untap_all_2a0 = _local_363_["untap-all*"]
  local Mult = _local_363_
  local function mult(ch)
    local dctr = nil
    local atom = {cs = {}}
    local m
    do
      local _364_ = {}
      do
        do
          local _365_ = Mux["muxch*"]
          if (nil ~= _365_) then
            local f_3_auto = _365_
            local function _366_(_)
              return ch
            end
            _364_["muxch*"] = _366_
          else
            local _ = _365_
            error("Protocol Mux doesn't define method muxch*")
          end
        end
        do
          local _368_ = Mult["tap*"]
          if (nil ~= _368_) then
            local f_3_auto = _368_
            local function _369_(_, ch0, close_3f)
              atom["cs"][ch0] = close_3f
              return nil
            end
            _364_["tap*"] = _369_
          else
            local _ = _368_
            error("Protocol Mult doesn't define method tap*")
          end
        end
        do
          local _371_ = Mult["untap*"]
          if (nil ~= _371_) then
            local f_3_auto = _371_
            local function _372_(_, ch0)
              atom["cs"][ch0] = nil
              return nil
            end
            _364_["untap*"] = _372_
          else
            local _ = _371_
            error("Protocol Mult doesn't define method untap*")
          end
        end
        local _374_ = Mult["untap-all*"]
        if (nil ~= _374_) then
          local f_3_auto = _374_
          local function _375_(_)
            atom["cs"] = {}
            return nil
          end
          _364_["untap-all*"] = _375_
        else
          local _ = _374_
          error("Protocol Mult doesn't define method untap-all*")
        end
      end
      local function _377_(_241)
        return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Mux, Mult" .. ">")
      end
      m = setmetatable({}, {__fennelview = _377_, __index = _364_, name = "reify"})
    end
    local dchan = chan(1)
    local done
    local function _378_(_)
      dctr = (dctr - 1)
      if (0 == dctr) then
        return put_21(dchan, true)
      else
        return nil
      end
    end
    done = _378_
    do
      local _let_380_ = require("lib.async")
      local go_1_auto = _let_380_["go"]
      local function _381_()
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
      go_1_auto(_381_)
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
  local _local_388_ = {["admix*"] = admix_2a, ["solo-mode*"] = solo_mode_2a, ["toggle*"] = toggle_2a, ["unmix*"] = unmix_2a, ["unmix-all*"] = unmix_all_2a}
  local admix_2a0 = _local_388_["admix*"]
  local solo_mode_2a0 = _local_388_["solo-mode*"]
  local toggle_2a0 = _local_388_["toggle*"]
  local unmix_2a0 = _local_388_["unmix*"]
  local unmix_all_2a0 = _local_388_["unmix-all*"]
  local Mix = _local_388_
  local function mix(out)
    local atom = {cs = {}, ["solo-mode"] = "mute"}
    local solo_modes = {mute = true, pause = true}
    local change = chan(sliding_buffer(1))
    local changed
    local function _389_()
      return put_21(change, true)
    end
    changed = _389_
    local pick
    local function _390_(attr, chs)
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
    pick = _390_
    local calc_state
    local function _393_()
      local chs = atom.cs
      local mode = atom["solo-mode"]
      local solos = pick("solo", chs)
      local pauses = pick("pause", chs)
      local _394_
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
        _394_ = tmp_9_auto
      end
      return {solos = solos, mutes = pick("mute", chs), reads = _394_}
    end
    calc_state = _393_
    local m
    do
      local _399_ = {}
      do
        do
          local _400_ = Mux["muxch*"]
          if (nil ~= _400_) then
            local f_3_auto = _400_
            local function _401_(_)
              return out
            end
            _399_["muxch*"] = _401_
          else
            local _ = _400_
            error("Protocol Mux doesn't define method muxch*")
          end
        end
        do
          local _403_ = Mix["admix*"]
          if (nil ~= _403_) then
            local f_3_auto = _403_
            local function _404_(_, ch)
              atom.cs[ch] = {}
              return changed()
            end
            _399_["admix*"] = _404_
          else
            local _ = _403_
            error("Protocol Mix doesn't define method admix*")
          end
        end
        do
          local _406_ = Mix["unmix*"]
          if (nil ~= _406_) then
            local f_3_auto = _406_
            local function _407_(_, ch)
              atom.cs[ch] = nil
              return changed()
            end
            _399_["unmix*"] = _407_
          else
            local _ = _406_
            error("Protocol Mix doesn't define method unmix*")
          end
        end
        do
          local _409_ = Mix["unmix-all*"]
          if (nil ~= _409_) then
            local f_3_auto = _409_
            local function _410_(_)
              atom.cs = {}
              return changed()
            end
            _399_["unmix-all*"] = _410_
          else
            local _ = _409_
            error("Protocol Mix doesn't define method unmix-all*")
          end
        end
        do
          local _412_ = Mix["toggle*"]
          if (nil ~= _412_) then
            local f_3_auto = _412_
            local function _413_(_, state_map)
              atom.cs = merge_with(merge_2a, atom.cs, state_map)
              return changed()
            end
            _399_["toggle*"] = _413_
          else
            local _ = _412_
            error("Protocol Mix doesn't define method toggle*")
          end
        end
        local _415_ = Mix["solo-mode*"]
        if (nil ~= _415_) then
          local f_3_auto = _415_
          local function _416_(_, mode)
            if not solo_modes[mode] then
              local _417_
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
                _417_ = tbl_21_auto
              end
              assert(false, ("mode must be one of: " .. t_2fconcat(_417_, ", ")))
            else
            end
            atom["solo-mode"] = mode
            return changed()
          end
          _399_["solo-mode*"] = _416_
        else
          local _ = _415_
          error("Protocol Mix doesn't define method solo-mode*")
        end
      end
      local function _421_(_241)
        return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Mux, Mix" .. ">")
      end
      m = setmetatable({}, {__fennelview = _421_, __index = _399_, name = "reify"})
    end
    do
      local _let_423_ = require("lib.async")
      local go_1_auto = _let_423_["go"]
      local function _424_()
        local _2_422_ = calc_state()
        local solos = _2_422_["solos"]
        local mutes = _2_422_["mutes"]
        local reads = _2_422_["reads"]
        local state = _2_422_
        local function recur(_425_)
          local solos0 = _425_["solos"]
          local mutes0 = _425_["mutes"]
          local reads0 = _425_["reads"]
          local state0 = _425_
          local _let_426_ = alts_21(reads0)
          local v = _let_426_[1]
          local c = _let_426_[2]
          local res = _let_426_
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
        return recur(_2_422_)
      end
      go_1_auto(_424_)
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
  local _local_431_ = {["sub*"] = sub_2a, ["unsub*"] = unsub_2a, ["unsub-all*"] = unsub_all_2a}
  local sub_2a0 = _local_431_["sub*"]
  local unsub_2a0 = _local_431_["unsub*"]
  local unsub_all_2a0 = _local_431_["unsub-all*"]
  local Pub = _local_431_
  local function pub(ch, topic_fn, buf_fn)
    local buf_fn0
    local or_432_ = buf_fn
    if not or_432_ then
      local function _433_()
        return nil
      end
      or_432_ = _433_
    end
    buf_fn0 = or_432_
    local atom = {mults = {}}
    local ensure_mult
    local function _434_(topic)
      local _435_ = atom.mults[topic]
      if (nil ~= _435_) then
        local m = _435_
        return m
      elseif (_435_ == nil) then
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
    ensure_mult = _434_
    local p
    do
      local _437_ = {}
      do
        do
          local _438_ = Mux["muxch*"]
          if (nil ~= _438_) then
            local f_3_auto = _438_
            local function _439_(_)
              return ch
            end
            _437_["muxch*"] = _439_
          else
            local _ = _438_
            error("Protocol Mux doesn't define method muxch*")
          end
        end
        do
          local _441_ = Pub["sub*"]
          if (nil ~= _441_) then
            local f_3_auto = _441_
            local function _442_(_, topic, ch0, close_3f)
              local m = ensure_mult(topic)
              return tap_2a0(m, ch0, close_3f)
            end
            _437_["sub*"] = _442_
          else
            local _ = _441_
            error("Protocol Pub doesn't define method sub*")
          end
        end
        do
          local _444_ = Pub["unsub*"]
          if (nil ~= _444_) then
            local f_3_auto = _444_
            local function _445_(_, topic, ch0)
              local _446_ = atom.mults[topic]
              if (nil ~= _446_) then
                local m = _446_
                return untap_2a0(m, ch0)
              else
                return nil
              end
            end
            _437_["unsub*"] = _445_
          else
            local _ = _444_
            error("Protocol Pub doesn't define method unsub*")
          end
        end
        local _449_ = Pub["unsub-all*"]
        if (nil ~= _449_) then
          local f_3_auto = _449_
          local function _450_(_, topic)
            if topic then
              atom["mults"][topic] = nil
              return nil
            else
              atom["mults"] = {}
              return nil
            end
          end
          _437_["unsub-all*"] = _450_
        else
          local _ = _449_
          error("Protocol Pub doesn't define method unsub-all*")
        end
      end
      local function _453_(_241)
        return ("#<" .. tostring(_241):gsub("table:", "reify:") .. ": " .. "Mux, Pub" .. ">")
      end
      p = setmetatable({}, {__fennelview = _453_, __index = _437_, name = "reify"})
    end
    do
      local _let_454_ = require("lib.async")
      local go_1_auto = _let_454_["go"]
      local function _455_()
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
              local _456_ = atom.mults[topic]
              if (nil ~= _456_) then
                local m = _456_
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
      go_1_auto(_455_)
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
        local function _461_(ret)
          rets[i] = ret
          dctr = (dctr - 1)
          if (0 == dctr) then
            return put_21(dchan, rets)
          else
            return nil
          end
        end
        val_23_auto = _461_
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
      local _let_464_ = require("lib.async")
      local go_1_auto = _let_464_["go"]
      local function _465_()
        local function recur()
          dctr = cnt
          for i = 1, cnt do
            local _466_ = pcall(take_21, chs[i], done[i])
            if (_466_ == false) then
              dctr = (dctr - 1)
            else
            end
          end
          local rets0 = _3c_21(dchan)
          local _468_
          do
            local res = false
            for i = 1, rets0.n do
              if res then break end
              res = (nil == rets0[i])
            end
            _468_ = res
          end
          if _468_ then
            return close_21(out)
          else
            _3e_21(out, f(t_2funpack(rets0)))
            return recur()
          end
        end
        return recur()
      end
      go_1_auto(_465_)
    end
    return out
  end
  local function merge(chs, buf_or_n)
    local out = chan(buf_or_n)
    do
      local _let_472_ = require("lib.async")
      local go_1_auto = _let_472_["go"]
      local function _473_()
        local _2_471_ = chs
        local cs = _2_471_
        local function recur(cs0)
          if (#cs0 > 0) then
            local _let_474_ = alts_21(cs0)
            local v = _let_474_[1]
            local c = _let_474_[2]
            if (nil == v) then
              local function _475_()
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
              return recur(_475_())
            else
              _3e_21(out, v)
              return recur(cs0)
            end
          else
            return close_21(out)
          end
        end
        return recur(_2_471_)
      end
      go_1_auto(_473_)
    end
    return out
  end
  local function into(t, ch)
    local function _480_(_241, _242)
      _241[(1 + #_241)] = _242
      return _241
    end
    return reduce(_480_, t, ch)
  end
  local function take(n, ch, buf_or_n)
    local out = chan(buf_or_n)
    do
      local _let_481_ = require("lib.async")
      local go_1_auto = _let_481_["go"]
      local function _482_()
        local done = false
        for i = 1, n do
          if done then break end
          local _483_ = _3c_21(ch)
          if (nil ~= _483_) then
            local v = _483_
            _3e_21(out, v)
          elseif (_483_ == nil) then
            done = true
          else
          end
        end
        return close_21(out)
      end
      go_1_auto(_482_)
    end
    return out
  end
  return {buffer = buffer, ["dropping-buffer"] = dropping_buffer, ["sliding-buffer"] = sliding_buffer, ["promise-buffer"] = promise_buffer, ["unblocking-buffer?"] = unblocking_buffer_3f, ["main-thread?"] = main_thread_3f, chan = chan, ["chan?"] = chan_3f, ["promise-chan"] = promise_chan, ["take!"] = take_21, ["<!!"] = _3c_21_21, ["<!"] = _3c_21, timeout = timeout, ["put!"] = put_21, [">!!"] = _3e_21_21, [">!"] = _3e_21, ["close!"] = close_21, go = go_2a, ["alts!"] = alts_21, ["offer!"] = offer_21, ["poll!"] = poll_21, pipe = pipe, ["pipeline-async"] = pipeline_async, pipeline = pipeline, ["pipeline-async-unordered"] = pipeline_async_unordered, ["pipeline-unordered"] = pipeline_unordered, reduce = reduce, reduced = reduced, ["reduced?"] = reduced_3f, transduce = transduce, split = split, ["onto-chan!"] = onto_chan_21, ["to-chan!"] = to_chan_21, mult = mult, tap = tap, untap = untap, ["untap-all"] = untap_all, mix = mix, admix = admix, unmix = unmix, ["unmix-all"] = unmix_all, toggle = toggle, ["solo-mode"] = solo_mode, pub = pub, sub = sub, unsub = unsub, ["unsub-all"] = unsub_all, map = map, merge = merge, into = into, take = take, buffers = {FixedBuffer = FixedBuffer, SlidingBuffer = SlidingBuffer, DroppingBuffer = DroppingBuffer, PromiseBuffer = PromiseBuffer}}
end
package.preload["http.async-extras"] = package.preload["http.async-extras"] or function(...)
  local _local_486_ = require("lib.async")
  local _3e_21 = _local_486_[">!"]
  local _3c_21 = _local_486_["<!"]
  local _3e_21_21 = _local_486_[">!!"]
  local _3c_21_21 = _local_486_["<!!"]
  local chan_3f = _local_486_["chan?"]
  local main_thread_3f = _local_486_["main-thread?"]
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
  local _local_576_ = require("http.readers")
  local make_reader = _local_576_["make-reader"]
  local string_reader = _local_576_["string-reader"]
  local _local_643_ = require("http.json")
  local decode = _local_643_["decode"]
  local _local_654_ = require("http.headers")
  local decode_value = _local_654_["decode-value"]
  local capitalize_header = _local_654_["capitalize-header"]
  local function parse_header(line)
    local _655_, _656_ = line:match(" *([^:]+) *: *(.*)")
    if ((nil ~= _655_) and (nil ~= _656_)) then
      local header = _655_
      local value = _656_
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
      local function _660_()
        local _658_, _659_ = parse_header((line or ""))
        if ((nil ~= _658_) and (nil ~= _659_)) then
          local header = _658_
          local value = _659_
          headers[header] = value
          return headers
        else
          return nil
        end
      end
      return read_headers(src, _660_())
    end
  end
  local function parse_response_status_line(status)
    if status then
      local function loop(reader, fields, res)
        if ((_G.type(fields) == "table") and (nil ~= fields[1])) then
          local field = fields[1]
          local fields0 = {select(2, (table.unpack or _G.unpack)(fields))}
          local part = reader()
          local function _663_()
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
          return loop(reader, fields0, _663_())
        else
          local _ = fields
          local reason = status:gsub(string.format("%s/%s.%s +%s +", res["protocol-version"].name, res["protocol-version"].major, res["protocol-version"].minor, res.status), "")
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
    local function _666_(src0, pattern)
      local rdr = string_reader(buffer)
      local buffer_content = rdr:read(pattern)
      local and_667_ = (nil ~= pattern)
      if and_667_ then
        local n = pattern
        and_667_ = ("number" == type(n))
      end
      if and_667_ then
        local n = pattern
        local len
        if buffer_content then
          len = #buffer_content
        else
          len = 0
        end
        local read_more_3f = (len < n)
        buffer = string.sub(buffer, (len + 1))
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
          buffer = string.sub(buffer, (#buffer_content + 2))
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
        local _675_ = src0:read(pattern)
        if (_675_ == nil) then
          if buffer_content then
            return buffer_content
          else
            return nil
          end
        elseif (nil ~= _675_) then
          local data = _675_
          return ((buffer_content or "") .. data)
        else
          return nil
        end
      else
        local _ = pattern
        return error(tostring(pattern))
      end
    end
    local function _679_(src0)
      local rdr = string_reader(buffer)
      local buffer_content = rdr:read("*l")
      local read_more_3f = not buffer:find("\n")
      if buffer_content then
        buffer = string.sub(buffer, (#buffer_content + 2))
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
    local function _683_(src0)
      return src0:close()
    end
    local function _684_(src0, bytes)
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
    return make_reader(src, {["read-bytes"] = _666_, ["read-line"] = _679_, close = _683_, peek = _684_})
  end
  local function read_chunk_size(src)
    local _686_ = src:read("*l")
    if (_686_ == "") then
      return read_chunk_size(src)
    elseif (nil ~= _686_) then
      local line = _686_
      local _687_ = line:match("%s*([0-9a-fA-F]+)")
      if (nil ~= _687_) then
        local size = _687_
        return tonumber(("0x" .. size))
      else
        local _ = _687_
        return error(string.format("line missing chunk size: %q", line))
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
    local function _692_(_, pattern)
      local rdr = string_reader(buffer)
      local and_693_ = (nil ~= pattern)
      if and_693_ then
        local n = pattern
        and_693_ = ("number" == type(n))
      end
      if and_693_ then
        local n = pattern
        local buffer_content = rdr:read(pattern)
        local len
        if buffer_content then
          len = #buffer_content
        else
          len = 0
        end
        local read_more_3f = (len < n)
        buffer = string.sub(buffer, (len + 1))
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
          buffer = string.sub(buffer, (#buffer_content + 2))
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
        local _701_ = rdr0:read("*a")
        if (_701_ == nil) then
          if buffer_content then
            return buffer_content
          else
            return nil
          end
        elseif (nil ~= _701_) then
          local data = _701_
          return ((buffer_content or "") .. data)
        else
          return nil
        end
      else
        local _0 = pattern
        return error(tostring(pattern))
      end
    end
    local function _705_(src0)
      local rdr = string_reader(buffer)
      local buffer_content = rdr:read("*l")
      local read_more_3f = not buffer:find("\n")
      if buffer_content then
        buffer = string.sub(buffer, (#buffer_content + 2))
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
    local function _709_(src0)
      return src0:close()
    end
    local function _710_(_, bytes)
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
    return make_reader(src, {["read-bytes"] = _692_, ["read-line"] = _705_, close = _709_, peek = _710_})
  end
  local non_error_statuses = {[200] = true, [201] = true, [202] = true, [203] = true, [204] = true, [205] = true, [206] = true, [207] = true, [300] = true, [301] = true, [302] = true, [303] = true, [304] = true, [307] = true}
  local function parse_http_response(src, _712_)
    local as = _712_["as"]
    local parse_headers_3f = _712_["parse-headers?"]
    local start = _712_["start"]
    local time = _712_["time"]
    local throw_errors_3f = _712_["throw-errors?"]
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
    do
      local _714_ = string.lower((parsed_headers["Transfer-Encoding"] or ""))
      local and_715_ = (nil ~= _714_)
      if and_715_ then
        local header = _714_
        and_715_ = (header:match("chunked[, ]") or header:match("chunked$"))
      end
      if and_715_ then
        local header = _714_
        chunk_size = read_chunk_size(src)
      else
        chunk_size = nil
      end
    end
    local stream
    if chunk_size then
      stream = chunked_body_reader(src, chunk_size)
    else
      stream = body_reader(src)
    end
    local response
    do
      local _719_
      if parse_headers_3f then
        _719_ = parsed_headers
      else
        _719_ = headers
      end
      status["headers"] = _719_
      status["length"] = tonumber(parsed_headers["Content-Length"])
      status["http-client"] = src
      local _721_
      if (start and time) then
        _721_ = math.ceil((1000 * (time() - start)))
      else
        _721_ = nil
      end
      status["request-time"] = _721_
      local _723_
      if (as == "raw") then
        _723_ = stream:read((parsed_headers["Content-Length"] or "*a"))
      elseif (as == "json") then
        _723_ = decode(stream)
      elseif (as == "stream") then
        _723_ = stream
      else
        local _ = as
        _723_ = error(string.format("unsupported coersion method '%s'", as))
      end
      status["body"] = _723_
      response = status
    end
    if (throw_errors_3f and not non_error_statuses[response.status]) then
      return error(response)
    else
      return response
    end
  end
  local function parse_request_status_line(status)
    local function loop(reader, fields, res)
      if ((_G.type(fields) == "table") and (nil ~= fields[1])) then
        local field = fields[1]
        local fields0 = {select(2, (table.unpack or _G.unpack)(fields))}
        local part = reader()
        local function _730_()
          res[field] = decode_value(part)
          return res
        end
        return loop(reader, fields0, _730_())
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
      local _732_
      if port then
        _732_ = ":"
      else
        _732_ = ""
      end
      host = authority:match(("@([^:]+)" .. _732_))
    else
      local _734_
      if port then
        _734_ = ":"
      else
        _734_ = ""
      end
      host = authority:match(("([^:]+)" .. _734_))
    end
    return {userinfo = userinfo, port = port, host = host}
  end
  local function parse_url(url)
    local scheme = url:match("^([^:]+)://")
    local function _737_()
      if scheme then
        return url:match("//([^/]+)/?")
      else
        return url:match("^([^/]+)/?")
      end
    end
    local _let_738_ = parse_authority(_737_())
    local host = _let_738_["host"]
    local port = _let_738_["port"]
    local userinfo = _let_738_["userinfo"]
    local scheme0 = (scheme or "http")
    local port0
    local or_739_ = port
    if not or_739_ then
      if (scheme0 == "https") then
        or_739_ = 443
      elseif (scheme0 == "http") then
        or_739_ = 80
      else
        or_739_ = nil
      end
    end
    port0 = or_739_
    local path = url:match("//[^/]+(/[^?#]*)")
    local query = url:match("%?([^#]+)#?")
    local fragment = url:match("#([^?]+)%??")
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
  local function make_reader(source, _491_)
    local read_bytes = _491_["read-bytes"]
    local read_line = _491_["read-line"]
    local close = _491_["close"]
    local peek = _491_["peek"]
    local len = _491_["length"]
    local close0
    if close then
      local function _492_(_, ...)
        return ok_3f(pcall(close, source, ...))
      end
      close0 = _492_
    else
      local function _493_()
        return nil
      end
      close0 = _493_
    end
    local _495_
    if read_bytes then
      local function _496_(_, pattern, ...)
        return read_bytes(source, pattern, ...)
      end
      _495_ = _496_
    else
      local function _497_()
        return nil
      end
      _495_ = _497_
    end
    local _499_
    if read_line then
      local function _500_()
        local function _501_(_, ...)
          return read_line(source, ...)
        end
        return _501_
      end
      _499_ = _500_
    else
      local function _502_()
        local function _503_()
          return nil
        end
        return _503_
      end
      _499_ = _502_
    end
    local _505_
    if peek then
      local function _506_(_, pattern, ...)
        return peek(source, pattern, ...)
      end
      _505_ = _506_
    else
      local function _507_()
        return nil
      end
      _505_ = _507_
    end
    local _509_
    if len then
      local function _510_()
        return len(source)
      end
      _509_ = _510_
    else
      local function _511_()
        return nil
      end
      _509_ = _511_
    end
    local function _513_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "Reader:") .. ">")
    end
    return setmetatable({close = close0, read = _495_, lines = _499_, peek = _505_, length = _509_}, {__index = Reader, __close = close0, __name = "Reader", __fennelview = _513_})
  end
  local function file_reader(file)
    local file0
    do
      local _514_ = type(file)
      if (_514_ == "string") then
        file0 = io.open(file, "r")
      else
        local _ = _514_
        file0 = file
      end
    end
    local open_3f
    local function _516_(_241)
      local function _517_(_2410)
        return _2410:read(0)
      end
      return (pcall(_517_, _241))
    end
    open_3f = _516_
    local function _518_(_241)
      if open_3f(_241) then
        return _241:close()
      else
        return nil
      end
    end
    local function _520_(f, pattern)
      if open_3f(f) then
        return f:read(pattern)
      else
        return nil
      end
    end
    local function _522_(f)
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
    local function _525_(f, pattern)
      assert(("number" == type(pattern)), "expected number of bytes to peek")
      if open_3f(f) then
        local res = f:read(pattern)
        f:seek("cur", ( - pattern))
        return res
      else
        return nil
      end
    end
    local function _527_(f)
      if open_3f(f) then
        local current = f:seek("cur")
        local len = (f:seek("end") - current)
        f:seek("cur", ( - len))
        return len
      else
        return nil
      end
    end
    return make_reader(file0, {close = _518_, ["read-bytes"] = _520_, ["read-line"] = _522_, peek = _525_, length = _527_})
  end
  local function string_reader(string)
    local i, closed_3f = 1, false
    local len = #string
    local try_read_line
    local function _529_(s, pattern)
      local _530_, _531_, _532_ = s:find(pattern, i)
      if (true and (nil ~= _531_) and (nil ~= _532_)) then
        local _ = _530_
        local _end = _531_
        local s0 = _532_
        i = (_end + 1)
        return s0
      else
        return nil
      end
    end
    try_read_line = _529_
    local read_line
    local function _534_(s)
      if (i <= len) then
        return (try_read_line(s, "(.-)\13?\n") or try_read_line(s, "(.-)\13?$"))
      else
        return nil
      end
    end
    read_line = _534_
    local function _536_(_)
      if not closed_3f then
        i = (len + 1)
        closed_3f = true
        return closed_3f
      else
        return nil
      end
    end
    local function _538_(s, pattern)
      if (i <= len) then
        if ((pattern == "*l") or (pattern == "l")) then
          return read_line(s)
        elseif ((pattern == "*a") or (pattern == "a")) then
          return s:sub(i)
        else
          local and_539_ = (nil ~= pattern)
          if and_539_ then
            local bytes = pattern
            and_539_ = ("number" == type(bytes))
          end
          if and_539_ then
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
    local function _543_(s, pattern)
      if (i <= len) then
        local and_544_ = (nil ~= pattern)
        if and_544_ then
          local bytes = pattern
          and_544_ = ("number" == type(bytes))
        end
        if and_544_ then
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
    local function _548_(s)
      if not closed_3f then
        return math.max(0, (#s - (i - 1)))
      else
        return nil
      end
    end
    return make_reader(string, {close = _536_, ["read-bytes"] = _538_, ["read-line"] = read_line, peek = _543_, length = _548_})
  end
  local ltn_3f, ltn12 = pcall(require, "ltn12")
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
        local and_550_ = (nil ~= pattern)
        if and_550_ then
          local bytes = pattern
          and_550_ = ("number" == type(bytes))
        end
        if and_550_ then
          local bytes = pattern
          buffer = (rdr:read("*a") or "")
          if (len < pattern) then
            if step0(source, ltn12.sink.table(data)) then
              buffer = (buffer .. (data[1] or ""))
              local _552_ = read(_, (bytes - len))
              local and_553_ = (nil ~= _552_)
              if and_553_ then
                local data0 = _552_
                and_553_ = data0
              end
              if and_553_ then
                local data0 = _552_
                return ((content or "") .. data0)
              else
                local _0 = _552_
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
          while step0(source, ltn12.sink.table(data)) do
          end
          return ((content or "") .. table.concat(data))
        elseif ((pattern == "*l") or (pattern == "l")) then
          if buffer:match("\n") then
            buffer = (rdr:read("*a") or "")
            return content
          else
            if step0(source, ltn12.sink.table(data)) then
              buffer = (buffer .. (data[1] or ""))
              local _558_ = read(_, pattern)
              if (nil ~= _558_) then
                local data0 = _558_
                return ((content or "") .. data0)
              else
                local _0 = _558_
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
    local function _564_()
      while step0(source, ltn12.sink.null()) do
      end
      closed_3f = true
      return nil
    end
    local function _565_(_241)
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
          if step0(source, ltn12.sink.table(data)) then
            buffer = (buffer .. (data[1] or ""))
            local _567_ = peek(_, (bytes - len))
            local and_568_ = (nil ~= _567_)
            if and_568_ then
              local data0 = _567_
              and_568_ = data0
            end
            if and_568_ then
              local data0 = _567_
              return data0
            else
              local _0 = _567_
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
    return make_reader(source, {close = _564_, ["read-bytes"] = read, ["read-line"] = _565_, peek = peek})
  end
  local function reader_3f(obj)
    local _574_ = getmetatable(obj)
    if ((_G.type(_574_) == "table") and (_574_.__index == Reader)) then
      return true
    else
      local _ = _574_
      return false
    end
  end
  return {["make-reader"] = make_reader, ["file-reader"] = file_reader, ["string-reader"] = string_reader, ["reader?"] = reader_3f, ["ltn12-reader"] = (ltn_3f and ltn12_reader)}
end
package.preload["http.json"] = package.preload["http.json"] or function(...)
  local _local_577_ = require("http.readers")
  local reader_3f = _local_577_["reader?"]
  local string_reader = _local_577_["string-reader"]
  local function _string_3f(val)
    return (("string" == type(val)) and {string = val})
  end
  local function _number_3f(val)
    return (("number" == type(val)) and {number = val})
  end
  local function _object_3f(val)
    return (("table" == type(val)) and {object = val})
  end
  local function _array_3f(val, _3fmax)
    local and_578_ = _object_3f(val)
    if and_578_ then
      local _579_ = #val
      if (_579_ == 0) then
        and_578_ = false
      elseif (nil ~= _579_) then
        local len = _579_
        local max = (_3fmax or len)
        local _584_ = next(val, max)
        local and_586_ = (nil ~= _584_)
        if and_586_ then
          local k = _584_
          and_586_ = ("number" == type(k))
        end
        if and_586_ then
          local k = _584_
          and_578_ = _array_3f(val, k)
        elseif (_584_ == nil) then
          and_578_ = {n = max, array = val}
        else
          local _ = _584_
          and_578_ = false
        end
      else
        and_578_ = nil
      end
    end
    return and_578_
  end
  local function _function_3f(val)
    return (("function" == type(val)) and {["function"] = val})
  end
  local function _guess(val)
    return (_array_3f(val) or _object_3f(val) or _string_3f(val) or _number_3f(val) or _function_3f(val) or val)
  end
  local function _escape_string(str)
    local escs
    local function _593_(_241, _242)
      return ("\\%03d"):format(_242:byte())
    end
    escs = setmetatable({["\7"] = "\\a", ["\8"] = "\\b", ["\12"] = "\\f", ["\11"] = "\\v", ["\13"] = "\\r", ["\t"] = "\\t", ["\\"] = "\\\\", ["\""] = "\\\"", ["\n"] = "\\n"}, {__index = _593_})
    return ("\"" .. str:gsub("[%c\\\"]", escs) .. "\"")
  end
  local function encode(val)
    local _594_ = _guess(val)
    if ((_G.type(_594_) == "table") and (nil ~= _594_.array) and (nil ~= _594_.n)) then
      local array = _594_.array
      local n = _594_.n
      local _595_
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
        _595_ = tbl_21_auto
      end
      return ("[" .. table.concat(_595_, ", ") .. "]")
    elseif ((_G.type(_594_) == "table") and (nil ~= _594_.object)) then
      local object = _594_.object
      local _597_
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
        _597_ = tbl_21_auto
      end
      return ("{" .. table.concat(_597_, ", ") .. "}")
    elseif ((_G.type(_594_) == "table") and (nil ~= _594_.string)) then
      local s = _594_.string
      return _escape_string(s)
    elseif ((_G.type(_594_) == "table") and (nil ~= _594_.number)) then
      local n = _594_.number
      return string.gsub(tostring(n), ",", ".")
    elseif ((_G.type(_594_) == "table") and (nil ~= _594_["function"])) then
      local f = _594_["function"]
      return error(("JSON encoding error: don't know how to encode function value: " .. tostring(f)))
    elseif (_594_ == true) then
      return "true"
    elseif (_594_ == false) then
      return "false"
    elseif (_594_ == nil) then
      return "null"
    else
      local _ = _594_
      return _escape_string(tostring(val))
    end
  end
  local function _skip_space(rdr)
    local function loop()
      local _600_ = rdr:peek(1)
      local and_601_ = (nil ~= _600_)
      if and_601_ then
        local c = _600_
        and_601_ = c:match("[ \t\n]")
      end
      if and_601_ then
        local c = _600_
        return loop(rdr:read(1))
      else
        return nil
      end
    end
    return loop()
  end
  local function _parse_num(rdr)
    local function loop(numbers)
      local _604_ = rdr:peek(1)
      local and_605_ = (nil ~= _604_)
      if and_605_ then
        local n = _604_
        and_605_ = n:match("[-0-9.eE+]")
      end
      if and_605_ then
        local n = _604_
        rdr:read(1)
        return loop((numbers .. n))
      else
        local _ = _604_
        return tonumber(numbers)
      end
    end
    return loop(rdr:read(1))
  end
  local _escapable = {["\""] = "\"", ["'"] = "'", ["\\"] = "\\", b = "\8", f = "\12", n = "\n", r = "\13", t = "\t"}
  local function _parse_string(rdr)
    rdr:read(1)
    local function loop(chars, escaped_3f)
      local ch = rdr:read(1)
      if (ch == "\\") then
        if escaped_3f then
          return loop((chars .. ch), false)
        else
          local _608_ = rdr:peek(1)
          local and_609_ = (nil ~= _608_)
          if and_609_ then
            local c = _608_
            and_609_ = _escapable[c]
          end
          if and_609_ then
            local c = _608_
            return loop(chars, true)
          else
            local and_611_ = (_608_ == "u")
            if and_611_ then
              and_611_ = (_G.utf8 and (rdr:peek(5) or ""):match("u%x%x%x%x"))
            end
            if and_611_ then
              return loop((chars .. _G.utf8.char(tonumber(("0x" .. rdr:read(5):match("u(%x%x%x%x)"))))))
            elseif (nil ~= _608_) then
              local c = _608_
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
        local and_616_ = (nil ~= ch)
        if and_616_ then
          local c = ch
          and_616_ = (escaped_3f and _escapable[c])
        end
        if and_616_ then
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
  local function _parse_obj(rdr, parse)
    rdr:read(1)
    local function loop(obj)
      _skip_space(rdr)
      local _619_ = rdr:peek(1)
      if (_619_ == "}") then
        rdr:read(1)
        return obj
      else
        local _ = _619_
        local key = parse()
        _skip_space(rdr)
        local _620_ = rdr:peek(1)
        if (_620_ == ":") then
          local _0 = rdr:read(1)
          local value = parse()
          obj[key] = value
          _skip_space(rdr)
          local _621_ = rdr:peek(1)
          if (_621_ == ",") then
            rdr:read(1)
            return loop(obj)
          elseif (_621_ == "}") then
            rdr:read(1)
            return obj
          else
            local _1 = _621_
            return error(("JSON parse error: expected ',' or '}' after the value: " .. encode(value)))
          end
        else
          local _0 = _620_
          return error(("JSON parse error: expected colon after the key: " .. encode(key)))
        end
      end
    end
    return loop({})
  end
  local function _parse_arr(rdr, parse)
    rdr:read(1)
    local len = 0
    local function loop(arr)
      _skip_space(rdr)
      local _625_ = rdr:peek(1)
      if (_625_ == "]") then
        rdr:read(1)
        return arr
      else
        local _ = _625_
        local val = parse()
        len = (1 + len)
        arr[len] = val
        _skip_space(rdr)
        local _626_ = rdr:peek(1)
        if (_626_ == ",") then
          rdr:read(1)
          return loop(arr)
        elseif (_626_ == "]") then
          rdr:read(1)
          return arr
        else
          local _0 = _626_
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
    elseif _string_3f(data) then
      rdr = string_reader(data)
    else
      rdr = error("expected a reader, or a string as input", 2)
    end
    local function loop()
      local _630_ = rdr:peek(1)
      if (_630_ == "{") then
        return _parse_obj(rdr, loop)
      elseif (_630_ == "[") then
        return _parse_arr(rdr, loop)
      elseif (_630_ == "\"") then
        return _parse_string(rdr)
      else
        local and_631_ = (_630_ == "t")
        if and_631_ then
          and_631_ = ("true" == rdr:peek(4))
        end
        if and_631_ then
          rdr:read(4)
          return true
        else
          local and_633_ = (_630_ == "f")
          if and_633_ then
            and_633_ = ("false" == rdr:peek(5))
          end
          if and_633_ then
            rdr:read(5)
            return false
          else
            local and_635_ = (_630_ == "n")
            if and_635_ then
              and_635_ = ("null" == rdr:peek(4))
            end
            if and_635_ then
              rdr:read(4)
              return nil
            else
              local and_637_ = (nil ~= _630_)
              if and_637_ then
                local c = _630_
                and_637_ = c:match("[ \t\n]")
              end
              if and_637_ then
                local c = _630_
                return loop(_skip_space(rdr))
              else
                local and_639_ = (nil ~= _630_)
                if and_639_ then
                  local n = _630_
                  and_639_ = n:match("[-0-9]")
                end
                if and_639_ then
                  local n = _630_
                  return _parse_num(rdr)
                elseif (_630_ == nil) then
                  return error("JSON parse error: end of stream")
                elseif (nil ~= _630_) then
                  local c = _630_
                  return error(string.format("JSON parse error: unexpected token ('%s' (code %d))", c, c:byte()))
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
  local function _642_(_, value)
    return encode(value)
  end
  return setmetatable({encode = encode, decode = decode}, {__call = _642_})
end
package.preload["http.headers"] = package.preload["http.headers"] or function(...)
  local function __3ekebab_case(str)
    local function _644_()
      local res,case_change_3f = "", false
      for c in string.gmatch(str, ".") do
        local function _645_()
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
        local _set_647_ = _645_()
        res = _set_647_[1]
        case_change_3f = _set_647_[2]
      end
      return {res, case_change_3f}
    end
    local _let_648_ = _644_()
    local res = _let_648_[1]
    return res
  end
  local function capitalize_header(header)
    local header0 = __3ekebab_case(header)
    local _649_
    do
      local tbl_21_auto = {}
      local i_22_auto = 0
      for word in header0:gmatch("[^-]+") do
        local val_23_auto = string.gsub(string.lower(word), "^%l", string.upper)
        if (nil ~= val_23_auto) then
          i_22_auto = (i_22_auto + 1)
          tbl_21_auto[i_22_auto] = val_23_auto
        else
        end
      end
      _649_ = tbl_21_auto
    end
    return table.concat(_649_, "-")
  end
  local function decode_value(value)
    local _651_ = tonumber(value)
    if (nil ~= _651_) then
      local n = _651_
      return n
    else
      local _ = _651_
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
  local _local_743_ = require("lib.async")
  local chan = _local_743_["chan"]
  local _3c_21 = _local_743_["<!"]
  local _3e_21 = _local_743_[">!"]
  local offer_21 = _local_743_["offer!"]
  local timeout = _local_743_["timeout"]
  local close_21 = _local_743_["close!"]
  local socket = require("socket")
  local function _set_chunk_size(self, pattern_or_size)
    self["chunk-size"] = pattern_or_size
    return nil
  end
  local function _socket_channel(client, xform, err_handler)
    local recv = chan(1024, xform, err_handler)
    local resp = chan(1024, xform, err_handler)
    local ready = chan()
    local close
    local function _744_(self)
      recv["close!"](recv)
      resp["close!"](resp)
      self.closed = true
      return nil
    end
    close = _744_
    local c
    local function _745_(_, val, handler, enqueue_3f)
      return recv["put!"](recv, val, handler, enqueue_3f)
    end
    local function _746_(_, handler, enqueue_3f)
      offer_21(ready, "ready")
      return resp["take!"](resp, handler, enqueue_3f)
    end
    local function _747_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "SocketChannel:") .. ">")
    end
    c = setmetatable({puts = recv.puts, takes = resp.takes, ["put!"] = _745_, ["take!"] = _746_, ["close!"] = close, close = close, ["chunk-size"] = 1024, ["set-chunk-size"] = _set_chunk_size}, {__index = getmetatable(ready).__index, __name = "SocketChannel", __fennelview = _747_})
    do
      local _let_750_ = require("lib.async")
      local go_1_auto = _let_750_["go"]
      local function _751_()
        local _2_748_ = _3c_21(recv)
        local data = _2_748_
        local _4_749_ = 0
        local i = _4_749_
        local function recur(data0, i0)
          if (nil ~= data0) then
            local _752_, _753_ = socket.select(nil, {client}, 0)
            if (true and ((_G.type(_753_) == "table") and (nil ~= _753_[1]))) then
              local _ = _752_
              local s = _753_[1]
              local _754_, _755_, _756_ = s:send(data0, i0)
              if ((_754_ == nil) and (_755_ == "timeout") and (nil ~= _756_)) then
                local j = _756_
                _3c_21(timeout(10))
                return recur(data0, j)
              elseif ((_754_ == nil) and (_755_ == "closed")) then
                s:close()
                return close_21(c)
              else
                local _0 = _754_
                return recur(_3c_21(recv), 0)
              end
            else
              local _ = _752_
              _3c_21(timeout(10))
              return recur(data0, i0)
            end
          else
            return nil
          end
        end
        return recur(_2_748_, _4_749_)
      end
      go_1_auto(_751_)
    end
    do
      local _let_763_ = require("lib.async")
      local go_1_auto = _let_763_["go"]
      local function _764_()
        local _2_760_ = true
        local wait_3f = _2_760_
        local _4_761_ = ""
        local part = _4_761_
        local _6_762_ = nil
        local remaining = _6_762_
        local function recur(wait_3f0, part0, remaining0)
          if wait_3f0 then
            _3c_21(ready)
          else
          end
          local size = (remaining0 or c["chunk-size"])
          local _766_, _767_, _768_ = client:receive(size, "")
          if (nil ~= _766_) then
            local data = _766_
            _3e_21(resp, (part0 .. data))
            return recur(true, "", nil)
          else
            local and_769_ = ((_766_ == nil) and (_767_ == "closed") and true)
            if and_769_ then
              local _3fdata = _768_
              and_769_ = ((_3fdata == nil) or (_3fdata == ""))
            end
            if and_769_ then
              local _3fdata = _768_
              client:close()
              return close_21(c)
            elseif ((_766_ == nil) and (_767_ == "closed") and (nil ~= _768_)) then
              local data = _768_
              client:close()
              _3e_21(resp, data)
              return close_21(c)
            else
              local and_771_ = ((_766_ == nil) and (_767_ == "timeout") and true)
              if and_771_ then
                local _3fdata = _768_
                and_771_ = ((_3fdata == nil) or (_3fdata == ""))
              end
              if and_771_ then
                local _3fdata = _768_
                _3c_21(timeout(10))
                return recur(false, part0, remaining0)
              elseif ((_766_ == nil) and (_767_ == "timeout") and (nil ~= _768_)) then
                local data = _768_
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
        return recur(_2_760_, _4_761_, _6_762_)
      end
      go_1_auto(_764_)
    end
    return c
  end
  local function chan0(_776_, xform, err_handler)
    local host = _776_["host"]
    local port = _776_["port"]
    assert(socket, "tcp module requires luasocket")
    local host0 = (host or "localhost")
    local function _777_(...)
      local _778_, _779_ = ...
      if (nil ~= _778_) then
        local client = _778_
        local function _780_(...)
          local _781_, _782_ = ...
          if true then
            local _ = _781_
            return _socket_channel(client, xform, err_handler)
          elseif ((_781_ == nil) and (nil ~= _782_)) then
            local err = _782_
            return error(err)
          else
            return nil
          end
        end
        return _780_(client:settimeout(0))
      elseif ((_778_ == nil) and (nil ~= _779_)) then
        local err = _779_
        return error(err)
      else
        return nil
      end
    end
    return _777_(socket.connect(host0, port))
  end
  return {chan = chan0}
end
package.preload["http.builder"] = package.preload["http.builder"] or function(...)
  local HTTP_VERSION = "HTTP/1.1"
  local _local_786_ = require("http.headers")
  local capitalize_header = _local_786_["capitalize-header"]
  local function _header__3estring(header, value)
    return (capitalize_header(header) .. ": " .. tostring(value) .. "\13\n")
  end
  local function headers__3estring(headers)
    if (headers and next(headers)) then
      local function _787_()
        local tbl_21_auto = {}
        local i_22_auto = 0
        for header, value in pairs(headers) do
          local val_23_auto = _header__3estring(header, value)
          if (nil ~= val_23_auto) then
            i_22_auto = (i_22_auto + 1)
            tbl_21_auto[i_22_auto] = val_23_auto
          else
          end
        end
        return tbl_21_auto
      end
      return table.concat(_787_())
    else
      return nil
    end
  end
  local function build_http_request(method, request_target, _3fheaders, _3fcontent)
    return string.format("%s %s %s\13\n%s\13\n%s", string.upper(method), request_target, HTTP_VERSION, (headers__3estring(_3fheaders) or ""), (_3fcontent or ""))
  end
  local function build_http_response(status, reason, _3fheaders, _3fcontent)
    return string.format("%s %s %s\13\n%s\13\n%s", HTTP_VERSION, tostring(status), reason, (headers__3estring(_3fheaders) or ""), (_3fcontent or ""))
  end
  return {["build-http-response"] = build_http_response, ["build-http-request"] = build_http_request, ["headers->string"] = headers__3estring}
end
package.preload["http.body"] = package.preload["http.body"] or function(...)
  local _local_791_ = require("http.builder")
  local headers__3estring = _local_791_["headers->string"]
  local _local_792_ = require("http.readers")
  local reader_3f = _local_792_["reader?"]
  local file_reader = _local_792_["file-reader"]
  local _local_793_ = require("lib.async")
  local chan_3f = _local_793_["chan?"]
  local _local_794_ = require("http.async-extras")
  local _3c_21_3f = _local_794_["<!?"]
  local function get_chunk_data(body)
    if chan_3f(body) then
      return _3c_21_3f(body)
    elseif reader_3f(body) then
      return body:read(1024)
    else
      return error(("unsupported body type: " .. type(body)))
    end
  end
  local function format_chunk(body)
    local data_3f = get_chunk_data(body)
    local data = (data_3f or "")
    return not data_3f, string.format("%x\13\n%s\13\n", #data, data)
  end
  local function stream_chunks(dst, body)
    local last_chunk_3f, data = format_chunk(body)
    dst:write(data)
    if not last_chunk_3f then
      return stream_chunks(dst, body)
    else
      return nil
    end
  end
  local function stream_reader(dst, body, remaining)
    local _797_
    local function _798_()
      if (1024 < remaining) then
        return 1024
      else
        return remaining
      end
    end
    _797_ = body:read(_798_())
    if (nil ~= _797_) then
      local data = _797_
      dst:write(data)
      if (remaining > 0) then
        return stream_reader(dst, body, (remaining - #data))
      else
        return nil
      end
    else
      return nil
    end
  end
  local function stream_channel(dst, body, remaining)
    local _801_ = _3c_21_3f(body)
    if (nil ~= _801_) then
      local data = _801_
      local data0
      if (#data < remaining) then
        data0 = data
      else
        data0 = string.sub(data, 1, remaining)
      end
      local remaining0 = (remaining - #data0)
      dst:write(data0)
      if (remaining0 > 0) then
        return stream_channel(dst, body, remaining0)
      else
        return nil
      end
    else
      return nil
    end
  end
  local function stream_body(dst, body, _805_)
    local transfer_encoding = _805_["transfer-encoding"]
    local content_length = _805_["content-length"]
    if body then
      if (transfer_encoding == "chunked") then
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
    local _810_ = type(body)
    if (_810_ == "table") then
      if chan_3f(body) then
        return body
      elseif reader_3f(body) then
        return body
      else
        return body
      end
    elseif (_810_ == "userdata") then
      local _812_ = getmetatable(body)
      if ((_G.type(_812_) == "table") and (_812_.__name == "FILE*")) then
        return file_reader(body)
      else
        local _ = _812_
        return body
      end
    else
      local _ = _810_
      return body
    end
  end
  local function format_multipart_part(_815_, boundary)
    local name = _815_["name"]
    local part_name = _815_["part-name"]
    local filename = _815_["filename"]
    local content = _815_["content"]
    local content_length = _815_["length"]
    local mime_type = _815_["mime-type"]
    local content0 = wrap_body(content)
    local function _816_()
      if filename then
        return string.format("; filename=%q", filename)
      else
        return ""
      end
    end
    local _817_
    if ("string" == type(content0)) then
      _817_ = #content0
    else
      _817_ = (content_length or content0:length())
    end
    return string.format("--%s\13\n%s\13\n", boundary, headers__3estring({["content-disposition"] = string.format("form-data; name=%q%s", (part_name or name), _816_()), ["content-length"] = _817_, ["content-type"] = (mime_type or guess_content_type(content0)), ["content-transfer-encoding"] = guess_transfer_encoding(content0)}))
  end
  local function multipart_content_length(multipart, boundary)
    local _819_
    do
      local total = 0
      for _, _820_ in ipairs(multipart) do
        local content_length = _820_["length"]
        local name = _820_["name"]
        local part_name = _820_["part-name"]
        local content = _820_["content"]
        local part = _820_
        local content0 = wrap_body(content)
        local _821_
        if ("string" == type(content0)) then
          _821_ = (#content0 + 2)
        elseif reader_3f(content0) then
          _821_ = (2 + (content0:length() or content_length or error(string.format("can't determine length for multipart content %q", (name or part_name)), 2)))
        elseif (nil ~= content_length) then
          _821_ = (content_length + 2)
        else
          _821_ = error(string.format("missing length field on non-string multipart content %q", (name or part_name)), 2)
        end
        total = (total + #format_multipart_part(part, boundary) + _821_)
      end
      _819_ = total
    end
    return (_819_ + #string.format("--%s--\13\n", boundary))
  end
  local function stream_multipart(dst, multipart, boundary)
    for _, _823_ in ipairs(multipart) do
      local name = _823_["name"]
      local part_name = _823_["part-name"]
      local filename = _823_["filename"]
      local content = _823_["content"]
      local content_length = _823_["length"]
      local mime_type = _823_["mime-type"]
      local part = _823_
      assert((nil ~= content), "Multipart content cannot be nil")
      assert((part_name or name), "Multipart body must contain at least content and name or part-name")
      do
        local content0 = wrap_body(content)
        local _824_
        if ("string" == type(content0)) then
          _824_ = content0
        else
          _824_ = ""
        end
        dst:write((format_multipart_part(part, boundary) .. _824_))
        if ("string" ~= type(content0)) then
          stream_body(dst, content0, {["content-length"] = (content_length or content0:length())})
        else
        end
      end
      dst:write("\13\n")
    end
    return dst:write(string.format("--%s--\13\n", boundary))
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
return setmetatable({client = require("http.client"), json = require("http.json"), readers = require("http.readers")}, {__index = setmetatable(require("http.client"), {__index = {__VERSION = "0.0.50"}})})