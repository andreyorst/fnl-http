(local {: lower : gsub : upper} string)

(local {: concat} table)

(fn ->kebab-case [str]
  {:private true}
  (let [[res]
        (accumulate [[res case-change?] ["" false]
                     c (str:gmatch ".")]
          (let [delim? (c:match "[-_ ]")
                upper? (= c (c:upper))]
            (if delim?
                [(.. res "-") nil]
                (and upper? case-change?)
                [(.. res "-" (c:lower)) nil]
                [(.. res (c:lower)) (and (not upper?) true)])))]
    res))

(fn capitalize-header [header]
  "Capitalizes the `header` string."
  (let [header (->kebab-case header)]
    (-> (icollect [word (header:gmatch "[^-]+")]
          (-> word lower (gsub "^%l" upper)))
        (concat "-"))))

(fn decode-value [value]
  "Tries to coerce a `value` to a number, `true, or `false`.
If coersion fails, returns the value as is."
  (case (tonumber value)
    n n
    _ (case value
        "true" true
        "false" false
        _ value)))

(fn get-boundary [headers]
  "Get boundary `fragment` from the `content-type` header.
Accepts the `headers` table."
  {:private true}
  (accumulate [boundary nil
               header value (pairs headers)
               :until boundary]
    (when (= "content-type" (lower header))
      (value:match "boundary=([^;]+)"))))

{: decode-value : capitalize-header : get-boundary}
