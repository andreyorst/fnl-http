(local {: >! : <! : >!! : <!!
        : chan : chan? : main-thread?}
  (require :lib.async))

(local {: lower} string)

(fn <!? [port]
  "Takes a value from `port`.  Will return `nil` if closed.  Will block
if nothing is available and used on the main thread.  Will park if
nothing is available and used in the `go` block."
  (if (main-thread?)
      (<!! port)
      (<! port)))

(fn >!? [port val]
  "Puts a `val` into `port`.  `nil` values are not allowed.  Must be
called inside a `(go ...)` block.  Will park if no buffer space is
available.  Returns `true` unless `port` is already closed."
  (if (main-thread?)
      (>!! port val)
      (>! port val)))

(fn make-tcp-client [socket-channel]
  "Accepts a `socket-channel`. Wraps it with a bunch of
methods to act like Luasocket client."
  (setmetatable
   {:read (fn [_ pattern]
            (let [ch (chan)]
              (socket-channel:set-chunk-size pattern ch)
              (<!? ch)))
    :receive (fn [_ pattern prefix]
               (let [ch (chan)]
                 (.. (or prefix "") (<!? ch))))
    :send (fn [_ data ...]
            (->> (case (values (select :# ...) ...)
                   0 data
                   (1 i) (data:sub i (length data))
                   _ (data:sub ...))
                 (>!? socket-channel)))
    :close (fn [_] (socket-channel:close))
    :write (fn [_ data] (>!? socket-channel data))}
   {:__name "tcp-client"
    :__fennelview
    #(.. "#<" (: (tostring $) :gsub "table" "tcp-client") ">")}))

(fn chunked-encoding? [transfer-encoding]
  "Test if `transfer-encoding` header is chunked."
  (case (lower (or transfer-encoding ""))
    (where header (or (header:match "chunked[, ]")
                      (header:match "chunked$")))
    true))

{: make-tcp-client
 : <!?
 : >!?
 : chunked-encoding?}