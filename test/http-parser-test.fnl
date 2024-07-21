(require-macros (doto :lib.fennel-test require))

(local {: build-http-response
        : encode-chunk
        : prepare-chunk
        : prepare-amount
        : build-http-request}
  (require :src.http-encoding))

(local {: parse-http-response
        : parse-http-request
        : parse-url}
  (require :src.http-parser))

(local {: string-reader}
  (require :src.readers))

(deftest http-response-parsing-test
  (testing "http response roundtrip"
    (let [req (build-http-response 200 "OK" {:connection :close} "vaiv\ndaun\n")
          rdr (string-reader req)
          {: body : headers : reason-phrase : status}
          (parse-http-response rdr {:as :raw})]
      (assert-eq req (build-http-response status reason-phrase headers body)))))

(deftest http-request-parsing-test
  (testing "http request roundtrip"
    (let [req (build-http-request :get "/" {:connection :close} "vaiv\ndaun\n")
          rdr (string-reader req)
          {: headers : method : path : content}
          (parse-http-request rdr)]
      (assert-eq req (build-http-request method path headers content)))))
