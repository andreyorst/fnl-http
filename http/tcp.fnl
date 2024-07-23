(import-macros
    {: go-loop : go}
 (doto :lib.async require))

(local {: chan : <! : >! : offer! : timeout
        : close!}
  (require :lib.async))

(local socket
  (require :socket))

(fn -set-chunk-size [self pattern-or-size]
  ;; Sets the chunk-size property of a socket channel in order to
  ;; dynamically adjust during reads.
  (set self.chunk-size pattern-or-size))

(fn -socket-channel [client xform err-handler]
  ;; returns a combo channel, where puts and takes are handled by
  ;; different channels which are used as buffers for two async
  ;; processes that interact with the socket
  {:private true}
  (let [recv (chan 1024 xform err-handler)
        resp (chan 1024 xform err-handler)
        ready (chan)
        close (fn [self] (recv:close!) (resp:close!) (set self.closed true))
        c (-> {:puts recv.puts
               :takes resp.takes
               :put! (fn [_  val handler enqueue?]
                       (recv:put! val handler enqueue?))
               :take! (fn [_ handler enqueue?]
                        ;; TODO: test extensively
                        (offer! ready :ready)
                        (resp:take! handler enqueue?))
               :close! close
               :close close
               :chunk-size 1024
               :set-chunk-size -set-chunk-size}
              (setmetatable
               {:__index (. (getmetatable ready) :__index)
                :__name "SocketChannel"
                :__fennelview
                #(.. "#<" (: (tostring $) :gsub "table:" "SocketChannel:") ">")}))]
    (go-loop [data (<! recv) i 0]
      (when (not= nil data)
        (case (socket.select nil [client] 0)
          (_ [s])
          (case (s:send data i)
            (nil :timeout j)
            (do (<! (timeout 10)) (recur data j))
            (nil :closed)
            (do (s:close) (close! c))
            _ (recur (<! recv) 0))
          _ (do (<! (timeout 10))
                (recur data i)))))
    (go-loop [wait? true
              part ""
              remaining nil]
      (when wait?
        (<! ready))
      (let [size (or remaining c.chunk-size)]
        (case (client:receive size "")
          data
          (do (>! resp (.. part data))
              (recur true "" nil))
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
              (recur false part remaining))
          (nil :timeout data)
          (let [bytes? (= :number (type size))
                remaining (if bytes?
                              (- size (length data))
                              size)]
            (<! (timeout 10))
            (if bytes?
                (recur (= remaining 0)
                       (.. part data)
                       (and (> remaining 0) remaining))
                (recur false
                       (.. part data)
                       remaining))))))
    c))

(fn chan [{: host : port} xform err-handler]
  "Creates a channel that connects to a socket via `host` and `port`.
Optionally accepts a transducer `xform`, and an error handler.
`err-handler` must be a fn of one argument - if an exception occurs
during transformation it will be called with the thrown value as an
argument, and any non-nil return value will be placed in the channel.
The read pattern f a socket can be controlled with the
`set-chunk-size` method."
  (assert socket "tcp module requires luasocket")
  (let [host (or host :localhost)]
    (match-try (socket.connect host port)
      client (client:settimeout 0)
      _ (-socket-channel client xform err-handler)
      (catch (nil err) (error err)))))

{: chan}
