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
local socket = require("socket")
package.preload["async"] = package.preload["async"] or function(...)
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
    _G.assert((nil ~= h), "Missing argument h on ./async.fnl:335")
    return h["active?"](h)
  end
  local function blockable_3f(h)
    _G.assert((nil ~= h), "Missing argument h on ./async.fnl:336")
    return h["blockable?"](h)
  end
  local function commit(h)
    _G.assert((nil ~= h), "Missing argument h on ./async.fnl:337")
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
    _G.assert((nil ~= item), "Missing argument item on ./async.fnl:376")
    _G.assert((nil ~= buffer), "Missing argument buffer on ./async.fnl:376")
    return buffer["add!"](buffer, item)
  end
  local function close_buf_21(buffer)
    _G.assert((nil ~= buffer), "Missing argument buffer on ./async.fnl:377")
    return buffer["close-buf!"](buffer)
  end
  local function full_3f(buffer)
    _G.assert((nil ~= buffer), "Missing argument buffer on ./async.fnl:374")
    return buffer["full?"](buffer)
  end
  local function remove_21(buffer)
    _G.assert((nil ~= buffer), "Missing argument buffer on ./async.fnl:375")
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
    local _let_289_ = require("async")
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
          local _let_294_ = require("async")
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
        local _let_299_ = require("async")
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
        local _let_302_ = require("async")
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
      local _let_306_ = require("async")
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
    local _let_310_ = require("async")
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
      local _let_322_ = require("async")
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
    local _let_329_ = require("async")
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
    local _let_333_ = require("async")
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
    local _let_336_ = require("async")
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
      local _let_342_ = require("async")
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
      local _let_346_ = require("async")
      local go_1_auto = _let_346_["go"]
      local function _347_()
        local function recur()
          local _348_ = _3c_21(from)
          if (nil ~= _348_) then
            local v = _348_
            local c = chan(1)
            if (kind == "compute") then
              local _let_349_ = require("async")
              local go_1_auto0 = _let_349_["go"]
              local function _350_()
                return process(v, c)
              end
              go_1_auto0(_350_)
            elseif (kind == "async") then
              local _let_351_ = require("async")
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
    _G.assert((nil ~= close_3f), "Missing argument close? on ./async.fnl:1340")
    _G.assert((nil ~= ch), "Missing argument ch on ./async.fnl:1340")
    return _["tap*"](_, ch, close_3f)
  end
  local function untap_2a(_, ch)
    _G.assert((nil ~= ch), "Missing argument ch on ./async.fnl:1341")
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
      local _let_380_ = require("async")
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
    _G.assert((nil ~= ch), "Missing argument ch on ./async.fnl:1404")
    return _["admix*"](_, ch)
  end
  local function solo_mode_2a(_, mode)
    _G.assert((nil ~= mode), "Missing argument mode on ./async.fnl:1408")
    return _["solo-mode*"](_, mode)
  end
  local function toggle_2a(_, state_map)
    _G.assert((nil ~= state_map), "Missing argument state-map on ./async.fnl:1407")
    return _["toggle*"](_, state_map)
  end
  local function unmix_2a(_, ch)
    _G.assert((nil ~= ch), "Missing argument ch on ./async.fnl:1405")
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
      local _let_423_ = require("async")
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
    _G.assert((nil ~= close_3f), "Missing argument close? on ./async.fnl:1509")
    _G.assert((nil ~= ch), "Missing argument ch on ./async.fnl:1509")
    _G.assert((nil ~= v), "Missing argument v on ./async.fnl:1509")
    return _["sub*"](_, v, ch, close_3f)
  end
  local function unsub_2a(_, v, ch)
    _G.assert((nil ~= ch), "Missing argument ch on ./async.fnl:1510")
    _G.assert((nil ~= v), "Missing argument v on ./async.fnl:1510")
    return _["unsub*"](_, v, ch)
  end
  local function unsub_all_2a(_, v)
    _G.assert((nil ~= v), "Missing argument v on ./async.fnl:1511")
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
      local _let_454_ = require("async")
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
      local _let_464_ = require("async")
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
      local _let_472_ = require("async")
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
      local _let_481_ = require("async")
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
  local tcp = {}
  local s_2fselect = (socket and socket.select)
  local s_2fconnect = (socket and socket.connect)
  local function set_chunk_size(self, pattern_or_size)
    self["chunk-size"] = pattern_or_size
    return nil
  end
  local function socket_channel(client, xform, err_handler)
    local recv = chan(1024, xform, err_handler)
    local resp = chan(1024, xform, err_handler)
    local ready = chan()
    local close
    local function _485_(self)
      recv["close!"](recv)
      resp["close!"](resp)
      self.closed = true
      return nil
    end
    close = _485_
    local c
    local function _486_(_, val, handler, enqueue_3f)
      return recv["put!"](recv, val, handler, enqueue_3f)
    end
    local function _487_(_, handler, enqueue_3f)
      offer_21(ready, "ready")
      return resp["take!"](resp, handler, enqueue_3f)
    end
    local function _488_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "SocketChannel:") .. ">")
    end
    c = setmetatable({puts = recv.puts, takes = resp.takes, ["put!"] = _486_, ["take!"] = _487_, ["close!"] = close, close = close, ["chunk-size"] = 1024, ["set-chunk-size"] = set_chunk_size}, {__index = Channel, __name = "SocketChannel", __fennelview = _488_})
    do
      local _let_491_ = require("async")
      local go_1_auto = _let_491_["go"]
      local function _492_()
        local _2_489_ = _3c_21(recv)
        local data = _2_489_
        local _4_490_ = 0
        local i = _4_490_
        local function recur(data0, i0)
          if (nil ~= data0) then
            local _493_, _494_ = s_2fselect(nil, {client}, 0)
            if (true and ((_G.type(_494_) == "table") and (nil ~= _494_[1]))) then
              local _ = _493_
              local s = _494_[1]
              local _495_, _496_, _497_ = s:send(data0, i0)
              if ((_495_ == nil) and (_496_ == "timeout") and (nil ~= _497_)) then
                local j = _497_
                _3c_21(timeout(10))
                return recur(data0, j)
              elseif ((_495_ == nil) and (_496_ == "closed")) then
                s:close()
                return close_21(c)
              else
                local _0 = _495_
                return recur(_3c_21(recv), 0)
              end
            else
              local _ = _493_
              _3c_21(timeout(10))
              return recur(data0, i0)
            end
          else
            return nil
          end
        end
        return recur(_2_489_, _4_490_)
      end
      go_1_auto(_492_)
    end
    do
      local _let_502_ = require("async")
      local go_1_auto = _let_502_["go"]
      local function _503_()
        local _2_501_ = true
        local wait_3f = _2_501_
        local function recur(wait_3f0)
          if wait_3f0 then
            _3c_21(ready)
          else
          end
          local _505_, _506_, _507_ = client:receive(c["chunk-size"])
          if (nil ~= _505_) then
            local data = _505_
            _3e_21(resp, data)
            return recur(true)
          elseif ((_505_ == nil) and (_506_ == "closed") and (_507_ == "")) then
            client:close()
            return close_21(c)
          elseif ((_505_ == nil) and (_506_ == "closed") and (nil ~= _507_)) then
            local data = _507_
            client:close()
            _3e_21(resp, data)
            return close_21(c)
          elseif ((_505_ == nil) and (_506_ == "timeout") and (_507_ == "")) then
            _3c_21(timeout(10))
            return recur(false)
          elseif ((_505_ == nil) and (_506_ == "timeout") and (nil ~= _507_)) then
            local data = _507_
            _3e_21(resp, data)
            _3c_21(timeout(10))
            return recur(true)
          else
            return nil
          end
        end
        return recur(_2_501_)
      end
      go_1_auto(_503_)
    end
    return c
  end
  tcp.chan = function(_509_, xform, err_handler)
    local host = _509_["host"]
    local port = _509_["port"]
    assert(socket, "tcp module requires luasocket")
    local host0 = (host or "localhost")
    local function _510_(...)
      local _511_, _512_ = ...
      if (nil ~= _511_) then
        local client = _511_
        local function _513_(...)
          local _514_, _515_ = ...
          if true then
            local _ = _514_
            return socket_channel(client, xform, err_handler)
          elseif ((_514_ == nil) and (nil ~= _515_)) then
            local err = _515_
            return error(err)
          else
            return nil
          end
        end
        return _513_(client:settimeout(0))
      elseif ((_511_ == nil) and (nil ~= _512_)) then
        local err = _512_
        return error(err)
      else
        return nil
      end
    end
    return _510_(s_2fconnect(host0, port))
  end
  return {buffer = buffer, ["dropping-buffer"] = dropping_buffer, ["sliding-buffer"] = sliding_buffer, ["promise-buffer"] = promise_buffer, ["unblocking-buffer?"] = unblocking_buffer_3f, chan = chan, ["chan?"] = chan_3f, ["promise-chan"] = promise_chan, ["take!"] = take_21, ["<!!"] = _3c_21_21, ["<!"] = _3c_21, timeout = timeout, ["put!"] = put_21, [">!!"] = _3e_21_21, [">!"] = _3e_21, ["close!"] = close_21, go = go_2a, ["alts!"] = alts_21, ["offer!"] = offer_21, ["poll!"] = poll_21, pipe = pipe, ["pipeline-async"] = pipeline_async, pipeline = pipeline, ["pipeline-async-unordered"] = pipeline_async_unordered, ["pipeline-unordered"] = pipeline_unordered, reduce = reduce, reduced = reduced, ["reduced?"] = reduced_3f, transduce = transduce, split = split, ["onto-chan!"] = onto_chan_21, ["to-chan!"] = to_chan_21, mult = mult, tap = tap, untap = untap, ["untap-all"] = untap_all, mix = mix, admix = admix, unmix = unmix, ["unmix-all"] = unmix_all, toggle = toggle, ["solo-mode"] = solo_mode, pub = pub, sub = sub, unsub = unsub, ["unsub-all"] = unsub_all, map = map, merge = merge, into = into, take = take, buffers = {FixedBuffer = FixedBuffer, SlidingBuffer = SlidingBuffer, DroppingBuffer = DroppingBuffer, PromiseBuffer = PromiseBuffer}, tcp = tcp}
end
local _local_518_ = require("async")
local _3c_21 = _local_518_["<!"]
local _3e_21 = _local_518_[">!"]
local _3c_21_21 = _local_518_["<!!"]
local _3e_21_21 = _local_518_[">!!"]
local close_21 = _local_518_["close!"]
local chan = _local_518_["chan"]
local promise_chan = _local_518_["promise-chan"]
local chan_3f = _local_518_["chan?"]
local tcp = _local_518_["tcp"]
local http_parser
package.preload["http-parser"] = package.preload["http-parser"] or function(...)
  local _local_563_ = require("readers")
  local make_reader = _local_563_["make-reader"]
  local reader = _local_563_
  local json = require("json")
  local utils = require("utils")
  local function parse_header(line)
    local _634_, _635_ = line:match(" *([^:]+) *: *(.*)")
    if ((nil ~= _634_) and (nil ~= _635_)) then
      local header = _634_
      local value = _635_
      return header, value
    else
      return nil
    end
  end
  local function read_headers(src, read_fn, _3fheaders)
    local headers = (_3fheaders or {})
    local line = read_fn(src, "*l")
    if ((line == "\13") or (line == "")) then
      return headers
    else
      local _ = line
      local function _639_()
        local _637_, _638_ = parse_header((line or ""))
        if ((nil ~= _637_) and (nil ~= _638_)) then
          local header = _637_
          local value = _638_
          headers[header] = value
          return headers
        else
          return nil
        end
      end
      return read_headers(src, read_fn, _639_())
    end
  end
  local function parse_response_status_line(status)
    local function loop(reader0, fields, res)
      if ((_G.type(fields) == "table") and (nil ~= fields[1])) then
        local field = fields[1]
        local fields0 = {select(2, (table.unpack or _G.unpack)(fields))}
        local part = reader0()
        local function _642_()
          if (field == "protocol-version") then
            local name, major, minor = part:match("([^/]+)/(%d).(%d)")
            res[field] = {name = name, major = tonumber(major), minor = tonumber(minor)}
            return res
          else
            local _ = field
            res[field] = utils["as-data"](part)
            return res
          end
        end
        return loop(reader0, fields0, _642_())
      else
        local _ = fields
        local reason = status:gsub(string.format("%s/%s.%s +%s +", res["protocol-version"].name, res["protocol-version"].major, res["protocol-version"].minor, res.status), "")
        res["reason-phrase"] = reason
        return res
      end
    end
    return loop(status:gmatch("([^ ]+)"), {"protocol-version", "status"}, {})
  end
  local function read_response_status_line(src, read_fn)
    return parse_response_status_line(read_fn(src, "*l"))
  end
  local function body_reader(src, read_fn)
    local buffer = ""
    local function _644_(src0, pattern)
      local rdr = reader["string-reader"](buffer)
      local buffer_content = rdr:read(pattern)
      local and_645_ = (nil ~= pattern)
      if and_645_ then
        local n = pattern
        and_645_ = ("number" == type(n))
      end
      if and_645_ then
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
            return (buffer_content .. (read_fn(src0, (n - len)) or ""))
          else
            return read_fn(src0, (n - len))
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
            return (buffer_content .. (read_fn(src0, pattern) or ""))
          else
            return read_fn(src0, pattern)
          end
        else
          return buffer_content
        end
      elseif ((pattern == "*a") or (pattern == "a")) then
        buffer = ""
        local _653_ = read_fn(src0, pattern)
        if (_653_ == nil) then
          if buffer_content then
            return buffer_content
          else
            return nil
          end
        elseif (nil ~= _653_) then
          local data = _653_
          return ((buffer_content or "") .. data)
        else
          return nil
        end
      else
        local _ = pattern
        return error(tostring(pattern))
      end
    end
    local function _657_(src0)
      local rdr = reader["string-reader"](buffer)
      local buffer_content = rdr:read("*l")
      local read_more_3f = not buffer:find("\n")
      if buffer_content then
        buffer = string.sub(buffer, (#buffer_content + 2))
      else
      end
      if read_more_3f then
        if buffer_content then
          return (buffer_content .. (read_fn(src0, "*l") or ""))
        else
          return read_fn(src0, "*l")
        end
      else
        return buffer_content
      end
    end
    local function _661_(src0)
      return src0:close()
    end
    local function _662_(src0, bytes)
      assert(("number" == type(bytes)), "expected number of bytes to peek")
      local rdr = reader["string-reader"](buffer)
      local content = (rdr:read(bytes) or "")
      local len = #content
      if (bytes == len) then
        return content
      else
        local data = read_fn(src0, (bytes - len))
        buffer = (buffer .. (data or ""))
        return buffer
      end
    end
    return make_reader(src, {["read-bytes"] = _644_, ["read-line"] = _657_, close = _661_, peek = _662_})
  end
  local function parse_http_response(src, read_fn, _664_)
    local as = _664_["as"]
    local parse_headers_3f = _664_["parse-headers?"]
    local start = _664_["start"]
    local time = _664_["time"]
    local status = read_response_status_line(src, read_fn)
    local headers = read_headers(src, read_fn)
    local parsed_headers
    do
      local tbl_16_auto = {}
      for k, v in pairs(headers) do
        local k_17_auto, v_18_auto = utils["capitalize-header"](k), utils["as-data"](v)
        if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
          tbl_16_auto[k_17_auto] = v_18_auto
        else
        end
      end
      parsed_headers = tbl_16_auto
    end
    local stream = body_reader(src, read_fn)
    local _666_
    if parse_headers_3f then
      _666_ = parsed_headers
    else
      _666_ = headers
    end
    status["headers"] = _666_
    status["length"] = tonumber(parsed_headers["Content-Length"])
    local _668_
    if (start and time) then
      _668_ = math.ceil((1000 * (time() - start)))
    else
      _668_ = nil
    end
    status["request-time"] = _668_
    local _670_
    if (as == "raw") then
      _670_ = stream:read((parsed_headers["Content-Length"] or "*a"))
    elseif (as == "json") then
      _670_ = json.parse(stream)
    elseif (as == "stream") then
      _670_ = stream
    else
      local _ = as
      _670_ = error(string.format("unsupported coersion method '%s'", as))
    end
    status["body"] = _670_
    return status
  end
  --[[ (let [req (build-http-response 200 "OK" {:connection "close"} "vaiv
  daun
  ") rdr (reader.string-reader req) {:body body :headers headers :reason-phrase reason-phrase :status status} (parse-http-response rdr (fn [src pattern] (src:read pattern)) {:as "raw"})] (= req (build-http-response status reason-phrase headers body))) ]]
  local function parse_request_status_line(status)
    local function loop(reader0, fields, res)
      if ((_G.type(fields) == "table") and (nil ~= fields[1])) then
        local field = fields[1]
        local fields0 = {select(2, (table.unpack or _G.unpack)(fields))}
        local part = reader0()
        local function _676_()
          res[field] = utils["as-data"](part)
          return res
        end
        return loop(reader0, fields0, _676_())
      else
        local _ = fields
        return res
      end
    end
    return loop(status:gmatch("([^ ]+)"), {"method", "path", "http-version"}, {})
  end
  local function read_request_status_line(src, read_fn)
    return parse_request_status_line(read_fn(src, "*l"))
  end
  local function parse_http_request(src, read_fn)
    local status = read_request_status_line(src, read_fn)
    local headers = read_headers(src, read_fn)
    status["headers"] = headers
    status["content"] = read_fn(src, "*a")
    return status
  end
  --[[ (let [req (build-http-request "get" "/" {:connection "close"} "vaiv
  daun
  ") rdr (reader.string-reader req) {:content content :headers headers :method method :path path} (parse-http-request rdr (fn [src pattern] (src:read pattern)) rdr)] (= req (build-http-request method path headers content))) ]]
  local function parse_authority(authority)
    local userinfo = authority:match("([^@]+)@")
    local port = authority:match(":(%d+)")
    local host
    if userinfo then
      local _678_
      if port then
        _678_ = ":"
      else
        _678_ = ""
      end
      host = authority:match(("@([^:]+)" .. _678_))
    else
      local _680_
      if port then
        _680_ = ":"
      else
        _680_ = ""
      end
      host = authority:match(("([^:]+)" .. _680_))
    end
    return {userinfo = userinfo, port = port, host = host}
  end
  local function parse_url(url)
    local scheme = url:match("^([^:]+)://")
    local function _683_()
      if scheme then
        return url:match("//([^/]+)/")
      else
        return url:match("^([^/]+)/")
      end
    end
    local _let_684_ = parse_authority(_683_())
    local host = _let_684_["host"]
    local port = _let_684_["port"]
    local userinfo = _let_684_["userinfo"]
    local scheme0 = (scheme or "http")
    local port0
    local or_685_ = port
    if not or_685_ then
      if (scheme0 == "https") then
        or_685_ = 443
      elseif (scheme0 == "http") then
        or_685_ = 80
      else
        or_685_ = nil
      end
    end
    port0 = or_685_
    local path = url:match("//[^/]+/([^?#]+)")
    local query = url:match("%?([^#]+)#?")
    local fragment = url:match("#([^?]+)%??")
    return {scheme = scheme0, host = host, port = port0, userinfo = userinfo, path = path, query = query, fragment = fragment}
  end
  return {["parse-http-response"] = parse_http_response, ["parse-http-request"] = parse_http_request, ["parse-url"] = parse_url}
end
package.preload["readers"] = package.preload["readers"] or function(...)
  local function ok_3f(ok_3f0, ...)
    if ok_3f0 then
      return ...
    else
      return nil
    end
  end
  local function make_reader(source, _520_)
    local read_bytes = _520_["read-bytes"]
    local read_line = _520_["read-line"]
    local close = _520_["close"]
    local peek = _520_["peek"]
    local close0
    if close then
      local function _521_(_, ...)
        return ok_3f(pcall(close, source, ...))
      end
      close0 = _521_
    else
      local function _522_()
        return nil
      end
      close0 = _522_
    end
    local _524_
    if read_bytes then
      local function _525_(_, pattern, ...)
        return ok_3f(pcall(read_bytes, source, pattern, ...))
      end
      _524_ = _525_
    else
      local function _526_()
        return nil
      end
      _524_ = _526_
    end
    local _528_
    if read_line then
      local function _529_()
        local function _530_(_, ...)
          return ok_3f(pcall(read_line, source, ...))
        end
        return _530_
      end
      _528_ = _529_
    else
      local function _531_()
        local function _532_()
          return nil
        end
        return _532_
      end
      _528_ = _531_
    end
    local _534_
    if peek then
      local function _535_(_, pattern, ...)
        return ok_3f(pcall(peek, source, pattern, ...))
      end
      _534_ = _535_
    else
      local function _536_()
        return nil
      end
      _534_ = _536_
    end
    local function _538_(_241)
      return ("#<" .. tostring(_241):gsub("table:", "Reader:") .. ">")
    end
    return setmetatable({close = close0, read = _524_, lines = _528_, peek = _534_}, {__close = close0, __name = "Reader", __fennelview = _538_})
  end
  local function file_reader(file)
    local file0
    do
      local _539_ = type(file)
      if (_539_ == "string") then
        file0 = io.open(file, "r")
      else
        local _ = _539_
        file0 = file
      end
    end
    local function _541_(_241)
      return _241:close()
    end
    local function _542_(f, pattern)
      return f:read(pattern)
    end
    local function _543_(f, pattern)
      assert(("number" == type(pattern)), "expected number of bytes to peek")
      local res = f:read(pattern)
      f:seek("cur", ( - pattern))
      return res
    end
    return make_reader(file0, {close = _541_, ["read-bytes"] = _542_, ["read-line"] = file0:lines(), peek = _543_})
  end
  local function string_reader(string)
    local i, closed = 1, false
    local len = #string
    local try_read_line
    local function _544_(s, pattern)
      local _545_, _546_, _547_ = s:find(pattern, i)
      if ((nil ~= _545_) and (nil ~= _546_) and (nil ~= _547_)) then
        local start = _545_
        local _end = _546_
        local s0 = _547_
        i = (_end + 1)
        return s0
      else
        return nil
      end
    end
    try_read_line = _544_
    local read_line
    local function _549_(s)
      if (i <= len) then
        return (try_read_line(s, "(.-)\13?\n") or try_read_line(s, "(.-)\13?$"))
      else
        return nil
      end
    end
    read_line = _549_
    local function _551_(_)
      if not closed then
        i = (len + 1)
        closed = true
        return closed
      else
        return nil
      end
    end
    local function _553_(s, pattern)
      if (i <= len) then
        if ((pattern == "*l") or (pattern == "l")) then
          return read_line(s)
        elseif ((pattern == "*a") or (pattern == "a")) then
          return s:sub(i)
        else
          local and_554_ = (nil ~= pattern)
          if and_554_ then
            local bytes = pattern
            and_554_ = ("number" == type(bytes))
          end
          if and_554_ then
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
    local function _558_(s, pattern)
      if (i <= len) then
        local and_559_ = (nil ~= pattern)
        if and_559_ then
          local bytes = pattern
          and_559_ = ("number" == type(bytes))
        end
        if and_559_ then
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
    return make_reader(string, {close = _551_, ["read-bytes"] = _553_, ["read-line"] = read_line, peek = _558_})
  end
  return {["make-reader"] = make_reader, ["file-reader"] = file_reader, ["string-reader"] = string_reader}
end
package.preload["json"] = package.preload["json"] or function(...)
  local reader = require("readers")
  local null = "null"
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
    local and_564_ = object_3f(val)
    if and_564_ then
      local _565_ = #val
      if (_565_ == 0) then
        and_564_ = false
      elseif (nil ~= _565_) then
        local len = _565_
        local max = (_3fmax or len)
        local _570_ = next(val, max)
        local and_572_ = (nil ~= _570_)
        if and_572_ then
          local k = _570_
          and_572_ = ("number" == type(k))
        end
        if and_572_ then
          local k = _570_
          and_564_ = array_3f(val, k)
        elseif (_570_ == nil) then
          and_564_ = {n = max, array = val}
        else
          local _ = _570_
          and_564_ = false
        end
      else
        and_564_ = nil
      end
    end
    return and_564_
  end
  local function function_3f(val)
    return (("function" == type(val)) and {["function"] = val})
  end
  local function guess(val)
    return (array_3f(val) or object_3f(val) or string_3f(val) or number_3f(val) or val)
  end
  local function escape_string(str)
    local escs
    local function _579_(_241, _242)
      return ("\\%03d"):format(_242:byte())
    end
    escs = setmetatable({["\7"] = "\\a", ["\8"] = "\\b", ["\12"] = "\\f", ["\11"] = "\\v", ["\13"] = "\\r", ["\t"] = "\\t", ["\\"] = "\\\\", ["\""] = "\\\"", ["\n"] = "\\n"}, {__index = _579_})
    return ("\"" .. str:gsub("[%c\\\"]", escs) .. "\"")
  end
  local function json(val)
    local _580_ = guess(val)
    if ((_G.type(_580_) == "table") and (nil ~= _580_.array) and (nil ~= _580_.n)) then
      local array = _580_.array
      local n = _580_.n
      local _581_
      do
        local tbl_21_auto = {}
        local i_22_auto = 0
        for i = 1, n do
          local val_23_auto = json(array[i])
          if (nil ~= val_23_auto) then
            i_22_auto = (i_22_auto + 1)
            tbl_21_auto[i_22_auto] = val_23_auto
          else
          end
        end
        _581_ = tbl_21_auto
      end
      return ("[" .. table.concat(_581_, ", ") .. "]")
    elseif ((_G.type(_580_) == "table") and (nil ~= _580_.object)) then
      local object = _580_.object
      local _583_
      do
        local tbl_21_auto = {}
        local i_22_auto = 0
        for k, v in pairs(object) do
          local val_23_auto = (json(k) .. ": " .. json(v))
          if (nil ~= val_23_auto) then
            i_22_auto = (i_22_auto + 1)
            tbl_21_auto[i_22_auto] = val_23_auto
          else
          end
        end
        _583_ = tbl_21_auto
      end
      return ("{" .. table.concat(_583_, ", ") .. "}")
    elseif ((_G.type(_580_) == "table") and (nil ~= _580_.string)) then
      local s = _580_.string
      return escape_string(s)
    elseif ((_G.type(_580_) == "table") and (nil ~= _580_.number)) then
      local n = _580_.number
      return string.gsub(tostring(n), ",", ".")
    elseif (_580_ == nil) then
      return null
    else
      local _ = _580_
      return escape_string(tostring(val))
    end
  end
  local function skip_space(rdr)
    local function loop()
      local _586_ = rdr:peek(1)
      local and_587_ = (nil ~= _586_)
      if and_587_ then
        local c = _586_
        and_587_ = c:match("[ \t\n]")
      end
      if and_587_ then
        local c = _586_
        return loop(rdr:read(1))
      else
        return nil
      end
    end
    return loop()
  end
  local function parse_num(rdr)
    local function loop(numbers)
      local _590_ = rdr:peek(1)
      local and_591_ = (nil ~= _590_)
      if and_591_ then
        local n = _590_
        and_591_ = n:match("[-0-9.eE+]")
      end
      if and_591_ then
        local n = _590_
        rdr:read(1)
        return loop((numbers .. n))
      else
        local _ = _590_
        return tonumber(numbers)
      end
    end
    return loop(rdr:read(1))
  end
  local function parse_string(rdr)
    rdr:read(1)
    local function loop(chars, escaped_3f)
      local _594_ = rdr:read(1)
      if (_594_ == "\\") then
        return loop(chars, not escaped_3f)
      elseif (_594_ == "\"") then
        if escaped_3f then
          return loop((chars .. "\""), false)
        else
          return chars
        end
      else
        local _ = _594_
        return loop((chars .. _), false)
      end
    end
    return loop("", false)
  end
  local function parse_obj(rdr, parse)
    rdr:read(1)
    local function loop(obj)
      skip_space(rdr)
      local _597_ = rdr:peek(1)
      if (_597_ == "}") then
        rdr:read(1)
        return obj
      else
        local _ = _597_
        local key = parse()
        skip_space(rdr)
        local _598_ = rdr:peek(1)
        if (_598_ == ":") then
          local _0 = rdr:read(1)
          local value = parse()
          obj[key] = value
          skip_space(rdr)
          local _599_ = rdr:peek(1)
          if (_599_ == ",") then
            rdr:read(1)
            return loop(obj)
          elseif (_599_ == "}") then
            rdr:read(1)
            return obj
          else
            local _1 = _599_
            return error(("JSON parse error: expected ',' or '}' after the value: " .. json(value)))
          end
        else
          local _0 = _598_
          return error(("JSON parse error: expected colon after the key: " .. json(key)))
        end
      end
    end
    return loop({})
  end
  local function parse_arr(rdr, parse)
    rdr:read(1)
    local function loop(arr)
      skip_space(rdr)
      local _603_ = rdr:peek(1)
      if (_603_ == "]") then
        rdr:read(1)
        return arr
      else
        local _ = _603_
        local val = parse()
        arr[(1 + #arr)] = val
        skip_space(rdr)
        local _604_ = rdr:peek(1)
        if (_604_ == ",") then
          rdr:read(1)
          return loop(arr)
        elseif (_604_ == "]") then
          rdr:read(1)
          return arr
        else
          local _0 = _604_
          return error(("JSON parse error: expected ',' or ']' after the value: " .. json(val)))
        end
      end
    end
    return loop({})
  end
  local function parse(rdr)
    local function loop()
      local _607_ = rdr:peek(1)
      if (_607_ == "{") then
        return parse_obj(rdr, loop)
      elseif (_607_ == "[") then
        return parse_arr(rdr, loop)
      elseif (_607_ == "\"") then
        return parse_string(rdr)
      else
        local and_608_ = (_607_ == "t")
        if and_608_ then
          and_608_ = ("true" == rdr:peek(4))
        end
        if and_608_ then
          rdr:read(4)
          return true
        else
          local and_610_ = (_607_ == "f")
          if and_610_ then
            and_610_ = ("false" == rdr:peek(5))
          end
          if and_610_ then
            rdr:read(5)
            return false
          else
            local and_612_ = (_607_ == "n")
            if and_612_ then
              and_612_ = ("null" == rdr:peek(4))
            end
            if and_612_ then
              rdr:read(4)
              return nil
            else
              local and_614_ = (nil ~= _607_)
              if and_614_ then
                local c = _607_
                and_614_ = c:match("[ \t\n]")
              end
              if and_614_ then
                local c = _607_
                return loop(skip_space(rdr))
              else
                local and_616_ = (nil ~= _607_)
                if and_616_ then
                  local n = _607_
                  and_616_ = n:match("[-0-9]")
                end
                if and_616_ then
                  local n = _607_
                  return parse_num(rdr)
                elseif (_607_ == nil) then
                  return error("JSON parse error: end of stream")
                else
                  local _ = _607_
                  return error(string.format("JSON parse error: unexpected token ('%s' (code %d))", _, _:byte()))
                end
              end
            end
          end
        end
      end
    end
    return loop()
  end
  return {json = json, parse = parse}
end
package.preload["utils"] = package.preload["utils"] or function(...)
  local function __3ekebab_case(str)
    local function _619_()
      local res,case_change_3f = "", false
      for c in string.gmatch(str, ".") do
        local function _620_()
          local delim_3f = c:match("[-_ ]")
          local upper_3f = (c == c:upper())
          if delim_3f then
            return {(res .. "-"), nil}
          elseif (upper_3f and case_change_3f) then
            return {(res .. "-" .. c:lower()), nil}
          else
            return {(res .. c), true}
          end
        end
        local _set_622_ = _620_()
        res = _set_622_[1]
        case_change_3f = _set_622_[2]
      end
      return {res, case_change_3f}
    end
    local _let_623_ = _619_()
    local res = _let_623_[1]
    return res
  end
  local function capitalize_header(header)
    local header0 = __3ekebab_case(header)
    local _624_
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
      _624_ = tbl_21_auto
    end
    return table.concat(_624_, "-")
  end
  local function as_data(value)
    local _626_ = tonumber(value)
    if (nil ~= _626_) then
      local n = _626_
      return n
    else
      local _ = _626_
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
  local function format_path(_629_)
    local path = _629_["path"]
    local query = _629_["query"]
    local fragment = _629_["fragment"]
    local _630_
    if query then
      _630_ = ("?" .. query)
    else
      _630_ = ""
    end
    local _632_
    if fragment then
      _632_ = ("?" .. fragment)
    else
      _632_ = ""
    end
    return ("/" .. (path or "") .. _630_ .. _632_)
  end
  return {["format-path"] = format_path, ["as-data"] = as_data, ["capitalize-header"] = capitalize_header}
end
http_parser = require("http-parser")
local utils = require("utils")
local function header__3estring(header, value)
  return (utils["capitalize-header"](header) .. ": " .. tostring(value) .. "\13\n")
end
local function headers__3estring(headers)
  if (headers and next(headers)) then
    local function _689_()
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
      return tbl_21_auto
    end
    return table.concat(_689_())
  else
    return nil
  end
end
local function make_read_fn(receive)
  local function _692_(src, pattern)
    src["set-chunk-size"](src, pattern)
    return receive(src)
  end
  return _692_
end
local HTTP_VERSION = "HTTP/1.1"
local function build_http_request(method, request_target, _3fheaders, _3fcontent)
  return string.format("%s %s %s\13\n%s\13\n%s", string.upper(method), request_target, HTTP_VERSION, (headers__3estring(_3fheaders) or ""), (_3fcontent or ""))
end
local function build_http_response(status, reason, _3fheaders, _3fcontent)
  return string.format("%s %s %s\13\n%s\13\n%s", HTTP_VERSION, tostring(status), reason, (headers__3estring(_3fheaders) or ""), (_3fcontent or ""))
end
local http = setmetatable({}, {__index = {version = "0.0.1"}})
http.request = function(method, url, _3fopts)
  local _let_693_ = http_parser["parse-url"](url)
  local host = _let_693_["host"]
  local port = _let_693_["port"]
  local parsed = _let_693_
  local opts
  do
    local tbl_16_auto = {as = "raw", ["async?"] = false}
    for k, v in pairs((_3fopts or {})) do
      local k_17_auto, v_18_auto = k, v
      if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
        tbl_16_auto[k_17_auto] = v_18_auto
      else
      end
    end
    opts = tbl_16_auto
  end
  local headers
  do
    local tbl_16_auto
    local _695_
    if port then
      _695_ = (":" .. port)
    else
      _695_ = ""
    end
    local _698_
    do
      local _697_ = opts.body
      local and_699_ = (nil ~= _697_)
      if and_699_ then
        local body = _697_
        and_699_ = ("string" == type(body))
      end
      if and_699_ then
        local body = _697_
        _698_ = #body
      else
        _698_ = nil
      end
    end
    tbl_16_auto = {host = (host .. _695_), ["content-length"] = _698_}
    for k, v in pairs((opts.headers or {})) do
      local k_17_auto, v_18_auto = k, v
      if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
        tbl_16_auto[k_17_auto] = v_18_auto
      else
      end
    end
    headers = tbl_16_auto
  end
  local path = utils["format-path"](parsed)
  local req = build_http_request(method, path, headers, opts.body)
  local chan0 = tcp.chan(parsed)
  do
    opts["start"] = socket.gettime()
    opts["time"] = socket.gettime
  end
  if opts["async?"] then
    local res = promise_chan()
    do
      local _let_704_ = require("async")
      local go_1_auto = _let_704_["go"]
      local function _705_()
        _3e_21(chan0, req)
        return _3e_21(res, http_parser["parse-http-response"](chan0, make_read_fn(_3c_21), opts))
      end
      go_1_auto(_705_)
    end
    return res
  else
    _3e_21_21(chan0, req)
    return http_parser["parse-http-response"](chan0, make_read_fn(_3c_21_21), opts)
  end
end
http.get = function(url_2_auto, opts_3_auto)
  return http.request("get", url_2_auto, opts_3_auto)
end
http.post = function(url_2_auto, opts_3_auto)
  return http.request("post", url_2_auto, opts_3_auto)
end
http.put = function(url_2_auto, opts_3_auto)
  return http.request("put", url_2_auto, opts_3_auto)
end
http.patch = function(url_2_auto, opts_3_auto)
  return http.request("patch", url_2_auto, opts_3_auto)
end
http.options = function(url_2_auto, opts_3_auto)
  return http.request("options", url_2_auto, opts_3_auto)
end
http.trace = function(url_2_auto, opts_3_auto)
  return http.request("trace", url_2_auto, opts_3_auto)
end
http.head = function(url_2_auto, opts_3_auto)
  return http.request("head", url_2_auto, opts_3_auto)
end
http.delete = function(url_2_auto, opts_3_auto)
  return http.request("delete", url_2_auto, opts_3_auto)
end
http.connect = function(url_2_auto, opts_3_auto)
  return http.request("connect", url_2_auto, opts_3_auto)
end
return http
