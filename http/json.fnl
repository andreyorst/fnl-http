(local {: reader?
        : string-reader
        : file-reader
        : make-reader}
  (require :http.readers))

(local {: file?}
  (require :http.utils))

(local {: concat} table)

(local {: gsub : format} string)

(fn string? [val]
  {:private true}
  (and (= :string (type val))
       {:string val}))

(fn number? [val]
  {:private true}
  (and (= :number (type val))
       {:number val}))

(fn object? [val]
  {:private true}
  (and (= :table (type val))
       {:object val}))

(fn array? [val ?max]
  {:private true}
  (and (object? val)
       (case (length val)
         0 false
         len (let [max (or ?max len)]
               (case (next val max)
                 (where k (= :number (type k)))
                 (array? val k)
                 nil {:n max :array val}
                 _ false)))))

(fn function? [val]
  {:private true}
  (and (= :function (type val))
       {:function val}))

(fn guess [val]
  {:private true}
  (or (array? val)
      (object? val)
      (string? val)
      (number? val)
      (function? val)
      val))

(fn escape-string [str]
  {:private true}
  (let [escs (-> {"\a" "\\a"
                  "\b" "\\b"
                  "\f" "\\f"
                  "\v" "\\v"
                  "\r" "\\r"
                  "\t" "\\t"
                  :\ "\\\\"
                  "\"" "\\\""
                  "\n" "\\n"}
                 (setmetatable
                  {:__index #(: "\\%03d" :format ($2:byte))}))]
    (.. "\"" (str:gsub "[%c\\\"]" escs) "\"")))

(fn encode [val]
  "Encode a Lua value `val` as JSON."
  (case (guess val)
    {:array array :n n}
    (.. "[" (-> (fcollect [i 1 n]
                  (encode (. array i)))
                (concat ", ")) "]")
    {:object object}
    (.. "{" (-> (icollect [k v (pairs object)]
                  (.. (encode k) ": " (encode v)))
                (concat ", ")) "}")
    {:string s}
    (escape-string s)
    {:number n}
    (gsub (tostring n) "," ".")
    {:function f} (error (.. "JSON encoding error: don't know how to encode function value: " (tostring f)))
    true "true"
    false "false"
    nil "null"
    _ (escape-string (tostring val))))

(fn skip-space [rdr]
  {:private true}
  ((fn loop []
     (case (rdr:peek 1)
       (where c (c:match "[ \t\n]"))
       (loop (rdr:read 1))))))

(fn parse-num [rdr]
  {:private true}
  ((fn loop [numbers]
     (case (rdr:peek 1)
       (where n (n:match "[-0-9.eE+]"))
       (do (rdr:read 1) (loop (.. numbers n)))
       _ (do (if (and (numbers:match "^%-?0")
                      (numbers:match "^%-?0[^.]"))
                 (error (.. "JSON parse error: invalid number " numbers))
                 (tonumber numbers)))))
   (rdr:read 1)))

(local escapable
  {"\"" "\""
   "'"  "\'"
   "\\" "\\"
   "b"  "\b"
   "f"  "\f"
   "n"  "\n"
   "r"  "\r"
   "t"  "\t"
   "/"  "/"})

(fn parse-string [rdr]
  {:private true}
  (rdr:read 1)
  ((fn loop [chars escaped?]
     (let [ch (rdr:read 1)]
       (case ch
         "\\" (if escaped?
                  (loop (.. chars ch) false)
                  (case (rdr:peek 1)
                    (where c (. escapable c))
                    (loop chars true)
                    (where "u" _G.utf8 (: (or (rdr:peek 5) "") :match "u%x%x%x%x"))
                    (loop (.. chars (_G.utf8.char (tonumber (: (rdr:read 5) :match "u(%x%x%x%x)") 16))))
                    c (error (format "JSON parse error: illegal bacslash escape ('%s' (code %d))" c (c:byte)))))
         "\"" (if escaped?
                  (loop (.. chars ch) false)
                  chars)
         nil (error "JSON parse error: unterminated string")
         (where c (and escaped? (. escapable c)))
         (loop (.. chars (. escapable c)) false)
         _ (loop (.. chars ch) false))))
   "" false))

(fn parse-obj [rdr parse]
  {:private true}
  (rdr:read 1)
  ((fn loop [obj]
     (skip-space rdr)
     (case (rdr:peek 1)
       "}" (do (rdr:read 1) obj)
       _ (let [key (parse)]
           (skip-space rdr)
           (case (rdr:peek 1)
             ":" (let [_ (rdr:read 1)
                       value (parse)]
                   (tset obj key value)
                   (skip-space rdr)
                   (case (rdr:peek 1)
                     "," (do (rdr:read 1)
                             (skip-space rdr)
                             (when (= (rdr:peek 1) "}")
                               (error "JSON parse error: expected a value after a comma"))
                             (loop obj))
                     "}" (do (rdr:read 1) obj)
                     _ (error (.. "JSON parse error: expected ',' or '}' after the value: " (encode value) ", got " _))))
             _ (error (.. "JSON parse error: expected colon after the key: " (encode key) ", got " _))))))
   {}))

(fn parse-arr [rdr parse]
  {:private true}
  (rdr:read 1)
  (var len 0)
  ((fn loop [arr]
     (skip-space rdr)
     (case (rdr:peek 1)
       "]" (do (rdr:read 1) arr)
       _ (let [val (parse)]
           (set len (+ 1 len))
           (tset arr len val)
           (skip-space rdr)
           (case (rdr:peek 1)
             "," (do (rdr:read 1)
                     (skip-space rdr)
                     (when (= (rdr:peek 1) "]")
                       (error "JSON parse error: expected a value after a comma"))
                     (loop arr))
             "]" (do (rdr:read 1) arr)
             _ (error (.. "JSON parse error: expected ',' or ']' after the value: "
                          (encode val) ", got " _))))))
   []))

(fn decode [data]
  "Accepts `data`, which can be either a `Reader` that supports `peek`,
and `read` methods or a string.  Parses the contents to a Lua table."
  (let [rdr (if (reader? data) data
                (string? data) (string-reader data)
                (file? data) (file-reader data)
                (error "expected a reader, or a string as input" 2))
        value ((fn loop []
                 (case (rdr:peek 1)
                   "{" (parse-obj rdr loop)
                   "[" (parse-arr rdr loop)
                   "\"" (parse-string rdr)
                   (where "t" (= "true" (rdr:peek 4))) (do (rdr:read 4) true)
                   (where "f" (= "false" (rdr:peek 5))) (do (rdr:read 5) false)
                   (where "n" (= "null" (rdr:peek 4))) (do (rdr:read 4) nil)
                   (where c (c:match "[ \t\n]")) (loop (skip-space rdr))
                   (where n (n:match "%-") (: (rdr:peek 2) :match "%-[0-9]")) (parse-num rdr)
                   (where n (n:match "[0-9]")) (parse-num rdr)
                   nil (error "JSON parse error: end of stream" 2)
                   c (error (format
                             "JSON parse error: unexpected token ('%s' (code %d))"
                             c (c:byte)) 2))))]
    (skip-space rdr)
    (case (rdr:read 1)
      c (error (format "JSON parse error: extra data after the parsed value ('%s' (code %d))" c (c:byte)) 2))
    value))

(setmetatable
 {: encode : decode}
 {:__call (fn [_ value] (encode value))})
