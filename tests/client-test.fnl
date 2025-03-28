(require-macros :io.gitlab.andreyorst.fennel-test)

(local {: skip-test}
  (require :io.gitlab.andreyorst.fennel-test))

(local http
  (require :io.gitlab.andreyorst.fnl-http.client))

(local a
  (require :io.gitlab.andreyorst.async))

(fn wait-for-server [attempts port]
  (faccumulate [started? false _ 1 attempts :until started?]
    (or (pcall http.head (.. "localhost:" port)
               {:headers {:connection "close"}})
        (a.<!! (a.timeout 100)))))

(fn kill [pid]
  (with-open [_ (io.popen (.. "kill -9 " pid " >/dev/null 2>&1"))]))

(use-fixtures
    :once
  (fn [t]
    (with-open [proc (io.popen (.. "deps"
                                   " tests/data/echo-server.fnl"
                                   " & echo $!"))]
      (let [pid (proc:read :*l)
            attempts 100]
        (if (wait-for-server attempts 8000)
            (do (t)
                (kill pid))
            (do (kill pid)
                (skip-test (.. "coudln't connect to echo server after " attempts " attempts") false)))))))

(deftest post-test
  (testing "posting raw data"
    (let [resp (http.post "localhost:8000" {:body "foo"})]
      (assert-eq
       "POST / HTTP/1.1\r\nContent-Length: 3\r\nHost: localhost:8000\r\n\r\nfoo"
       resp.body))))

(deftest chunked-post-test
  (testing "posting chunked data"
    (let [resp (http.post "localhost:8000" {:body (io.open "tests/data/valid.json")})]
      (with-open [valid (io.open "tests/data/chunked-body")]
        (assert-eq
         (.. "POST / HTTP/1.1\r\n"
             "Host: localhost:8000\r\n"
             "Transfer-Encoding: chunked\r\n"
             "\r\n"
             (valid:read :*a))
         resp.body)))))

(deftest multipart-post-test
  (testing "posting multipart data"
    (let [resp (http.post "localhost:8000"
                          {:multipart [{:name "foo"
                                        :content (io.open "tests/data/valid.json")
                                        :length (with-open [f (io.open "tests/data/valid.json")] (f:seek :end))}
                                       {:name "bar" :content "bar"}]
                           :headers {:content-type "multipart/form-data; boundary=foobar"}})]
      (with-open [valid (io.open "tests/data/multipart")]
        (assert-eq (.. "POST / HTTP/1.1\r\nContent-Length: 1759\r\n"
                       "Content-Type: multipart/form-data; boundary=foobar\r\n"
                       "Host: localhost:8000\r\n\r\n"
                       (valid:read :*a))
                   resp.body))))
  (testing "posting chunked multipart data"
    (let [resp (http.post "localhost:8000"
                          {:multipart [{:name "foo"
                                        :content (io.open "tests/data/valid.json")}
                                       {:name "bar" :content "bar"}]
                           :headers {:content-type "multipart/form-data; boundary=foobar"}})]
      (with-open [valid (io.open "tests/data/chunked-multipart")]
        (assert-eq (valid:read :*a) resp.body)))))

(deftest query-parameters-test
  (testing "query params appear in the target path"
    (assert-eq
     "POST /?a=1&b=2 HTTP/1.1\r\nHost: localhost:8000\r\n\r\n"
     (-> "localhost:8000"
         (http.post {:query-params {:a "1" :b "2"}})
         (. :body)))
    (assert-eq
     "POST /?a=1&b=2&c=3 HTTP/1.1\r\nHost: localhost:8000\r\n\r\n"
     (-> "localhost:8000?a=1"
         (http.post {:query-params {:b "2" :c "3"}})
         (. :body)))
    (assert-eq
     "POST /?a=1&a=2&c=3 HTTP/1.1\r\nHost: localhost:8000\r\n\r\n"
     (-> "localhost:8000?a=1"
         (http.post {:query-params {:a "2" :c "3"}})
         (. :body)))
    (assert-eq
     "POST /?a=1&a=2&a=3 HTTP/1.1\r\nHost: localhost:8000\r\n\r\n"
     (-> "localhost:8000?a=1"
         (http.post {:query-params {:a ["2" "3"]}})
         (. :body)))))
