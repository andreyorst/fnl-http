(comment
 "Copyright (c) 2023 Andrey Listopadov and contributors.  All rights reserved.
The use and distribution terms for this software are covered by the Eclipse
Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php) which
can be found in the file LICENSE at the root of this distribution.  By using
this software in any fashion, you are agreeing to be bound by the terms of
this license.
You must not remove this notice, or any other, from this software.")

(local lib-name
  (or ... :async))

(local main-thread
  (or (coroutine.running)
      (error (.. lib-name " requires Lua 5.2 or higher"))))

;;; Helpers

(set package.preload.reduced
  (or package.preload.reduced
      ;; https://gitlab.com/andreyorst/reduced.lua
      #(let [Reduced
             {:__fennelview
              (fn [[x] view options indent]
                (.. "#<reduced: " (view x options (+ 11 indent)) ">"))
              :__index {:unbox (fn [[x]] x)}
              :__name :reduced
              :__tostring (fn [[x]] (.. "reduced: " (tostring x)))}]
         (fn reduced [value]
           "Wrap `value` as an instance of the Reduced object.
Reduced will terminate the `reduce` function, if it supports this kind
of termination."
           (setmetatable [value] Reduced))
         (fn reduced? [value]
           "Check if `value` is an instance of Reduced."
           (rawequal (getmetatable value) Reduced))
         {:is_reduced reduced? : reduced :reduced? reduced?})))

(local {: reduced : reduced?}
  (require :reduced))

(local (gethook sethook)
  (case _G.debug
    {: gethook : sethook} (values gethook sethook)
    _ (do (io.stderr:write
           "WARNING: debug library is unawailable.  "
           lib-name " uses debug.sethook to advance timers.  "
           "Time-related features are disabled.\n")
          nil)))

(local {:remove t/remove
        :concat t/concat
        :insert t/insert
        :sort t/sort}
  table)

(local t/unpack
  (or _G.unpack table.unpack))

(local {:running c/running
        :resume c/resume
        :yield c/yield
        :create c/create}
  coroutine)

(local {:min m/min
        :random m/random
        :ceil m/ceil
        :floor m/floor
        :modf m/modf}
  math)

(fn main-thread? []
  "Check if current thread is a main one and not a coroutine."
  {:private true}
  (case (c/running)
    nil true
    (_ true) true
    _ false))

(macro defprotocol [name ...]
  "A protocol is a named set of named methods and their signatures:

```fennel
(defprotocol AProtocolName
  ;; method signatures
  (bar [self a b] \"bar docs\")
  (baz [self a] \"baz docs\"))
```

No implementations are provided. Docs can be specified for each
method. The above yields a set of polymorphic functions and a protocol
object.
The resulting functions dispatch on the type of their first argument,
which is required and corresponds to the implicit target object
('self' in Lua parlance). `defprotocol` is dynamic, has no special
compile-time effect, and defines no new types or
classes. Implementations of the protocol methods can be provided using
`reify`:

```fennel
(defprotocol P
  (foo [self]))

(foo
  (let [x 42]
    (reify P
      (foo [this] x))))
;; => 42
```"
  `(local ,(faccumulate [names {'&as name} i 1 (select :# ...)]
             (let [method (select i ...)]
               (assert-compile (list? method) "expected method declaration")
               (let [[name] method]
                 (assert-compile (sym? name) "expected named method" name)
                 (doto names
                   (tset (tostring name) name)))))
          ,(faccumulate [methods {} i 1 (select :# ...)]
             (let [method (select i ...)
                   [name arglist body] method]
               (assert-compile (sequence? arglist) (.. "expected arglist for method " (tostring name)) arglist)
               (assert-compile (or (= :string (type body)) (= nil body)) (.. "expected no body for method " (tostring name)) body)
               (doto methods
                 (tset (tostring name)
                       `(lambda ,name ,arglist
                          ,body
                          (: ,(. arglist 1) ,(tostring name) ,(unpack arglist 2)))))))))

(macro reify [...]
  "Creates an object implementing a protocol.  `reify` is a macro with
the following structure:

```
(reify options* specs*)
```

Currently there are no options.

Each spec consists of the protocol name followed by one or more
method bodies:

```
protocol-name
(methodName [args+] body)*
```

Methods should be supplied for all methods of the desired
protocol(s). Note that the first parameter must be supplied to
correspond to the target object ('self' in Lua parlance). Thus
methods for interfaces will take one more argument than do the
interface declarations."
  (let [index (gensym)
        protocols []
        actions '(do)]
    (var current nil)
    ((fn loop [x ...]
       (assert-compile (or (sym? x) (list? x)) "expected symbol or fnspec" x)
       (if (sym? x)
           (do (set current x)
               (table.insert protocols (tostring x)))
           (list? x)
           (let [[name & [arglist &as fnspec]] x]
             (assert-compile (sym? name) "expected method name" name)
             (assert-compile (sequence? arglist) "expected method arglist" arglist)
             (table.insert
              actions
              `(case (. ,current ,(tostring name))
                 f# (tset ,index ,(tostring name) (fn ,(unpack fnspec)))
                 ,(sym :_) (error ,(.. "Protocol " (tostring current) " doesn't define method " (tostring name)))))))
       (when (not= 0 (select :# ...))
         (loop ...)))
     ...)
    `(let [,index {}]
       ,actions
       (setmetatable
        {}
        {:__index ,index
         :name "reify"
         :__fennelview
         #(.. "#<" (: (tostring $) :gsub "table:" "reify:")
              ": " ,(table.concat protocols ", ") ">")}))))

(fn merge* [t1 t2]
  "Returns a new table containing items from `t1` and `t2`, overriding
values from `t1` if same keys are present."
  {:private true}
  (let [res {}]
    (collect [k v (pairs t1) :into res] k v)
    (collect [k v (pairs t2) :into res] k v)))

(fn merge-with [f t1 t2]
  "Returns a new table containing items from `t1` and `t2`, if same keys
are present merge is done by calling `f` with both values."
  {:private true}
  (let [res (collect [k v (pairs t1)] k v)]
    (collect [k v (pairs t2) :into res]
      (case (. res k)
	e (values k (f e v))
	nil (values k v)))))

;;; Macros

(eval-compiler
  (local lib-name
    (or ... :async))

  (fn go [...]
    "Asynchronously executes the `body`, returning immediately to the
calling thread. Additionally, any visible calls to `<!`, `>!` and
`alts!`  channel operations within the `body` will block (if
necessary) by 'parking' the calling thread rather than tying up the
only Lua thread.  Upon completion of the operation, the `body` will be
resumed.  Returns a channel which will receive the result of the `body`
when completed."
    {:fnl/arglist [& body]}
    `(let [{:go go#} (require ,lib-name)]
       (go# #(do ,...))))

  (fn go-loop [binding-vec ...]
    "Asyncrhonous loop macro.

Similar to `let`, but binds a special `recur` call that will reassign
the values of the `bindings` and restart the loop `body` when called
in tail position.  Unlike `let`, doesn't support multiple-value
destructuring specifically."
    {:fnl/arglist [binding-vec body*]}
    (let [recur (sym :recur)
          keys []
          gensyms []
          bindings []]
      (each [i v (ipairs binding-vec)]
        (when (= 0 (% i 2))
          (let [key (. binding-vec (- i 1))
                gs (gensym (tostring i))]
            (assert-compile (not (list? key)) "loop macro doesn't support multiple-value destructuring" key)
            ;; [sym1# sym2# etc...], for the function application below
            (table.insert gensyms gs)

            ;; let bindings
            (table.insert bindings gs)  ;; sym1#
            (table.insert bindings v)   ;; (expression)
            (table.insert bindings key) ;; [first & rest]
            (table.insert bindings gs)  ;; sym1#

            ;; The gensyms we use for function application
            (table.insert keys key))))
      `(go (let ,bindings
             ((fn ,recur ,keys
                ,...)
              ,(unpack gensyms))))))

  (fn alt! [...]
    "Makes a single choice between one of several channel operations, as if
by `alts!`, returning the value of the result expr corresponding to
the operation completed.  Must be called inside a `(go ...)` block.

Each clause takes the form of:

    channel-op[s] result-expr

where `channel-op` is one of:

- take-port - a single port to take
- [take-port | [put-port put-val] ...] - a vector of ports as per alts!
- :default | :priority - an option for alts!

and `result-expr` is either a list beginning with a vector, whereupon
that vector will be treated as a binding for the `[val port]` return
of the operation, else any other expression.

```fennel
(alt!
  [c t] ([val ch] (foo ch val))
  x ([v] v)
  [[out val]] :wrote
  :default 42)
```

Each option may appear at most once.  The choice and parking
characteristics are those of `alts!`."
    {:fnl/arglist [& clauses]}
    (let [opts {:n 0}
          branches []
          ports []
          gensyms []
          val (gensym :?val)
          res (gensym :res)
          ignore (gensym :_)]
      (for [i 1 (select :# ...) 2]
        (let [(a b) (select i ...)]
          (if (= :default a)
              (do (doto opts
                    (tset (+ opts.n 1) a)
                    (tset (+ opts.n 2) b)
                    (tset :n (+ opts.n 3)))
                  (table.insert branches [val :default])
                  (table.insert branches val))
              (= :string (type a))
              (doto opts
                (tset (+ opts.n 1) a)
                (tset (+ opts.n 2) b)
                (tset :n (+ opts.n 3)))
              (sequence? a)
              (each [_ a (ipairs a)]
                (let [p (gensym :port)]
                  (table.insert gensyms p)
                  (if (sequence? a)
                      (do (table.insert ports [p (. a 2)])
                          (table.insert gensyms (. a 1))
                          (table.insert branches [ignore p '&as res]))
                      (do (table.insert ports p)
                          (table.insert gensyms a)
                          (table.insert branches [ignore p '&as res])))
                  (if (and (list? b) (sequence? (. b 1)))
                      (table.insert branches (list 'let [(. b 1) res] (unpack b 2)))
                      (table.insert branches b))))
              (let [p (gensym :port)]
                (table.insert ports p)
                (table.insert gensyms p)
                (table.insert gensyms a)
                (table.insert branches [ignore p '&as res])
                (if (and (list? b) (sequence? (. b 1)))
                    (table.insert branches `(let [,(. b 1) ,res] ,(unpack b 2)))
                    (table.insert branches b))))))
      `(let [{:alts! alts#} (require ,lib-name)
             ,(unpack gensyms)]
         (match (alts# ,ports ,(unpack opts 1 opts.n))
           ,(unpack branches)))))

  (tset macro-loaded lib-name {: go-loop : go : alt!}))

(require-macros (or ... :async))

(defprotocol Handler
  (active? [h] "returns true if has callback. Must work w/o lock")
  (blockable? [h] "returns true if this handler may be blocked, otherwise it must not block")
  (commit [h] "commit to fulfilling its end of the transfer, returns cb. Must be called within lock"))

(fn fn-handler [f ...]
  (let [blockable (if (= 0 (select :# ...)) true ...)]
    (reify
     Handler
     (active? [_] true)
     (blockable? [_] blockable)
     (commit [_] f))))

(local fhnop (fn-handler #nil))

(local socket
  (match (pcall require :socket) (true s) s _ nil))

(local posix
  (match (pcall require :posix) (true p) p _ nil))

(local (time sleep time-type)
  (if (?. socket :gettime)
      (let [sleep socket.sleep]
        (values socket.gettime #(sleep (/ $ 1000)) :socket))
      (?. posix :clock_gettime)
      (let [gettime posix.clock_gettime
            nanosleep posix.nanosleep]
        (values #(let [(s ns) (gettime)]
                   (+ s (/ ns 1000000000)))
                #(let [(s ms) (m/modf (/ $ 1000))]
                   (nanosleep s (* 1000000 1000 ms)))
                :posix))
      (values os.time nil :lua)))

(local difftime #(- $1 $2))

;;; Buffers

(defprotocol Buffer
  (full? [buffer] "Returns `true` if `buffer` cannot accept a put.")
  (remove! [buffer] "Remove and return next item from the `buffer`, called under chan mutex.")
  (add! [buffer item] "If room, add `item` to the `buffer`, returns `buffer`, called under chan mutex.")
  (close-buf! [buffer] "called on `buffer` closed under chan mutex, return ignored."))

(local FixedBuffer
  {:type Buffer
   :full? (fn [{:buf buffer : size}]
            "Retrurn `true` if `buffer` length is equal to its `size` field."
            (>= (length buffer) size))
   :length (fn [{:buf buffer}]
             "Return item count in the `buffer`."
             (length buffer))
   :add! (fn [{:buf buffer &as this} val]
           "Add `val` into the `buffer`."
           (assert (not= val nil) "value must not be nil")
           (tset buffer (+ 1 (length buffer)) val)
           this)
   :remove! (fn [{:buf buffer}]
              "Take value from the `buffer`."
              (when (> (length buffer) 0)
                (t/remove buffer 1)))
   :close-buf! (fn [_] "noop" nil)})

(local DroppingBuffer
  {:type Buffer
   :full? (fn []
            "Check if buffer is full.
Always returns `false`."
            false)
   :length (fn [{:buf buffer}]
             "Return item count in the `buffer`."
             (length buffer))
   :add! (fn [{:buf buffer : size &as this} val]
           "Put `val` into the `buffer` if item count is less than `size`,
otherwise drop the value."
           (assert (not= val nil) "value must not be nil")
           (when (< (length buffer) size)
             (tset buffer (+ 1 (length buffer)) val))
           this)
   :remove! (fn [{:buf buffer}]
              "Take value from the `buffer`."
              (when (> (length buffer) 0)
                (t/remove buffer 1)))
   :close-buf! (fn [_] "noop" nil)})

(local SlidingBuffer
  {:type Buffer
   :full? (fn []
            "Check if buffer is full.
Always returns `false`."
            false)
   :length (fn [{:buf buffer}]
             "Return item count in the `buffer`."
             (length buffer))
   :add! (fn [{:buf buffer : size &as this} val]
           "Put `val` into the `buffer` if item count is less than `size`,
otherwise drop the oldest value."
           (assert (not= val nil) "value must not be nil")
           (tset buffer (+ 1 (length buffer)) val)
           (when (< size (length buffer))
             (t/remove buffer 1))
           this)
   :remove! (fn [{:buf buffer}]
              "Take value from the `buffer`."
              (when (> (length buffer) 0)
                (t/remove buffer 1)))
   :close-buf! (fn [_] "noop" nil)})

(local no-val {})

(local PromiseBuffer
  {:type Buffer
   :val no-val
   :full? (fn []
            "Check if buffer is full.
Always returns `false`."
            false)
   :length (fn [this]
             "Return item count in the `buffer`."
             (if (rawequal no-val this.val) 0 1))
   :add! (fn [this val]
           "Put `val` into the `buffer` if there isnt one already,
otherwise drop the value."
           (assert (not= val nil) "value must not be nil")
           (when (rawequal no-val this.val)
             (tset this :val val))
           this)
   :remove! (fn [{:val value}]
              "Take `value` from the buffer.
Doesn't remove the `val` from the buffer."
              value)
   :close-buf! (fn [{:val value &as this}]
                 "Close the promise buffer by setting its `value` to `nil` if it wasn't
delivered earlier."
                 (when (rawequal no-val value)
                   (tset this :val nil)))})

(fn buffer* [size buffer-type]
  {:private true}
  (and size (assert (= :number (type size)) (.. "size must be a number: " (tostring size))))
  (assert (not (: (tostring size) :match "%.")) "size must be integer")
  (setmetatable
   {:size size
    :buf []}
   {:__index buffer-type
    :__name "buffer"
    :__len (fn [self] (self:length))
    :__fennelview
    #(.. "#<" (: (tostring $) :gsub "table:" "buffer:") ">")}))

(fn buffer [n]
  "Returns a fixed buffer of size `n`.  When full, puts will block/park."
  (buffer* n FixedBuffer))

(fn dropping-buffer [n]
  "Returns a buffer of size `n`.  When full, puts will complete but
val will be dropped (no transfer)."
  (buffer* n DroppingBuffer))

(fn sliding-buffer [n]
  "Returns a buffer of size `n`.  When full, puts will complete, and be
buffered, but oldest elements in buffer will be dropped (not
transferred)."
  (buffer* n SlidingBuffer))

(fn promise-buffer []
  "Create a promise buffer.

When the buffer receives a value all other values are dropped.  Taking
a value from the buffer doesn't remove it from the buffer."
  (buffer* 1 PromiseBuffer))

(fn buffer? [obj]
  {:private true}
  (match obj
    {:type Buffer} true
    _ false))

(fn unblocking-buffer? [buff]
  "Returns true if a channel created with `buff` will never block.  That is
to say, puts into this buffer will never cause the buffer to be full."
  (match (and (buffer? buff)
              (. (getmetatable buff) :__index))
    SlidingBuffer true
    DroppingBuffer true
    PromiseBuffer true
    _ false))

;;; Channels

(local timeouts {})
(local dispatched-tasks {})
(local os/clock os.clock)
(var (n-instr register-time orig-hook orig-mask orig-n) 1_000_000)

(fn schedule-hook [hook n]
  "Run function `hook` after `n` VM instructions are executed.
`hook` must check that it is called with the \"count\" event and must
unset itself upon entering, re-registering itself if needs to run
again at the end.  The `hook` should calculate moderate amount of
instructions to run again without causing too much load on the system.
Returns the previous hook and its settings, if found. Optionally,
`hook` should restore the original hook returned by this function."
  {:private true}
  (when (and gethook sethook)
    (let [(hook* mask n*) (gethook)]
      (when (not= hook hook*)
        (set (register-time orig-hook orig-mask orig-n)
          (values (os/clock) hook* mask n*))
        (sethook main-thread hook "" n)))))

(fn cancel-hook [hook]
  "Cancel the given `hook`, restoring original hook and its settings if
present.  Returns the previous settings of the `hook`.  If the current
hook is not the same as `hook`, does nothing."
  {:private true}
  (when (and gethook sethook)
    (match (gethook main-thread)
      (hook ?mask ?n)
      (do (sethook main-thread orig-hook orig-mask orig-n)
          (values ?mask ?n)))))

(fn process-messages [event]
  "Close any timeout channels whose closing time is less than or equal
to current time.  Also calls any callbacks that were dispatched.
Reschedules itself approximately 10ms in the future if there are more
pending tasks or timers."
  {:private true}
  (let [took (- (os/clock) register-time)
        (_ n) (cancel-hook process-messages)]
    (set n-instr
      (if (not= event :count) n
          (m/floor (/ 0.01 (/ took n)))))
    (faccumulate [done nil _ 1 1024 :until done]
      (case (next dispatched-tasks)
        f (tset dispatched-tasks (doto f pcall) nil)
        nil true))
    (each [t ch (pairs timeouts)]
      (when (>= 0 (difftime t (time)))
        (tset timeouts t (ch:close!))))
    (when (or (next dispatched-tasks) (next timeouts))
      (schedule-hook process-messages n-instr))))

(fn dispatch [f]
  (if (and gethook sethook)
      (do (tset dispatched-tasks f true)
          (schedule-hook process-messages n-instr))
      (f))
  nil)

(macro box [val] `[,val])
(macro unbox [b] `(. ,b 1))
(macro PutBox [handler val] `[,handler ,val])
(macro -handler [pb] `(. ,pb 1))
(macro -val [pb] `(. ,pb 2))

(fn put-active? [[handler]]
  (handler:active?))

(fn cleanup! [t pred]
  (let [to-keep (icollect [i v (ipairs t)]
                  (when (pred v)
                    v))]
    (while (t/remove t))
    (each [_ v (ipairs to-keep)]
      (t/insert t v))
    t))

(local MAX-QUEUE-SIZE 1024)
(local MAX_DIRTY 64)

(local Channel
  {:dirty-puts 0 :dirty-takes 0})

(fn Channel.abort [{: puts}]
  (fn recur []
    (let [putter (t/remove puts 1)]
      (when (not= nil putter)
        (let [put-handler (-handler putter)
              val (-val putter)]
          (if (put-handler:active?)
              (let [put-cb (put-handler:commit)]
                (dispatch #(put-cb true)))
              (recur)))))))

(fn Channel.put! [{: buf : closed &as this} val handler enqueue?]
  (assert (not= val nil) "Can't put nil on a channel")
  (if (not (handler.active?))
      (box (not closed))
      closed
      (do
        (handler:commit)
        (box false))
      (and buf (not (buf:full?)))
      (let [{: takes : add!} this]
        (handler:commit)
        (let [done? (reduced? (add! buf val))
              take-cbs ((fn recur [takers]
                          (if (and (next takes) (> (length buf) 0))
                              (let [taker (t/remove takes 1)]
                                (if (taker:active?)
                                    (let [ret (taker:commit)
                                          val (buf:remove!)]
                                      (recur (doto takers (t/insert (fn [] (ret val))))))
                                    (recur takers)))
                              takers)) [])]
          (when done? (this:abort))
          (when (next take-cbs)
            (each [_ f (ipairs take-cbs)]
              (dispatch f)))
          (box true)))
      ;; else
      (let [takes this.takes
            taker ((fn recur []
                     (let [taker (t/remove takes 1)]
                       (when taker
                         (if (taker:active?)
                             taker
                             (recur))))))]
        (if taker
            (let [take-cb (taker:commit)]
              (handler:commit)
              (dispatch (fn [] (take-cb val)))
              (box true))
            (let [{: puts : dirty-puts} this]
              (if (> dirty-puts MAX_DIRTY)
                  (do (set this.dirty-puts 0)
                      (cleanup! puts put-active?))
                  (set this.dirty-puts (+ 1 dirty-puts)))
              (when (handler:blockable?)
                (assert (< (length puts) MAX-QUEUE-SIZE)
                        (.. "No more than " MAX-QUEUE-SIZE
                            " pending puts are allowed on a single channel."
                            " Consider using a windowed buffer."))
                (let [handler* (if (or (main-thread?) enqueue?) handler
                                   (let [thunk (c/running)]
                                     (reify
                                      Handler
                                      (active? [_] (handler:active?))
                                      (blockable? [_] (handler:blockable?))
                                      (commit [_] #(c/resume thunk $...)))))]
                  (t/insert puts (PutBox handler* val))
                  (when (not= handler handler*)
                    (let [val (c/yield)]
                      ((handler:commit) val)
                      (box val))))))))))

(fn Channel.take! [{: buf &as this} handler enqueue?]
  (if (not (handler:active?))
      nil
      (and (not (= nil buf)) (> (length buf) 0))
      (case (handler:commit)
        take-cb (let [puts this.puts
                      val (buf:remove!)]
                  (when (and (not (buf:full?)) (next puts))
                    (let [add! this.add!
                          [done? cbs]
                          ((fn recur [cbs]
                             (let [putter (t/remove puts 1)
                                   put-handler (-handler putter)
                                   val (-val putter)
                                   cb (and (put-handler:active?) (put-handler:commit))
                                   cbs (if cb (doto cbs (t/insert cb)) cbs)
                                   done? (when cb (reduced? (add! buf val)))]
                               (if (and (not done?) (not (buf:full?)) (next puts))
                                   (recur cbs)
                                   [done? cbs]))) [])]
                      (when done? (this:abort))
                      (each [_ cb (ipairs cbs)]
                        (dispatch #(cb true)))))
                  (box val)))
      ;; else
      (let [puts this.puts
            putter ((fn recur []
                      (let [putter (t/remove puts 1)]
                        (when putter
                          (if (: (-handler putter) :active?)
                              putter
                              (recur))))))]
        (if putter
            (let [put-cb (: (-handler putter) :commit)]
              (handler:commit)
              (dispatch #(put-cb true))
              (box (-val putter)))
            this.closed
            (do
              (when buf (this.add! buf))
              (if (and (handler:active?) (handler:commit))
                  (let [has-val (and buf (next buf.buf))
                        val (when has-val (buf:remove!))]
                    (box val))
                  nil))
            (let [{: takes : dirty-takes} this]
              (if (> dirty-takes MAX_DIRTY)
                  (do (set this.dirty-takes 0)
                      (cleanup! takes #(: $ :active?)))
                  (set this.dirty-takes (+ 1 dirty-takes)))
              (when (handler:blockable?)
                (assert (< (length takes) MAX-QUEUE-SIZE)
                        (.. "No more than " MAX-QUEUE-SIZE
                            " pending takes are allowed on a single channel."))
                (let [handler* (if (or (main-thread?) enqueue?) handler
                                   (let [thunk (c/running)]
                                     (reify
                                      Handler
                                      (active? [_] (handler:active?))
                                      (blockable? [_] (handler:blockable?))
                                      (commit [_] #(c/resume thunk $...)))))]
                  (t/insert takes handler*)
                  (when (not= handler handler*)
                    (let [val (c/yield)]
                      ((handler:commit) val)
                      (box val))))))))))

(fn Channel.close! [this]
  (if this.closed
      nil
      (let [{: buf : takes} this]
        (set this.closed true)
        (when (and buf (= 0 (length this.puts)))
          (this.add! buf))
        ((fn recur []
           (let [taker (t/remove takes 1)]
             (when (not= nil taker)
               (when (taker:active?)
                 (let [take-cb (taker:commit)
                       val (when (and buf (next buf.buf)) (buf:remove!))]
                   (dispatch (fn [] (take-cb val)))))
               (recur)))))
        (when buf (buf:close-buf!))
        nil)))

(doto Channel
  (tset :type Channel)
  (tset :close Channel.close!))

(fn err-handler* [e]
  {:private true}
  (io.stderr:write (tostring e) "\n")
  nil)

(fn add!* [buf ...]
  (case (values (select :# ...) ...)
    (1 ?val) (buf:add! ?val)
    (0) buf))

(fn chan [buf-or-n xform err-handler]
  "Creates a channel with an optional buffer, an optional
transducer, and an optional error handler.  If `buf-or-n` is a number,
will create and use a fixed buffer of that size.  If `xform` is
supplied a buffer must be specified.  `err-handler` must be a fn of one
argument - if an exception occurs during transformation it will be
called with the thrown value as an argument, and any non-nil return
value will be placed in the channel."
  (let [buffer (match buf-or-n
                 {:type Buffer} buf-or-n
                 0 nil
                 size (buffer size))
        add! (if xform
                 (do (assert (not= nil buffer) "buffer must be supplied when transducer is")
                     (xform add!*))
                 add!*)
        err-handler (or err-handler err-handler*)
        handler (fn [ch err]
                  (case (err-handler err)
                    res (ch:put! res fhnop)))
        c {:puts []
           :takes []
           :buf buffer
           :err-handler handler}]
    (fn c.add! [...]
      (case (pcall add! ...)
        (true _) _
        (false e) (handler c e)))
    (->> {:__index Channel
          :__name "ManyToManyChannel"
          :__fennelview
          #(.. "#<" (: (tostring $) :gsub "table:" "ManyToManyChannel:") ">")}
         (setmetatable c))))

(fn promise-chan [xform err-handler]
  "Creates a promise channel with an optional transducer, and an optional
exception-handler.  A promise channel can take exactly one value that
consumers will receive.  Once full, puts complete but val is
dropped (no transfer).  Consumers will block until either a value is
placed in the channel or the channel is closed.  See `chan' for the
semantics of `xform` and `err-handler`."
  (chan (promise-buffer) xform err-handler))

(fn chan? [obj]
  "Test if `obj` is a channel."
  (match obj {:type Channel} true _ false))

(fn closed? [port]
  (assert (chan? port) "expected a channel")
  port.closed)

(var warned false)

(fn timeout [msecs]
  "Returns a channel that will close after `msecs`.

To avoid running too many timers simultaneously, the same channel may
be returned if `timeout` is called within 10ms interval off the
previous call.  Because of this optimization timeout channels must
never be closed manually.

Note, timeout channels require `debug.sethook` to be present in order
to work.  While there are any active timeouts no other debug hooks
will run.

Also note that by default, Lua doesn't support sub-second time
measurements.  Unless luasocket or luaposix is available all
millisecond values are rounded to the next whole second value."
  (assert (and gethook sethook) "Can't advance timers - debug.sethook unavailable")
  (let [dt (case time-type
             :lua (let [s (/ msecs 1000)]
                    (when (and (not warned) (not (= (m/ceil s) s)))
                      (set warned true)
                      (: (timeout 10000) :take! (fn-handler #(set warned false)))
                      (io.stderr:write
                       (.. "WARNING Lua doesn't support sub-second time precision.  "
                           "Timeout rounded to the next nearest whole second.  "
                           "Install luasocket or luaposix to get sub-second precision.\n")))
                    s)
             _ (/ msecs 1000))
        t (+ (/ (m/ceil (* (time) 100)) 100) dt)
        c (or (. timeouts t)
              (let [c (chan)] (tset timeouts t c) c))]
    (schedule-hook process-messages n-instr)
    c))

(fn take! [port fn1 ...]
  "Asynchronously takes a value from `port`, passing to `fn1`.  Will pass
`nil` if closed.  If `on-caller?` (default `true`) is `true`, and value
is immediately available, will call `fn1` on calling thread.  Returns
`nil`."
  {:fnl/arglist [port fn1 on-caller?]}
  (assert (chan? port) "expected a channel as first argument")
  (assert (not= nil fn1) "expected a callback")
  (let [on-caller? (if (= (select :# ...) 0) true ...)]
    (case (port:take! (fn-handler fn1))
      retb (let [val (unbox retb)]
             (if on-caller?
                 (fn1 val)
                 (dispatch #(fn1 val)))))
    nil))

(fn try-sleep []
  "Sleep til next timeout is ready.
Used when called for a blocking OP on the main thread."
  {:private true}
  (let [timers
        (doto (icollect [timer (pairs timeouts)] timer)
          (t/sort))]
    (case (. timers 1)
      (where t sleep (not (next dispatched-tasks)))
      (let [t (- t (time))]
        (when (> t 0)
          (sleep t)
          ;; manually advance times, as we've may have overslept
          (process-messages :manual))
        true)
      _ (when (next dispatched-tasks)
          (process-messages :manual)
          true))))

(fn <!! [port]
  "Takes a value from `port`.  Will return `nil` if closed.  Will block
if nothing is available.  Not allowed to be used in direct or
transitive calls from `(go ...)` blocks."
  (assert (main-thread?) "<!! used not on the main thread")
  (var val nil)
  (take! port #(set val $))
  (while (and (= val nil) (not port.closed) (try-sleep)))
  (when (and (= nil val) (not port.closed))
    (error (.. "The " (tostring port)
               " is not ready and there are no scheduled tasks."
               " Value will never arrive.") 2))
  val)

(fn <! [port]
  "Takes a value from `port`.  Must be called inside a `(go ...)` block.
Will return `nil` if closed.  Will park if nothing is available."
  (assert (not (main-thread?)) "<! used not in (go ...) block")
  (assert (chan? port) "expected a channel as first argument")
  (case (port:take! fhnop)
    retb (unbox retb)))

(fn put! [port val ...]
  "Asynchronously puts a `val` into `port`, calling `fn1` (if supplied)
when complete.  `nil` values are not allowed.  If
`on-caller?` (default `true`) is `true`, and the put is immediately
accepted, will call `fn1` on calling thread."
  {:fnl/arglist [port val fn1 on-caller?]}
  (assert (chan? port) "expected a channel as first argument")
  (case (select :# ...)
    0 (case (port:put! val fhnop)
        retb (unbox retb)
        _ true)
    1 (put! port val ... true)
    2 (let [(fn1 on-caller?) ...]
        (case (port:put! val (fn-handler fn1))
          retb (let [ret (unbox retb)]
                 (if on-caller?
                     (fn1 ret)
                     (dispatch #(fn1 ret)))
                 ret)
          _ true))))

(fn >!! [port val]
  "Puts a `val` into `port`.  `nil` values are not allowed. Will block if no
buffer space is available.  Returns `true` unless `port` is already
closed.  Not allowed to be used in direct or transitive calls
from `(go ...)` blocks."
  (assert (main-thread?) ">!! used not on the main thread")
  (var (not-done res) true)
  (put! port val #(set (not-done res) (values false $)))
  (while (and not-done (try-sleep port)))
  (when (and not-done (not port.closed))
    (error (.. "The " (tostring port)
               " is not ready and there are no scheduled tasks."
               " Value was sent but there's no one to receive it") 2))
  res)

(fn >! [port val]
  "Puts a `val` into `port`.  `nil` values are not allowed.  Must be
called inside a `(go ...)` block.  Will park if no buffer space is
available.  Returns `true` unless `port` is already closed."
  (assert (not (main-thread?)) ">! used not in (go ...) block")
  (case (port:put! val fhnop)
    retb (unbox retb)))

(fn close! [port]
  "Close `port`."
  (assert (chan? port) "expected a channel")
  (port:close))

(fn go* [fn1]
  "Asynchronously executes the `fn1`, returning immediately to the
calling thread.  Additionally, any visible calls to `<!', `>!' and
`alts!'  channel operations within the body will block (if necessary)
by 'parking' the calling thread rather than tying up the only Lua
thread.  Upon completion of the operation, the `fn1` will be resumed.
Returns a channel which will receive the result of the `fn1` when
completed"
  (let [c (chan 1)]
    (case (-> (fn []
                (case (fn1)
                  val (>! c val))
                (close! c))
              c/create
              c/resume)
      (false msg)
      (do (c:err-handler msg)
          (close! c)))
    c))

(fn random-array [n]
  {:private true}
  (let [ids (fcollect [i 1 n] i)]
    (for [i n 2 -1]
      (let [j (m/random i)
            ti (. ids i)]
        (tset ids i (. ids j))
        (tset ids j ti)))
    ids))

(fn alt-flag []
  (let [atom {:flag true}]
    (reify
     Handler
     (active? [_] atom.flag)
     (blockable? [_] true)
     (commit [_] (set atom.flag false) true))))

(fn alt-handler [flag cb]
  (reify
   Handler
   (active? [_] (flag:active?))
   (blockable? [_] true)
   (commit [_] (flag:commit) cb)))

(fn alts! [ports ...]
  "Completes at most one of several channel operations.  Must be called
inside a (go ...) block.  `ports` is a vector of channel endpoints,
which can be either a channel to take from or a vector of
[channel-to-put-to val-to-put], in any combination.  Takes will be made
as if by <!, and puts will be made as if by >!.  Unless the :priority
option is true, if more than one port operation is ready a
non-deterministic choice will be made.  If no operation is ready and a
:default value is supplied, [default-val :default] will be returned,
otherwise alts! will park until the first operation to become ready
completes.  Returns [val port] of the completed operation, where val is
the value taken for takes, and a boolean (true unless already closed,
as per put!) for puts.

`opts` are passed as :key val ...

Supported options:

:default val - the value to use if none of the operations are immediately ready
:priority true - (default nil) when true, the operations will be tried in order.

Note: there is no guarantee that the port exps or val exprs will be
used, nor in what order should they be, so they should not be
depended upon for side effects."
  {:fnl/arglist [ports & opts]}
  (assert (not (main-thread?)) "called alts! on the main thread")
  (assert (> (length ports) 0) "alts must have at least one channel operation")
  (let [n (length ports)
        arglen (select :# ...)
        no-def {}
        opts (case (values (select :# ...) ...)
               0 {:default no-def}
               (where (1 t) (= :table (type t)))
               (accumulate [res {:default no-def} k v (pairs t)]
                 (doto res (tset k v)))
               _
               (faccumulate [res {:default no-def} i 1 arglen 2]
                 (let [(k v) (select i ...)]
                   (doto res (tset k v)))))
        ids (random-array n)
        res-ch (chan (promise-buffer))
        flag (alt-flag)]
    (var done nil)
    (for [i 1 n :until done]
      (let [id (if (and opts opts.priority) i (. ids i))
            (retb port)
            (case (. ports id)
              (where [?c ?v] (chan? ?c))
              (values
               (?c:put! ?v (alt-handler flag #(do (put! res-ch [$ ?c]) (close! res-ch))) true)
               ?c)
              (where ?c (chan? ?c))
              (values
               (?c:take! (alt-handler flag #(do (put! res-ch [$ ?c]) (close! res-ch))) true)
               ?c)
              _ (error (.. "expected a channel: " (tostring _))))]
        (when (not= nil retb)
          (>! res-ch [(unbox retb) port])
          (set done true))))
    (if (and (flag:active?) (not= no-def opts.default))
        (do (flag:commit)
            [opts.default :default])
        (<! res-ch))))

(fn offer! [port val]
  "Puts a `val` into `port` if it's possible to do so immediately.
`nil` values are not allowed.  Never blocks.  Returns `true` if offer
succeeds."
  (assert (chan? port) "expected a channel as first argument")
  (when (or (next port.takes)
            (and port.buf (not (port.buf:full?))))
    (case (port:put! val fhnop)
      retb (unbox retb))))

(fn poll! [port]
  "Takes a value from `port` if it's possible to do so immediately.
Never blocks.  Returns value if successful, `nil` otherwise."
  (assert (chan? port) "expected a channel")
  (when (or (next port.puts)
            (and port.buf (not= nil (next port.buf.buf))))
    (case (port:take! fhnop)
      retb (unbox retb))))

;;; Operations

(fn pipe [from to ...]
  "Takes elements from the `from` channel and supplies them to the `to`
channel.  By default, the to channel will be closed when the from
channel closes, but can be determined by the `close?` parameter.  Will
stop consuming the from channel if the to channel closes."
  {:fnl/arglist [from to close?]}
  (let [close? (if (= (select :# ...) 0) true ...)]
    (go-loop []
      (let [val (<! from)]
        (if (= nil val)
            (when close? (close! to))
            (do (>! to val)
                (recur)))))))

(fn pipeline* [n to xf from close? err-handler kind]
  {:private true}
  (let [jobs (chan n)
        results (chan n)
        finishes (and (= kind :async) (chan n))
        process (fn [job]
                  (case job
                    nil (do (close! results) nil)
                    [v p] (let [res (chan 1 xf err-handler)]
                            (go (>! res v)
                                (close! res))
                            (put! p res)
                            true)))
        async (fn [job]
                (case job
                  nil (do (close! results)
                          (close! finishes)
                          nil)
                  [v p] (let [res (chan 1)]
                          (xf v res)
                          (put! p res)
                          true)))]
    (for [_ 1 n]
      (case kind
        :compute (go-loop []
                   (let [job (<! jobs)]
                     (when (process job)
                       (recur))))
        :async (go-loop []
                 (let [job (<! jobs)]
                   (when (async job)
                     (<! finishes)
                     (recur))))))
    (go-loop []
      (match (<! from)
        nil (close! jobs)
        v (let [p (chan 1)]
            (>! jobs [v p])
            (>! results p)
            (recur))))
    (go-loop []
      (case (<! results)
        nil (when close? (close! to))
        p (case (<! p)
            res (do ((fn loop* []
                       (case (<! res)
                         val (do (>! to val)
                                 (loop*)))))
                    (when finishes
                      (>! finishes :done))
                    (recur)))))))

(fn pipeline-async [n to af from ...]
  "Takes elements from the `from` channel and supplies them to the `to`
channel, subject to the async function `af`, with parallelism `n`.
`af` must be a function of two arguments, the first an input value and
the second a channel on which to place the result(s).  The presumption
is that `af` will return immediately, having launched some
asynchronous operation whose completion/callback will put results on
the channel, then `close!' it.  Outputs will be returned in order
relative to the inputs.  By default, the `to` channel will be closed
when the `from` channel closes, but can be determined by the `close?`
parameter.  Will stop consuming the `from` channel if the `to` channel
closes.  See also `pipeline'."
  {:fnl/arglist [n to af from close?]}
  (let [close? (if (= (select :# ...) 0) true ...)]
    (pipeline* n to af from close? nil :async)))

(fn pipeline [n to xf from ...]
  "Takes elements from the `from` channel and supplies them to the `to`
channel, subject to the transducer `xf`, with parallelism `n`.
Because it is parallel, the transducer will be applied independently
to each element, not across elements, and may produce zero or more
outputs per input.  Outputs will be returned in order relative to the
inputs.  By default, the `to` channel will be closed when the `from`
channel closes, but can be determined by the `close?` parameter.  Will
stop consuming the `from` channel if the `to` channel closes.  Note
this is supplied for API compatibility with the Clojure version.
Values of `n > 1` will not result in actual concurrency in a
single-threaded runtime.  `err-handler` must be a fn of one argument -
if an exception occurs during transformation it will be called with
the thrown value as an argument, and any non-nil return value will be
placed in the channel."
  {:fnl/arglist [n to xf from close? err-handler]}
  (let [(close? err-handler) (if (= (select :# ...) 0) true ...)]
    (pipeline* n to xf from close? err-handler :compute)))

(fn split [p ch t-buf-or-n f-buf-or-n]
  "Takes a predicate `p` and a source channel `ch` and returns a vector
of two channels, the first of which will contain the values for which
the predicate returned true, the second those for which it returned
false.

The out channels will be unbuffered by default, or `t-buf-or-n` and
`f-buf-or-n` can be supplied.  The channels will close after the
source channel has closed."
  (let [tc (chan t-buf-or-n)
        fc (chan f-buf-or-n)]
    (go-loop []
      (let [v (<! ch)]
        (if (= nil v)
            (do (close! tc) (close! fc))
            (when (>! (if (p v) tc fc) v)
              (recur)))))
    [tc fc]))

(fn reduce [f init ch]
  "`f` should be a function of 2 arguments.  Returns a channel containing
the single result of applying `f` to `init` and the first item from the
channel, then applying `f` to that result and the 2nd item, etc.  If
the channel closes without yielding items, returns `init` and `f` is not
called.  `ch` must close before `reduce` produces a result."
  (go-loop [ret init]
    (let [v (<! ch)]
      (if (= nil v) ret
          (let [res (f ret v)]
            (if (reduced? res)
                (res:unbox)
                (recur res)))))))

(fn transduce [xform f init ch]
  "Async/reduces a channel with a transformation `xform` applied to `f`.
Usees `init` as initial value for `reduce'.  Returns a channel
containing the result.  `ch` must close before `transduce` produces a
result."
  (let [f (xform f)]
    (go (let [ret (<! (reduce f init ch))]
          (f ret)))))

(fn onto-chan! [ch coll ...]
  "Puts the contents of `coll` into the supplied channel `ch`.
By default the channel will be closed after the items are copied, but
can be determined by the `close?` parameter.  Returns a channel which
will close after the items are copied."
  {:fnl/arglist [ch coll close?]}
  (let [close? (if (= (select :# ...) 0) true ...)]
    (go (each [_ v (ipairs coll)]
          (>! ch v))
        (when close? (close! ch))
        ch)))

(fn bounded-length [bound t]
  {:private true}
  (m/min bound (length t)))

(fn to-chan! [coll]
  "Creates and returns a channel which contains the contents of `coll`,
closing when exhausted."
  (let [ch (chan (bounded-length 100 coll))]
    (onto-chan! ch coll)
    ch))

(fn pipeline-unordered*
  [n to xf from close? err-handler kind]
  (let [closes (to-chan! (fcollect [_ 1 (- n 1)] :close))
        process (fn [v p]
                  (let [res (chan 1 xf err-handler)]
                    (go
                      (>! res v)
                      (close! res)
                      ((fn loop []
                         (case (<! res)
                           v (do (put! p v)
                                 (loop)))))
                      (close! p))))]
    (for [_ 1 n]
      (go-loop []
        (case (<! from)
          v (let [c (chan 1)]
              (case kind
                :compute (go (process v c))
                :async (go (xf v c)))
              (when ((fn loop []
                       (case (<! c)
                         res (when (>! to res)
                               (loop))
                         _ true)))
                (recur)))
          _ (when (and close?
                       (= nil (<! closes)))
              (close! to)))))))

(fn pipeline-unordered
  [n to xf from ...]
  "Takes elements from the `from` channel and supplies them to the `to`
channel, subject to the transducer `xf`, with parallelism `n`. Because
it is parallel, the transducer will be applied independently to each
element, not across elements, and may produce zero or more outputs per
input.  Outputs will be returned in order of completion. By default,
the to channel will be closed when the from channel closes, but can be
determined by the `close?` parameter. Will stop consuming the from
channel if the to channel closes. `err-handler` must be a fn of one
argument - if an exception occurs during transformation it will be
called with the thrown value as an argument, and any non-nil return
value will be placed in the channel. Note, values of `n > 1` will not
result in actual concurrency in a single-threaded runtime. See also
`pipeline`, `pipeline-async`."
  {:fnl/arglist [n to xf from close? err-handler]}
  (let [(close? err-handler) (if (= (select :# ...) 0) true ...)]
    (pipeline-unordered* n to xf from close? err-handler :compute)))

(fn pipeline-async-unordered [n to af from ...]
  "Takes elements from the `from` channel and supplies them to the `to`
channel, subject to the async function `af`, with parallelism `n`. `af`
must be a function of two arguments, the first an input value and
the second a channel on which to place the result(s). The
presumption is that `af` will return immediately, having launched some
asynchronous operation whose completion/callback will put results on
the channel, then `close!` it. Outputs will be returned in order
of completion. By default, the to channel will be closed
when the from channel closes, but can be determined by the `close?`
parameter. Will stop consuming the `from` channel if the `to` channel
closes. See also `pipeline`, `pipeline-async`."
  {:fnl/arglist [n to af from close?]}
  (let [close? (if (= (select :# ...) 0) true ...)]
    (pipeline-unordered* n to af from close? nil :async)))

;;; Mult, Mix, Pub

(defprotocol Mux
  (muxch* [_]))

(defprotocol Mult
  (tap* [_ ch close?])
  (untap* [_ ch])
  (untap-all* [_]))

(fn mult [ch]
  "Creates and returns a mult(iple) of the supplied channel
`ch`.  Channels containing copies of the channel can be created with
'tap', and detached with 'untap'.

Each item is distributed to all taps in parallel and synchronously,
i.e. each tap must accept before the next item is distributed.  Use
buffering/windowing to prevent slow taps from holding up the mult.

Items received when there are no taps get dropped.

If a tap puts to a closed channel, it will be removed from the mult."
  (var dctr nil)
  (let [atom {:cs {}}
        m (reify
           Mux
           (muxch* [_] ch)

           Mult
           (tap* [_ ch close?] (tset atom :cs ch close?) nil)
           (untap* [_ ch] (tset atom :cs ch nil) nil)
           (untap-all* [_] (tset atom :cs {}) nil))
        dchan (chan 1)
        done (fn [_]
               (set dctr (- dctr 1))
               (when (= 0 dctr)
                 (put! dchan true)))]
    (go-loop []
      (let [val (<! ch)]
        (if (= nil val)
            (each [c close? (pairs atom.cs)]
              (when close? (close! c)))
            (let [chs (icollect [k (pairs atom.cs)] k)]
              (set dctr (length chs))
              (each [_ c (ipairs chs)]
                (when (not (put! c val done))
                  (untap* m c)))
              ;;wait for all
              (when (next chs)
                (<! dchan))
              (recur)))))
    m))

(fn tap [mult ch ...]
  "Copies the `mult` source onto the supplied channel `ch`.
By default the channel will be closed when the source closes, but can
be determined by the `close?` parameter."
  {:fnl/arglist [mult ch close?]}
  (let [close? (if (= (select :# ...) 0) true ...)]
    (tap* mult ch close?) ch))

(fn untap [mult ch]
  "Disconnects a target channel `ch` from a `mult`."
  (untap* mult ch))

(fn untap-all [mult]
  "Disconnects all target channels from a `mult`."
  (untap-all* mult))

(defprotocol Mix
  (admix* [_ ch])
  (unmix* [_ ch])
  (unmix-all* [_])
  (toggle* [_ state-map])
  (solo-mode* [_ mode]))

(fn mix [out]
  "Creates and returns a mix of one or more input channels which will
be put on the supplied `out` channel.  Input sources can be added to
the mix with 'admix', and removed with 'unmix'.  A mix supports
soloing, muting and pausing multiple inputs atomically using 'toggle',
and can solo using either muting or pausing as determined by
'solo-mode'.

Each channel can have zero or more boolean modes set via 'toggle':

:solo - when `true`, only this (ond other soloed) channel(s) will
        appear in the mix output channel.  `:mute` and `:pause` states
        of soloed channels are ignored.  If solo-mode is `:mute`,
        non-soloed channels are muted, if `:pause`, non-soloed
        channels are paused.
:mute - muted channels will have their contents consumed but not
        included in the mix
:pause - paused channels will not have their contents consumed (and
         thus also not included in the mix)"
  (let [atom {:cs {}
              :solo-mode :mute}
        solo-modes {:mute true :pause true}
        change (chan (sliding-buffer 1))
        changed #(put! change true)
        pick (fn [attr chs]
               (collect [c v (pairs chs)]
                 (when (. v attr)
                   (values c true))))
        calc-state (fn []
                     (let [chs atom.cs
                           mode atom.solo-mode
                           solos (pick :solo chs)
                           pauses (pick :pause chs)]
                       {:solos solos
                        :mutes (pick :mute chs)
                        :reads (doto (if (and (= mode :pause) (next solos))
                                         (icollect [k (pairs solos)] k)
                                         (icollect [k (pairs chs)]
                                           (when (not (. pauses k))
                                             k)))
                                 (t/insert change))}))
        m (reify
           Mux
           (muxch* [_] out)
           Mix
           (admix* [_ ch] (tset atom.cs ch {}) (changed))
           (unmix* [_ ch] (tset atom.cs ch nil) (changed))
           (unmix-all* [_] (set atom.cs {}) (changed))
           (toggle* [_ state-map]
                   (set atom.cs (merge-with merge* atom.cs state-map))
                   (changed))
           (solo-mode* [_ mode]
                      (when (not (. solo-modes mode))
                        (assert false (.. "mode must be one of: "
                                          (t/concat (icollect [k (pairs solo-modes)] k) ", "))))
                      (set atom.solo-mode mode)
                      (changed)))]
    (go-loop [{: solos : mutes : reads &as state} (calc-state)]
      (let [[v c &as res] (alts! reads)]
        (if (or (= nil v) (= c change))
            (do (when (= nil v)
                  (tset atom.cs c nil))
                (recur (calc-state)))
            (if (or (. solos c)
                    (and (not (next solos)) (not (. mutes c))))
                (when (>! out v)
                  (recur state))
                (recur state)))))
    m))

(fn admix [mix ch]
  "Adds `ch` as an input to the `mix`."
  (admix* mix ch))

(fn unmix [mix ch]
  "Removes `ch` as an input to the `mix`."
  (unmix* mix ch))

(fn unmix-all [mix]
  "Removes all inputs from the `mix`."
  (unmix-all* mix))

(fn toggle [mix state-map]
  "Atomically sets the state(s) of one or more channels in a `mix`.  The
`state-map` is a map of channels -> channel-state-map.  A
channel-state-map is a map of attrs -> boolean, where attr is one or
more of `:mute`, `:pause` or `:solo`.  Any states supplied are merged
with the current state.

Note that channels can be added to a `mix` via `toggle', which can be
used to add channels in a particular (e.g. paused) state."
  (toggle* mix state-map))

(fn solo-mode [mix mode]
  "Sets the solo mode of the `mix`.  `mode` must be one of `:mute` or
`:pause`."
  (solo-mode* mix mode))

(defprotocol Pub
  (sub* [_ v ch close?])
  (unsub* [_ v ch])
  (unsub-all* [_ v]))

(fn pub [ch topic-fn buf-fn]
  "Creates and returns a pub(lication) of the supplied channel `ch`,
partitioned into topics by the `topic-fn`.  `topic-fn` will be applied
to each value on the channel and the result will determine the 'topic'
on which that value will be put.  Channels can be subscribed to
receive copies of topics using 'sub', and unsubscribed using 'unsub'.
Each topic will be handled by an internal mult on a dedicated channel.
By default these internal channels are unbuffered, but a `buf-fn` can
be supplied which, given a topic, creates a buffer with desired
properties.  Each item is distributed to all subs in parallel and
synchronously, i.e. each sub must accept before the next item is
distributed.  Use buffering/windowing to prevent slow subs from
holding up the pub.  Items received when there are no matching subs
get dropped.  Note that if `buf-fns` are used then each topic is
handled asynchronously, i.e. if a channel is subscribed to more than
one topic it should not expect them to be interleaved identically with
the source."
  (let [buf-fn (or buf-fn #nil)
        atom {:mults {}}
        ensure-mult (fn [topic]
                      (case (. atom :mults topic)
                        m m
                        nil (let [mults atom.mults
                                  m (mult (chan (buf-fn topic)))]
                              (doto mults (tset topic m))
                              m)))
        p (reify
           Mux
           (muxch* [_] ch)

           Pub
           (sub* [_ topic ch close?]
                (let [m (ensure-mult topic)]
                  (tap* m ch close?)))
           (unsub* [_ topic ch]
                  (case (. atom :mults topic)
                    m (untap* m ch)))
           (unsub-all* [_ topic]
                      (if topic
                          (tset atom :mults topic nil)
                          (tset atom :mults {}))))]
    (go-loop []
      (let [val (<! ch)]
        (if (= nil val)
            (each [_ m (pairs atom.mults)]
              (close! (muxch* m)))
            (let [topic (topic-fn val)]
              (case (. atom :mults topic)
                m (when (not (>! (muxch* m) val))
                    (tset atom :mults topic nil)))
              (recur)))))
    p))

(fn sub [pub topic ch ...]
  "Subscribes a channel `ch` to a `topic` of a `pub`.
By default the channel will be closed when the source closes, but can
be determined by the `close?` parameter."
  {:fnl/arglist [pub topic ch close?]}
  (let [close? (if (= (select :# ...) 0) true ...)]
    (sub* pub topic ch close?)))

(fn unsub [pub topic ch]
  "Unsubscribes a channel `ch` from a `topic` of a `pub`."
  (unsub* pub topic ch))

(fn unsub-all [pub topic]
  "Unsubscribes all channels from a `pub`, or a `topic` of a `pub`."
  (unsub-all* pub topic))

;;;

(fn map [f chs buf-or-n]
  "Takes a function and a collection of source channels `chs`, and
returns a channel which contains the values produced by applying `f`
to the set of first items taken from each source channel, followed by
applying `f` to the set of second items from each channel, until any
one of the channels is closed, at which point the output channel will
be closed.  The returned channel will be unbuffered by default, or a
`buf-or-n` can be supplied."
  (var dctr nil)
  (let [out (chan buf-or-n)
        cnt (length chs)
        rets {:n cnt}
        dchan (chan 1)
        done (fcollect [i 1 cnt]
               (fn [ret]
                 (tset rets i ret)
                 (set dctr (- dctr 1))
                 (when (= 0 dctr)
                   (put! dchan rets))))]
    (if (= 0 cnt)
        (close! out)
        (go-loop []
          (set dctr cnt)
          (for [i 1 cnt]
            (case (pcall take! (. chs i) (. done i))
              false (set dctr (- dctr 1))))
          (let [rets (<! dchan)]
            (if (faccumulate [res false
                              i 1 rets.n
                              :until res]
                  (= nil (. rets i)))
                (close! out)
                (do (>! out (f (t/unpack rets)))
                    (recur))))))
    out))

(fn merge [chs buf-or-n]
  "Takes a collection of source channels `chs` and returns a channel which
contains all values taken from them.  The returned channel will be
unbuffered by default, or a `buf-or-n` can be supplied.  The channel
will close after all the source channels have closed."
  (let [out (chan buf-or-n)]
    (go-loop [cs chs]
      (if (> (length cs) 0)
          (let [[v c] (alts! cs)]
            (if (= nil v)
                (recur (icollect [_ c* (ipairs cs)]
                         (when (not= c* c) c*)))
                (do (>! out v)
                    (recur cs))))
          (close! out)))
    out))

(fn into [t ch]
  "Returns a channel containing the single (collection) result of the
items taken from the channel `ch` conjoined to the supplied collection
`t`.  `ch` must close before `into` produces a result."
  (reduce #(doto $1 (tset (+ 1 (length $1)) $2)) t ch))

(fn take [n ch buf-or-n]
  "Returns a channel that will return, at most, `n` items from
`ch`.  After n items have been returned, or `ch` has been closed, the
return chanel will close.  The output channel is unbuffered by
default, unless `buf-or-n` is given."
  (let [out (chan buf-or-n)]
    (go (var done false)
        (for [i 1 n :until done]
          (case (<! ch)
            v (>! out v)
            nil (set done true)))
        (close! out))
    out))

{: buffer
 : dropping-buffer
 : sliding-buffer
 : promise-buffer
 : unblocking-buffer?
 : chan
 : promise-chan
 : take!
 : <!!
 : <!
 : timeout
 : put!
 : >!!
 : >!
 : close!
 :go go*
 : alts!
 : offer!
 : poll!
 : pipe
 : pipeline-async
 : pipeline
 : pipeline-async-unordered
 : pipeline-unordered
 : reduce
 : reduced
 : reduced?
 : transduce
 : split
 : onto-chan!
 : to-chan!
 : mult
 : tap
 : untap
 : untap-all
 : mix
 : admix
 : unmix
 : unmix-all
 : toggle
 : solo-mode
 : pub
 : sub
 : unsub
 : unsub-all
 : map
 : merge
 : into
 : take
 :buffers
 {: FixedBuffer
  : SlidingBuffer
  : DroppingBuffer
  : PromiseBuffer}}
