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
                [(.. res (c:lower)) (and (not upper?) true)])))]
    res))

(fn capitalize-header [header]
  "Capitalizes the header string."
  (let [header (->kebab-case header)]
    (-> (icollect [word (header:gmatch "[^-]+")]
          (-> word
              string.lower
              (string.gsub "^%l" string.upper)))
        (table.concat "-"))))

(fn decode-value [value]
  "Tries to coerce a `value` to a number, `true, or `false`.
If coersion fails, returns the value as is."
  (case (tonumber value)
    n n
    _ (case value
        "true" true
        "false" false
        _ value)))

{: decode-value
 : capitalize-header}
