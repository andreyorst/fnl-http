(require-macros
 (doto :io.gitlab.andreyorst.fennel-test require))

(local {: skip-test}
  (require :io.gitlab.andreyorst.fennel-test))

(local http
  (require :io.gitlab.andreyorst.fnl-http.client))

(local body
  (require :io.gitlab.andreyorst.fnl-http.body))

(local parser
  (require :io.gitlab.andreyorst.fnl-http.parser))

(local readers
  (require :io.gitlab.andreyorst.reader))

(local json
  (require :io.gitlab.andreyorst.json))

(local a
  (require :io.gitlab.andreyorst.async))

(fn url [path]
  (.. "http://localhost:8002" (or path "")))

(fn wait-for-server [attempts]
  (faccumulate [started? false i 1 attempts :until started?]
    (or (pcall http.head (url)
               {:headers {:connection "close"}})
        (a.<!! (a.timeout 100)))))

(fn kill [pid]
  (with-open [_ (io.popen (.. "kill -9 " pid " >/dev/null 2>&1"))]))

(use-fixtures
    :once
  (fn [t]
    (with-open [proc (io.popen (.. "deps"
                                   " tests/data/server.fnl"
                                   " & echo $!"))]
      (let [pid (proc:read :*l)
            attempts 100]
        (if (wait-for-server attempts 8000)
            (do (t)
                (kill pid))
            (do (kill pid)
                (skip-test (.. "coudln't connect to echo server after " attempts " attempts") false)))))))

(deftest get-test
  (testing "simple GET"
    (assert-eq
     {:headers {:Host "localhost:8002"}
      :method "GET"
      :path "/"
      :protocol-version {:major 1 :minor 1 :name "HTTP"}}
     (-> (url)
         (http.get {:as :json})
         (. :body)))))

(deftest post-test
  (testing "POST string"
    (assert-eq
     {:content "vaiv"
      :headers {:Content-Length "4" :Host "localhost:8002"}
      :length 4
      :method "POST"
      :path "/"
      :protocol-version {:major 1 :minor 1 :name "HTTP"}}
     (-> (url)
         (http.post {:body "vaiv" :as :json})
         (. :body))))
  (testing "POST file"
    (assert-eq
     {:content "vaiv\n"
      :headers {:Content-Length "5" :Host "localhost:8002"}
      :length 5
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :method "POST"
      :path "/"}
     (-> (url)
         (http.post {:body (readers.file-reader "tests/data/sample") :as :json})
         (. :body)))))

(deftest multipart-post-test
  (when (not _G.utf8)
    (skip-test "no utf8 module found"))
  (testing "POST multipart chunked"
    (let [{: body} (http.post
                    (url)
                    {:multipart [{:name "daun" :content "kuku"}
                                 {:filename "valid.json" :name "valid"
                                  :content (io.open "tests/data/valid.json")}]
                     :headers {:content-type "multipart/form-data; boundary=foobar"}
                     :as :json
                     :throw-errors? false})]
      (assert-eq
       {:headers {:Content-Type "multipart/form-data; boundary=foobar" :Host "localhost:8002"}
        :method "POST"
        :parts [{:content "kuku"
                 :headers {:Content-Disposition "form-data; name=\"daun\""
                           :Content-Length "4"
                           :Content-Transfer-Encoding "8bit"
                           :Content-Type "text/plain; charset=UTF-8"}
                 :length 4
                 :name "daun"
                 :type "form-data"}
                {:content (with-open [f (io.open "tests/data/valid.json")] (f:read :*a))
                 :filename "valid.json"
                 :headers {:Content-Disposition "form-data; name=\"valid\"; filename=\"valid.json\""
                           :Content-Transfer-Encoding "binary"
                           :Content-Type "application/octet-stream"
                           :Transfer-Encoding "chunked"}
                 :name "valid"
                 :type "form-data"}]
        :path "/"
        :protocol-version {:major 1 :minor 1 :name "HTTP"}}
       body)
      (assert-eq
       (require :data.valid)
       (json.decode (. body :parts 2 :content))))))

(deftest multipart-get-test
  (testing "GET multipart"
    (assert-eq
     {:headers {:Connection "keep-alive"
                :Content-Length "1759"
                :Content-Type "multipart/form-data; boundary=foobar"}
      :length 1759
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :reason-phrase "OK"
      :status 200
      :trace-redirects {}
      :body (with-open [f (io.open "tests/data/multipart")]
              (f:read :*a))}
     (doto (http.get (url "/multipart") {:as :raw :throw-errors? false})
       (tset :http-client nil)
       (tset :request-time nil))))
  (testing "GET chunked multipart"
    (assert-eq
     {:headers {:Connection "keep-alive"
                :Content-Type "multipart/form-data; boundary=foobar"}
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :reason-phrase "OK"
      :status 200
      :trace-redirects {}
      :body (with-open [f (io.open "tests/data/chunked-multipart")]
              (let [data (f:read :*a)]
                (data:sub 94 (length data))))}
     (doto (http.get (url "/chunked-multipart") {:as :raw :throw-errors? false})
       (tset :http-client nil)
       (tset :request-time nil)))))

(deftest multipart-iterator-test
  (testing "iterating over parts"
    (let [parts (body.multipart-body-iterator (readers.file-reader "tests/data/chunked-multipart") "foobar" parser.read-headers)]
      (each [{: name : content : headers} parts]
        (case name
          "foo" (do (assert-eq {:Content-Disposition "form-data; name=\"foo\"\r"
                                :Content-Transfer-Encoding "binary\r"
                                :Content-Type "application/octet-stream\r"
                                :Transfer-Encoding "chunked\r"}
                               headers)
                    (assert-eq
                     (with-open [f (io.open "tests/data/valid.json")]
                       (f:read :*a))
                     (content:read :*a)))
          "bar" (assert-eq "bar" (content:read :*a))))))
  (testing "closing part reader while iterating"
    (let [parts (body.multipart-body-iterator (readers.file-reader "tests/data/chunked-multipart") "foobar" parser.read-headers)]
      (each [{: name : content : headers} parts]
        (case name
          "foo" (do (content:close)
                    (assert-eq nil (content:read :*a)))
          "bar" (assert-eq "bar" (content:read :*a))))))
  (testing "skipping part while iterating"
    (let [parts (body.multipart-body-iterator (readers.file-reader "tests/data/chunked-multipart") "foobar" parser.read-headers)]
      (each [{: name : content : headers} parts]
        (case name
          "foo" nil
          "bar" (assert-eq "bar" (content:read :*a)))))))
