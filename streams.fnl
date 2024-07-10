(fn input-stream [{: read-bytes : read-line : close}]
  "Generic input stream generator.
Accepts methods, that enclose some source, and produce appropriate
results.

The `close` method should return `true` when the resource is first
closed, and `nil` for repeated attempts at closing the stream.

The `read-bytes` method should return a specified amount of bytes,
determined either by the number of bytes, or by a supported read
pattern.

The `read-line` method should return a logical line of text, if the
stream source supports line iteration.

All methods are optional, and if not provided, the return value of
each is `nil`."
  (let [close (if close
                  (fn [...] ((fn [ok? ...] (when ok? ...)) (pcall close ...)))
                  #nil)]
    (-> {:close close
         :read (if read-bytes
                   (fn [...] ((fn [ok? ...] (when ok? ...)) (pcall read-bytes ...)))
                   #nil)
         :lines (if read-line
                    (fn [] #((fn [ok? ...] (when ok? ...)) (pcall read-line)))
                    (fn [] #nil))}
        (setmetatable
         {:__close close
          :__name "Stream"
          :__fennelview #(.. "#<" (: (tostring $) :gsub "table:" "Stream:") ">")}))))

(fn file-input-stream [file]
  "Input stream generator for files.
Accepts a `file` handle."
  (input-stream
   {:close #(file:close)
    :read-bytes (fn [_ pattern] (file:read pattern))
    :read-line (file:lines)}))

(fn string-input-stream [s]
  "Input stream generator for strings.
Accepts a string `s`."
  (var (i closed) (values 1 false))
  (let [len (length s)]
    (input-stream
     {:close #(do (set i (+ len 1))
                  (when (not closed)
                    (set closed true)
                    closed))
      :read-bytes (fn [_ bytes]
                    (when (< i len)
                      (let [res (s:sub i (+ i bytes -1))]
                        (set i (+ i bytes))
                        res)))
      :read-line (fn []
                   (case (s:find "(.-)\r?\n" i)
                     (start end s) (do (set i (+ end 1))
                                       s)
                     nil (when (< i len)
                           (case (s:find "(.-)\r?$" i)
                             (start end s) (do (print start end s)
                                               (set i (+ end 1))
                                               s)))))})))

{: input-stream
 : file-input-stream
 : string-input-stream}
