(require-macros (doto :lib.fennel-test require))

(local {: build-http-response
        : encode-chunk
        : prepare-chunk
        : prepare-amount
        : build-http-request}
  (require :http.encoder))

(local {: parse-http-response
        : parse-http-request
        : parse-url}
  (require :http.parser))

(local {: string-reader
        : file-reader}
  (require :http.readers))

(fn select-keys [tbl keys]
  (collect [_ k (ipairs keys)]
    k (. tbl k)))

(deftest http-response-parsing-test
  (testing "http response roundtrip"
    (let [resp (build-http-response 200 "OK" {:connection :close})
          {: body : headers : reason-phrase : status &as parsed}
          (parse-http-response (string-reader resp) {:as :raw})]
      (assert-eq {:body nil
                  :headers {:Connection "close"}
                  :reason-phrase "OK"
                  :protocol-version {:major 1 :minor 1 :name "HTTP"}
                  :status 200}
                 (-> parsed
                     (select-keys
                      [:body :headers :reason-phrase
                       :protocol-version :status])))
      (assert-eq resp (build-http-response status reason-phrase headers body))))
  (testing "http response multi-word reason phrase"
    (let [resp (build-http-response 404 "Not found" {:connection :close})
          parsed (parse-http-response (string-reader resp) {:as :raw})]
      (assert-eq {:body nil
                  :headers {:Connection "close"}
                  :reason-phrase "Not found"
                  :protocol-version {:major 1 :minor 1 :name "HTTP"}
                  :status 404}
                 (-> parsed
                     (select-keys
                      [:body :headers :reason-phrase
                       :protocol-version :status]))))))

(deftest http-request-parsing-test
  (testing "http request roundtrip"
    (let [req (build-http-request :get "/" {:connection :close})
          {: headers : method : path : content}
          (parse-http-request (string-reader req))]
      (assert-eq req (build-http-request method path headers content)))))

(deftest http-response-body-parse-test
  (testing "raw body"
    (let [resp (build-http-response 200 "OK" {} "hello there")
          parsed (parse-http-response (string-reader resp) {:as :raw})]
      (assert-eq "hello there" parsed.body)))
  (testing "json body"
    (let [resp (build-http-response 200 "OK" {} "{\"foo\": \"bar\", \"baz\": [1,2,3]}")
          parsed (parse-http-response (string-reader resp) {:as :json})]
      (assert-eq {:foo "bar" :baz [1 2 3]} parsed.body)))
  (testing "chunked body"
    (with-open [resp (io.open "test/data/chunked" :r)]
      (let [parsed (parse-http-response (string-reader (resp:read :*a)) {:as :raw})]
        (assert-eq "Hello there\nGeneral Kenobi" parsed.body)))))