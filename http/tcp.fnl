(import-macros
    {: go-loop : go}
 (doto :lib.async require))

(local {: chan : <! : >! : offer! : timeout
        : close!}
  (require :lib.async))

(local {: >!?}
  (require :http.async-extras))

(local {:select s/select
        :connect s/connect
        &as socket}
  (require :socket))

(fn chunk-setter [ch]
  (fn set-chunk-size [_ pattern-or-size]
    "Sets the chunk-size property of a socket channel in order to
dynamically adjust during reads."
    {:private true}
    (>!? ch pattern-or-size)))

(fn socket-channel [client xform err-handler]
  "Returns a combo channel, where puts and takes are handled by
different channels which are used as buffers for two async processes
that interact with the socket"
  {:private true}
  (let [recv (chan 1024 xform err-handler)
        ;; TODO: decide if xform is needed on the `resp` channel.  The
        ;;       server responds with data, and we put it to the
        ;;       channel.  Thus, it can look like when the server just
        ;;       has this channel directly, so it makes sense to obey
        ;;       the `xform`.  On the other hand, the server doesn't
        ;;       really knows anything about the channel, and the
        ;;       communication itself is already like an `xform`.
        ;;       Decide what to do.
        resp (chan 1024 xform err-handler)
        next-chunk (chan)
        close (fn [self] (recv:close!) (resp:close!) (set self.closed true))
        c (-> {:puts recv.puts
               :takes resp.takes
               :put! (fn [_  val handler enqueue?]
                       (recv:put! val handler enqueue?))
               :take! (fn [_ handler enqueue?]
                        (resp:take! handler enqueue?))
               :close! close
               :close close
               :set-chunk-size (chunk-setter next-chunk)}
              (setmetatable
               {:__index (. (getmetatable next-chunk) :__index)
                :__name "SocketChannel"
                :__fennelview
                #(.. "#<" (: (tostring $) :gsub "table:" "SocketChannel:") ">")}))]
    (go-loop [data (<! recv) i 0]
      (when (not= nil data)
        (case (s/select nil [client] 0)
          (_ [s])
          (case (s:send data i)
            (nil :timeout j)
            (do (<! (timeout 10)) (recur data j))
            (nil :closed)
            (do (s:close) (close! c))
            _ (recur (<! recv) 0))
          _ (do (<! (timeout 10))
                (recur data i)))))
    (go-loop [chunk-size (<! next-chunk)
              partial-data ""]
      (case (client:receive chunk-size)
        data
        (do (>! resp (.. partial-data data))
            (recur (<! next-chunk) ""))
        (where (nil :closed ?data)
               (or (= ?data nil) (= ?data "")))
        (do (client:close)
            (close! c))
        (nil :closed data)
        (do (client:close)
            (>! resp data)
            (close! c))
        (where (nil :timeout ?data)
               (or (= ?data nil) (= ?data "")))
        (do (<! (timeout 10))
            (recur chunk-size partial-data))
        (nil :timeout data)
        (do (<! (timeout 10))
            (case (and (= :number (type chunk-size))
                       (- chunk-size (length data)))
              chunk-size* (recur chunk-size* (.. partial-data data))
              _ (recur chunk-size (.. partial-data data))))))
    c))

(fn chan [{: host : port} xform err-handler]
  "Creates a channel that connects to a socket via `host` and `port`.
Optionally accepts a transducer `xform`, and an error handler.
`err-handler` must be a fn of one argument - if an exception occurs
during transformation it will be called with the thrown value as an
argument, and any non-nil return value will be placed in the channel.
The read pattern for a socket must be explicitly set with the
`set-chunk-size` method before each take operation."
  (assert socket "tcp module requires luasocket")
  (let [host (or host :localhost)]
    (match-try (s/connect host port)
      client (client:settimeout 0)
      _ (socket-channel client xform err-handler)
      (catch (nil err) (error err)))))

{: chan}
