(fn ok? [ok? ...] (when ok? ...))

(local Reader {})

(fn make-reader [source {: read-bytes : read-line : close : peek}]
  "Generic reader generator.
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

All methods are optional, and if not provided, the return value of
each is `nil`."
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
                   #nil)}
        (setmetatable
         {:reader Reader
          :__close close
          :__name "Reader"
          :__fennelview #(.. "#<" (: (tostring $) :gsub "table:" "Reader:") ">")}))))

(fn file-reader [file]
  "Reader generator for files.
Accepts a `file` or a string path which is opened automatically handle."
  (let [file (case (type file)
               :string (io.open file :r)
               _ file)]
      (make-reader file
                   {:close #(: $ :close)
                    :read-bytes (fn [f pattern] (f:read pattern))
                    :read-line (file:lines)
                    :peek (fn [f pattern]
                            (assert (= :number (type pattern)) "expected number of bytes to peek")
                            (let [res (f:read pattern)]
                              (f:seek :cur (- pattern))
                              res))})))

(fn string-reader [string]
  "Input stream generator for strings.
Accepts a `string`."
  (var (i closed) (values 1 false))
  (let [len (length string)
        try-read-line (fn [s pattern]
                        (case (s:find pattern i)
                          (start end s)
                          (do (set i (+ end 1)) s)))
        read-line (fn [s]
                    (when (<= i len)
                      (or (try-read-line s "(.-)\r?\n")
                          (try-read-line s "(.-)\r?$"))))]
    (make-reader
     string
     {:close (fn [_]
               (when (not closed)
                 (set i (+ len 1))
                 (set closed true)
                 closed))
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
                  _ (error "expected number of bytes to peek"))))})))

(fn reader? [obj]
  (= Reader (. (getmetatable obj) :reader)))

{: make-reader
 : file-reader
 : string-reader
 : reader?}
