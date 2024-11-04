(local {: reader?
        : string-reader
        : file-reader
        : make-reader}
  (require :io.gitlab.andreyorst.fnl-http.readers))

(local {: file?}
  (require :io.gitlab.andreyorst.fnl-http.utils))

(local {: concat} table)

(local {: gsub : format} string)

;; Lua -> JSON Encoder

(fn string? [val]
  {:private true}
  (and (= :string (type val))
       :string))

(fn encode-string [str _]
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

(fn object? [val]
  {:private true}
  (and (= :table (type val))
       :object))

(fn encode-object [object encode]
  {:private true}
  (.. "{" (-> (icollect [k v (pairs object)]
                (.. (encode k) ": " (encode v)))
              (concat ", ")) "}"))

(fn array? [val ?max]
  {:private true}
  (and (object? val)
       (case (length val)
         0 false
         len (let [max (or ?max len)]
               (case ((pairs val) val max)
                 (where k (= :number (type k)))
                 (array? val k)
                 nil :array
                 _ false)))))

(fn max-n [val ?max]
  {:private true}
  (let [max (or ?max (length val))]
    (case ((pairs val) val max)
      n (max-n val n)
      nil max)))

(fn encode-array [array encode]
  {:private true}
  (.. "[" (-> (fcollect [i 1 (max-n array)]
                (encode (. array i)))
              (concat ", ")) "]"))

(fn number? [val]
  {:private true}
  (and (= :number (type val))
       :number))

(fn encode-number [n]
  {:private true}
  (gsub (tostring n) "," "."))

(fn function? [val]
  {:private true}
  (and (= :function (type val))
       :function))

(fn encode-function [f]
  {:private true}
  (error (.. "JSON encoding error: don't know how to encode function value: " (tostring f)) 2))

(fn boolean? [val]
  (and (= :boolean (type val))
       :boolean))

(fn encode-boolean [b]
  {:private true}
  (if b "true" "false"))

(fn nil? [val]
  (and (= :nil (type val))
       :nil))

(fn encode-nil [_]
  {:private true}
  "null")

(local encoders
  (setmetatable
   {}
   {:__index
    {:array encode-array
     :object encode-object
     :string encode-string
     :number encode-number
     :function encode-function
     :boolean encode-boolean
     :nil encode-nil}}))

(local default-encoders
  [array? object? string? number? function? boolean? nil?])

(local custom-encoders
  [])

(fn register-encoder [object object? object-encoder]
  "Add custom `object` encoder.

If there's a custom object that is not supported by JSON encoder, the
`object-encoder` function can be registered to it via the `object?`
checker.  The `object?` is a function that, given an `object`, will
return a unique identifier for that `object`.  The identifier must be
a singleton, to ensure its uniquess across different data types.

The `object-encoder` is a function of two arguments.  The first
argument is the `object` itself, and the second argument is the
`encode` function, that is passed automatically, and can be used to
encode nested values.

# Examples

For example, proxy objects have a problem that they usually wrap an
empty table with custom metatable that deals with data access.  The
JSON encoder can distinguish between objects and arrays based on
special hueristics, but given a proxy object it can break.

For example, let's create a zero-indexed array:

```fennel :skip-test
(local Array {})

(fn zero-indexed-array [...]
  (let [vals [...]]
    (setmetatable
     []
     {:__index (fn [_ i]
                 (. vals (+ i 1)))
      :__newindex (fn [i val]
                    (tset vals (- i 1) val))
      :__len #(length vals)
      :__pairs (fn [_] #(next vals $2))
      :__type Array})))
```

Omitting the rest of metatable machinery, we now have a custom object
that behaves as an array.  However, encoding it as JSON yields an
incorrect result:

```fennel :skip-test
(encode (zero-indexed-array 1 2 3))
\"[2, 3, null]\"
```

A custom encoder can be provided to fix that:

```fennel :skip-test
(fn array? [x]
  (case (getmetatable x)
    {:__type Array} Array
    _ false))

(fn encode-array [arr encode]
  (.. \"[\"
      (-> (fcollect [i 0 (- (length arr) 1)]
            (encode (. arr i)))
          (table.concat \", \"))
      \"]\"))

(json.register-encoder (zero-indexed-array) array? encode-array)
```

Note that `encode-array` accepts `encode` function and calls it on
array elements:

```fennel :skip-test
>> (json (zero-indexed-array 1 2 3))
\"[1, 2, 3]\"
```

This should provide enough flexibility to support arbitrary proxy
objects."
  (let [type* (object? object)]
    (assert (= nil (. encoders type*))
            (string.format "encoder for %s is already registered" (tostring type*)))
    (assert (= :table (type type*)))
    (tset encoders type* object-encoder)
    (table.insert custom-encoders 1 object?)))

(fn unregister-encoder [object object?]
  "Remove an `object` encoder defined with `register-encoder`.
Uses `object?` to find encoder to remove."
  (case (accumulate [n nil i designator (ipairs custom-encoders)
                     :until n]
          (when (= object? designator)
            i))
    n (do (table.remove custom-encoders n)
          (tset encoders (object? object) nil)
          true)))

(fn get-encoder [designators val]
  {:private true}
  (accumulate [encoder nil
               _ type* (ipairs designators)
               :until encoder]
    (. encoders (type* val))))

(fn encode [val]
  "Encode a Lua value `val` as JSON."
  (case (or (get-encoder custom-encoders val)
            (get-encoder default-encoders val))
    encoder (encoder val encode)
    nil (error (.. "no encoder for value " (tostring val)))))

;; Parser

(fn skip-space [rdr]
  {:private true}
  ((fn loop []
     (case (rdr:peek 1)
       (where c (c:match "[ \t\n]"))
       (loop (rdr:read 1))))))

(fn decode-num [rdr]
  {:private true}
  ((fn loop [numbers]
     (case (rdr:peek 1)
       (where n (n:match "[-0-9.eE+]"))
       (do (rdr:read 1) (loop (.. numbers n)))
       _ (or (and (numbers:match "^%-?0")
                  (numbers:match "^%-?0[^.e]")
                  (error (.. "JSON parse error: invalid number " numbers)))
             (and (or (numbers:match "%.e")
                      (numbers:match "%.$"))
                  (error (.. "JSON parse error: invalid number " numbers)))
             (tonumber numbers)
             (error (.. "JSON parse error: invalid number " numbers)))))
   (rdr:read 1)))

(local ctrl-characters
  (faccumulate [res {}
                i 0 31]
    (doto res (tset (string.char i) true))))

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

(fn decode-string [rdr]
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
                    (where "u" (= nil _G.utf8))
                    (error "JSON parse error: unable to parse Unicode escape sequence - utf8 module is unavailable")
                    c (error (format "JSON parse error: illegal bacslash escape ('%s' (code %d))" c (c:byte)))))
         "\"" (if escaped?
                  (loop (.. chars ch) false)
                  chars)
         nil (error "JSON parse error: unterminated string")
         (where c (and escaped? (. escapable c)))
         (loop (.. chars (. escapable c)) false)
         (where c (. ctrl-characters c))
         (error (format "JSON parse error: unescaped control character ('%s' (code %d))" c (c:byte)))
         _ (loop (.. chars ch) false))))
   "" false))

(fn decode-obj [rdr decode]
  {:private true}
  (rdr:read 1)
  ((fn loop [obj]
     (skip-space rdr)
     (case (rdr:peek 1)
       "}" (do (rdr:read 1) obj)
       "\"" (let [key (decode rdr)]
              (skip-space rdr)
              (case (rdr:peek 1)
                ":" (let [_ (rdr:read 1)
                          value (decode rdr)]
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
                _ (error (.. "JSON parse error: expected colon after the key: " (encode key) ", got " _))))
       _ (error "JSON parse error: expected a string key")))
   {}))

(fn decode-arr [rdr decode]
  {:private true}
  (rdr:read 1)
  (var len 0)
  ((fn loop [arr]
     (skip-space rdr)
     (case (rdr:peek 1)
       "]" (do (rdr:read 1) arr)
       _ (let [val (decode rdr)]
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

(fn decode* [rdr]
  (case (rdr:peek 1)
    "{" (decode-obj rdr decode*)
    "[" (decode-arr rdr decode*)
    "\"" (decode-string rdr)
    (where "t" (= "true" (rdr:peek 4))) (do (rdr:read 4) true)
    (where "f" (= "false" (rdr:peek 5))) (do (rdr:read 5) false)
    (where "n" (= "null" (rdr:peek 4))) (do (rdr:read 4) nil)
    (where c (c:match "[ \t\n]")) (decode* (doto rdr skip-space))
    (where n (n:match "%-") (: (rdr:peek 2) :match "%-[0-9]")) (decode-num rdr)
    (where n (n:match "[0-9]")) (decode-num rdr)
    nil (error "JSON parse error: end of stream" 2)
    c (error (format
              "JSON parse error: unexpected token ('%s' (code %d))"
              c (c:byte)) 2)))

(fn decode [data]
  "Accepts `data`, which can be either a `Reader` that supports `peek`,
and `read` methods, a string, or a file handle.  Parses the first
logical JSON value to a Lua value."
  (let [rdr (if (reader? data) data
                (string? data) (string-reader data)
                (file? data) (file-reader data)
                (error "expected a reader, or a string as input" 2))]
    (decode* rdr)))

(setmetatable
 {: encode : decode : register-encoder : unregister-encoder}
 {:__call (fn [_ value] (encode value))})
