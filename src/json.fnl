(local reader
  (require :reader))

(local null "null")

(fn string? [val]
  (and (= :string (type val))
       {:string val}))

(fn number? [val]
  (and (= :number (type val))
       {:number val}))

(fn object? [val]
  (and (= :table (type val))
       {:object val}))

(fn array? [val ?max]
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
  (and (= :function (type val))
       {:function val}))

(fn guess [val]
  (or (array? val)
      (object? val)
      (string? val)
      (number? val)
      val))

(fn escape-string [str]
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

(fn json [val]
  "Encode a Lua value `val` as JSON."
  (case (guess val)
    {:array array :n n}
    (.. "[" (-> (fcollect [i 1 n]
                  (json (. array i)))
                (table.concat ", ")) "]")
    {:object object}
    (.. "{" (-> (icollect [k v (pairs object)]
                  (.. (json k) ": " (json v)))
                (table.concat ", ")) "}")
    {:string s}
    (escape-string s)
    {:number n}
    (string.gsub (tostring n) "," ".")
    nil null
    _ (escape-string (tostring val))))

(fn skip-space [rdr]
  ((fn loop []
     (case (rdr:peek 1)
       (where c (c:match "[ \t\n]"))
       (loop (rdr:read 1))))))

(fn parse-num [rdr]
  ((fn loop [numbers]
     (case (rdr:peek 1)
       (where n (n:match "[-0-9.eE+]"))
       (do (rdr:read 1) (loop (.. numbers n)))
       _ (tonumber numbers)))
   (rdr:read 1)))

(fn parse-string [rdr]
  (rdr:read 1)
  ((fn loop [chars escaped?]
     (case (rdr:read 1)
       "\\" (loop chars (not escaped?))
       "\"" (if escaped?
                (loop (.. chars "\"") false)
                chars)
       _ (loop (.. chars _) false)
       ))
   "" false))

(fn parse-obj [rdr parse]
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
                     "," (do (rdr:read 1) (loop obj))
                     "}" (do (rdr:read 1) obj)
                     _ (error (.. "expected ',' or '}' after the value " (json value)))))
             _ (error (.. "expected colon after the key " (json key)))))))
   {}))

(fn parse-arr [rdr parse]
  (rdr:read 1)
  ((fn loop [arr]
     (skip-space rdr)
     (case (rdr:peek 1)
       "]" (do (rdr:read 1) arr)
       _ (let [val (parse)]
           (tset arr (+ 1 (length arr)) val)
           (skip-space rdr)
           (case (rdr:peek 1)
             "," (do (rdr:read 1) (loop arr))
             "]" (do (rdr:read 1) arr)
             _ (error (.. "expected ',' or ']' after the value " (json val)))))))
   []))

(fn parse [rdr]
  "Accepts a reader object `rdr`, that supports `peek`, and `read`
methods.  Parses the contents to a Lua table."
  ((fn loop []
     (case (rdr:peek 1)
       "{" (parse-obj rdr loop)
       "[" (parse-arr rdr loop)
       "\"" (parse-string rdr)
       (where "t" (= "true" (rdr:peek 4))) (do (rdr:read 4) true)
       (where "f" (= "false" (rdr:peek 5))) (do (rdr:read 5) false)
       (where "n" (= "null" (rdr:peek 4))) (do (rdr:read 4) nil)
       (where c (c:match "[ \t\n]")) (loop (skip-space rdr))
       (where n (n:match "[-0-9]")) (parse-num rdr)
       _ (error (.. "unexpected token '" (tostring _) "'"))))))

{: json
 : parse}
