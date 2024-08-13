(fn ok? [ok? ...] (when ok? ...))

(local Reader {})

(fn make-reader [source {: read-bytes : read-line : close : peek :length len}]
  {:fnl/docstring "Generic reader generator.
Accepts methods, that the `source` is going to be passed, and produce
appropriate results.

Available methods:

- `close` method should return `true` when the resource is first
closed, and `nil` for repeated attempts at closing the reader.
- `read-bytes` method should return a specified amount of bytes,
determined either by the number of bytes, or by a supported read
pattern.
- `read-line` method should return a logical line of text, if the
reader source supports line iteration.
- `peek` method should read a specified amount of bytes without moving
  the position in the reader.
- `length` method should return the amount of bytes left in the
  reader.

All methods are optional, and if not provided, the return value of
each is `nil`."
   :fnl/arglist [source {: read-bytes : read-line : close : peek : length}]}
  (let [close (if close
                  (fn [_ ...]
                    (ok? (pcall close source ...)))
                  #nil)]
    (-> {: close
         :read (if read-bytes
                   (fn [_ pattern ...]
                     (read-bytes source pattern ...)) #nil)
         :lines (if read-line
                    (fn []
                      (fn [_ ...]
                        (read-line source ...)))
                    (fn [] #nil))
         :peek (if peek
                   (fn [_ pattern ...]
                     (peek source pattern ...))
                   #nil)
         :length (if len
                     (fn []
                       (len source))
                     #nil)}
        (setmetatable
         {:__index Reader
          :__close close
          :__len (if len (fn [] (len source)) #nil)
          :__name "Reader"
          :__fennelview #(.. "#<" (: (tostring $) :gsub "table:" "Reader:") ">")}))))

(local {: open :type io/type} io)

(fn file-reader [file]
  "Creates a `Reader` from the given `file`.
Accepts a file handle or a path string which is opened automatically."
  (let [file (case (or (io/type file) (type file))
               :string (open file :r)
               :file file
               "closed file" (error "file is closed" 2)
               _ (error (.. "expected a string path or a file handle, got " _)))
        open? #(case (io/type $) :file true)]
    (make-reader file
                 {:close #(when (open? $) ($:close))
                  :read-bytes (fn [f pattern]
                                (when (open? f)
                                  (f:read pattern)))
                  :read-line (fn [f]
                               (let [next-line (when (open? f) (file:lines))]
                                 (when (open? f) (next-line))))
                  :peek (fn [f pattern]
                          (assert (= :number (type pattern)) "expected number of bytes to peek")
                          (when (open? f)
                            (let [res (f:read pattern)]
                              (f:seek :cur (- pattern))
                              res)))
                  :length (fn [f]
                            (when (open? f)
                              (let [current (f:seek :cur)
                                    len (- (f:seek :end) current)]
                                (f:seek :cur (- len))
                                len)))})))

(local {: max} math)

(fn string-reader [string]
  "Creates a `Reader` from the given `string`."
  (assert (= :string (type string)) "expected a string as first argument")
  (var (i closed?) (values 1 false))
  (let [len (length string)
        try-read-line (fn [s pattern]
                        (case (s:find pattern i)
                          (_ end s)
                          (do (set i (+ end 1)) s)))
        read-line (fn [s]
                    (when (<= i len)
                      (or (try-read-line s "(.-)\r?\n")
                          (try-read-line s "(.-)\r?$"))))]
    (make-reader
     string
     {:close (fn [_]
               (when (not closed?)
                 (set i (+ len 1))
                 (set closed? true)
                 closed?))
      :read-bytes (fn [s pattern]
                    (when (<= i len)
                      (case pattern
                        (where (or :*l :l))
                        (read-line s)
                        (where (or :*a :a))
                        (s:sub i)
                        (where bytes (= :number (type bytes)))
                        (let [res (s:sub i (+ i bytes -1))]
                          (set i (+ i bytes))
                          res))))
      :read-line read-line
      :peek (fn [s pattern]
              (when (<= i len)
                (case pattern
                  (where bytes (= :number (type bytes)))
                  (let [res (s:sub i (+ i bytes -1))]
                    res)
                  _ (error "expected number of bytes to peek"))))
      :length (fn [s]
                (when (not closed?)
                  (max 0 (- (length s) (- i 1)))))})))

(local (ltn? ltn12)
  (pcall require :ltn12))

(local {:table sink/table
        :null sink/null} ltn12.sink)

(local {: concat} table)

(fn ltn12-reader [source step]
  "Creates a `Reader` from LTN12 `source`.
Accepts an optional `step` function, to pump data from source when
required.  If no `step` provided, the default `ltn12.pump.step` is
used."
  (let [step (or step ltn12.pump.step)]
    (var buffer "")
    (var closed? false)
    (fn read [_ pattern]
      (when (not closed?)
        (let [rdr (string-reader buffer)
              content (rdr:read pattern)
              len (length (or content ""))
              data []]
          (case pattern
            (where bytes (= :number (type bytes)))
            (do (set buffer (or (rdr:read :*a) ""))
                (if (< len pattern)
                    (if (step source (sink/table data))
                        (do (set buffer (.. buffer (or (. data 1) "")))
                            (case (read _ (- bytes len))
                              (where data data) (.. (or content "") data)
                              _ content))
                        content)
                    content))
            (where (or :*a :a))
            (do (set buffer (or (rdr:read :*a) ""))
                (while (step source (sink/table data)) nil)
                (.. (or content "") (concat data)))
            (where (or :*l :l))
            (if (buffer:match "\n")
                (do (set buffer (or (rdr:read :*a) ""))
                    content)
                (if (step source (sink/table data))
                    (do (set buffer (.. buffer (or (. data 1) "")))
                        (case (read _ pattern)
                          data (.. (or content "") data)
                          _ content))
                    (do (set buffer (or (rdr:read :*a) ""))
                        content)))))))
    (make-reader
     source
     {:close (fn []
               (while (step source (sink/null)) nil)
               (set closed? true))
      :read-bytes read
      :read-line #(when (not closed?) (read $ :*l))
      :peek (fn peek [_ bytes]
              (when (not closed?)
                (let [rdr (string-reader buffer)
                      content (rdr:peek bytes)
                      len (length (or content ""))
                      data []]
                  (if (< len bytes)
                      (if (step source (sink/table data))
                          (do (set buffer (.. buffer (or (. data 1) "")))
                              (case (peek _ (- bytes len))
                                (where data data) data
                                _ content))
                          content)
                      content))))})))

(fn reader? [obj]
  "Check if `obj` is an instance of `Reader`."
  (match (getmetatable obj)
    {:__index Reader} true
    _ false))

{: make-reader
 : file-reader
 : string-reader
 : reader?
 :ltn12-reader (and ltn? ltn12-reader)}
