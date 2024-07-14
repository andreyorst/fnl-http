(fn ->kebab-case [str]
  (let [[res]
        (accumulate [[res case-change?] ["" false]
                     c (string.gmatch str ".")]
          (let [delim? (c:match "[-_ ]")
                upper? (= c (c:upper))]
            (if delim?
                [(.. res "-") nil]
                (and upper? case-change?)
                [(.. res "-" (c:lower)) nil]
                [(.. res c) true])))]
    res))

(fn capitalize-header [header]
  "Capitalizes the header string."
  (let [header (->kebab-case header)]
    (-> (icollect [word (header:gmatch "[^-]+")]
          (-> word
              string.lower
              (string.gsub "^%l" string.upper)))
        (table.concat "-"))))

(fn as-data [value]
  "Tries to coerce a `value` to a number, `true, or `false`.
If coersion fails, returns the value as is."
  (case (tonumber value)
    n n
    _ (case value
        "true" true
        "false" false
        _ value)))

(fn format-path [{: path : query : fragment}]
  "Formats the PATH component of a HTTP `Path` header.
Accepts the `path`, `query`, and `fragment` parts from the parsed URL."
  (.. "/" (or path "") (if query (.. "?" query) "") (if fragment (.. "?" fragment) "")))

{: format-path
 : as-data
 : capitalize-header}
