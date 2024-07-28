(require-macros (doto :lib.fennel-test require))

(local http
  (require :http))

(local a
  (require :lib.async))

(use-fixtures
 :each
 (fn [t]
   (with-open [_proc (io.popen "nc -w 1 -l localhost 8000 > test/data/resp")]
     (a.<!! (a.timeout 100))
     (t)
     (: (io.popen "rm -rf test/data/resp") :close))))

(when (: (io.popen "nc -h > /dev/null 2>&1") :close)

(deftest post-test
  (testing "posting raw data"
    (pcall http.post "localhost:8000" {:body "foo"})
    (with-open [resp (io.open "test/data/resp")]
      (assert-eq
       "POST / HTTP/1.1\r\nContent-Length: 3\r\nHost: localhost:8000\r\n\r\nfoo"
       (resp:read :*a)))))

(deftest chunked-post-test
  (testing "posting chunked data"
    (pcall http.post "localhost:8000" {:body (io.open "test/data/valid.json")})
    (with-open [resp (io.open "test/data/resp")
                valid (io.open "test/data/chunked-body")]
      (assert-eq
       (.. "POST / HTTP/1.1\r\n"
           "Host: localhost:8000\r\n"
           "Transfer-Encoding: chunked\r\n"
           "\r\n"
           (valid:read :*a))
       (resp:read :*a)))))

(deftest multipart-post-test
  (testing "posting multipart data"
    (pcall http.post "localhost:8000"
           {:multipart [{:name "foo"
                         :content (io.open "test/data/valid.json")}
                        {:name "bar" :content "bar"}]
            :headers {:content-type "multipart/form-data; boundary=foobar"}})
    (with-open [resp (io.open "test/data/resp")
                valid (io.open "test/data/multipart")]
      (assert-eq (.. "POST / HTTP/1.1\r\nContent-Length: 1759\r\n"
                     "Content-Type: multipart/form-data; boundary=foobar\r\n"
                     "Host: localhost:8000\r\n\r\n"
                     (valid:read :*a)) (resp:read :*a)))))

  )
