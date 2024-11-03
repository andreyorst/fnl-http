(require-macros
 (doto :io.gitlab.andreyorst.fennel-test require))

(local {: skip-test}
  (require :io.gitlab.andreyorst.fennel-test))

(local http
  (require :io.gitlab.andreyorst.fnl-http.client))

(local readers
  (require :io.gitlab.andreyorst.fnl-http.readers))

(local json
  (require :io.gitlab.andreyorst.fnl-http.json))

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
    (with-open [proc (io.popen (.. "fennel"
                                   " --add-fennel-path lib/?.fnl"
                                   " --add-fennel-path src/?.fnl"
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
                {:content "[
    \"JSON Test Pattern pass1\",
    {\"object with 1 member\":[\"array with 1 element\"]},
    {},
    [],
    -42,
    true,
    false,
    null,
    {
        \"integer\": 1234567890,
        \"real\": -9876.543210,
        \"e\": 0.123456789e-12,
        \"E\": 1.234567890E+34,
        \"\":  23456789012E66,
        \"zero\": 0,
        \"one\": 1,
        \"space\": \" \",
        \"quote\": \"\\\"\",
        \"backslash\": \"\\\\\",
        \"controls\": \"\\b\\f\\n\\r\\t\",
        \"slash\": \"/ & /\",
        \"alpha\": \"abcdefghijklmnopqrstuvwyz\",
        \"ALPHA\": \"ABCDEFGHIJKLMNOPQRSTUVWYZ\",
        \"digit\": \"0123456789\",
        \"0123456789\": \"digit\",
        \"special\": \"`1~!@#$%^&*()_+-={':[,]}|;.</>?\",
        \"hex\": \"\\u0123\\u4567\\u89AB\\uCDEF\\uabcd\\uef4A\",
        \"true\": true,
        \"false\": false,
        \"null\": null,
        \"array\":[  ],
        \"object\":{  },
        \"address\": \"50 St. James Street\",
        \"url\": \"http://www.JSON.org/\",
        \"comment\": \"// /* <!-- --\",
        \"# -- --> */\": \" \",
        \" s p a c e d \" :[1,2 , 3

,

4 , 5\t   ,  \t\t        6           ,7        ],\"compact\":[1,2,3,4,5,6,7],
        \"jsontext\": \"{\\\"object with 1 member\\\":[\\\"array with 1 element\\\"]}\",
        \"quotes\": \"&#34; \\u0022 %22 0x22 034 &#x22;\",
        \"/\\\\\\\"\\uCAFE\\uBABE\\uAB98\\uFCDE\\ubcda\\uef4A\\b\\f\\n\\r\\t`1~!@#$%^&*()_+-=[]{}|;:',./<>?\"
: \"A key can be any string\"
    },
    0.5 ,98.6
,
99.44
,

1066,
1e1,
0.1e1,
1e-1,
1e00,2e+00,2e-00
,\"rosebud\"]
"
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
       (require :tests.data.valid)
       (json.decode (. body :parts 2 :content))))))
