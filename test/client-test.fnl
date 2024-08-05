(require-macros (doto :lib.fennel-test require))

(local http
  (require :http.client))

(local a
  (require :lib.async))

(fn wait-for-server [attempts port]
  (faccumulate [started? false i 1 attempts :until started?]
    (or (pcall http.head (.. "localhost:" port)
               {:headers {:connection "close"}})
        (a.<!! (a.timeout 30)))))

(fn kill [pid]
  (with-open [_ (io.popen (.. "kill -9 " pid " >/dev/null 2>&1"))]))

(use-fixtures
 :once
 (fn [t]
   (with-open [proc (io.popen "fennel test/server.fnl & echo $!")]
     (let [pid (proc:read :*l)
           attempts 30]
       (if (wait-for-server attempts 8000)
           (do (t)
               (kill pid))
           (io.write "skipping tests after " attempts " failed connection attempts: "))))))

(deftest post-test
  (testing "posting raw data"
    (let [resp (http.post "localhost:8000" {:body "foo"})]
      (assert-eq
       "POST / HTTP/1.1\r\nContent-Length: 3\r\nHost: localhost:8000\r\n\r\nfoo"
       resp.body))))

(deftest chunked-post-test
  (testing "posting chunked data"
    (let [resp (http.post "localhost:8000" {:body (io.open "test/data/valid.json")})]
      (with-open [valid (io.open "test/data/chunked-body")]
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
                                        :content (io.open "test/data/valid.json")}
                                       {:name "bar" :content "bar"}]
                           :headers {:content-type "multipart/form-data; boundary=foobar"}})]
      (with-open [valid (io.open "test/data/multipart")]
        (assert-eq (.. "POST / HTTP/1.1\r\nContent-Length: 1759\r\n"
                       "Content-Type: multipart/form-data; boundary=foobar\r\n"
                       "Host: localhost:8000\r\n\r\n"
                       (valid:read :*a))
                   resp.body)))))
