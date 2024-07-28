(local {: >! : <! : >!! : <!!
        : chan? : main-thread?}
  (require :lib.async))

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

{: <!? : >!?}
