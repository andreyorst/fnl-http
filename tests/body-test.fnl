(require-macros (doto :io.gitlab.andreyorst.fennel-test require))

(local {: chan : >!! : close! : go : >!
        : chan?}
  (require :io.gitlab.andreyorst.async))

(local {: stream-body
        : format-chunk
        : stream-multipart
        : multipart-content-length
        : wrap-body}
  (require :io.gitlab.andreyorst.fnl-http.body))

(local {: string-reader
        : file-reader
        : reader?}
  (require :io.gitlab.andreyorst.reader))

(fn string-writer []
  (var s "")
  {:write (fn [_ data]
            (set s (.. s data)))
   :string #s})

(deftest wrap-body-test
  (testing "wrapping strings does nothing"
    (assert-eq :string (type (wrap-body "foo"))))
  (testing "wrapping files returns a file reader"
    (with-open [f (io.open "tests/data/valid.json" :r)]
      (assert-is (reader? (wrap-body f)))))
  (testing "wrapping closed files throws an error"
    (->> (with-open [f (io.open "tests/data/valid.json" :r)] f)
         (pcall wrap-body)
         assert-not))
  (testing "wrapping channels returns the same channel"
    (let [ch (chan)]
      (assert-is (chan? (wrap-body ch)))
      (assert-eq ch (wrap-body ch))))
  (testing "wrapping readers returns the same reader"
    (let [r (string-reader "foo")]
      (assert-is (reader? (wrap-body r)))
      (assert-eq r (wrap-body r))))
  (testing "wrapping tables returns the json reader"
    (let [t {:foo "bar"}]
      (assert-is (reader? (wrap-body t :application/json)))
      (assert-eq "{\"foo\": \"bar\"}" (: (wrap-body t :application/json) :read :*a)))))

(deftest format-chunk-test
  (testing "formatting chunk from file"
    (with-open [data (io.open "tests/data/valid.json" :r)
                valid (io.open "tests/data/chunked-body" :r)]
      (let [r (file-reader data)
            (last? chunk) (format-chunk r)]
        (assert-not last?)
        (assert-eq (valid:read 1031) chunk))))
  (testing "formatting chunk from channel"
    (with-open [valid (io.open "tests/data/chunked-body" :r)]
      (let [ch (chan)
            _ (go #(with-open [body (io.open "tests/data/valid.json" :r)]
                     (each [line (body:lines)]
                       (>! ch (.. line "\n")))
                     (close! ch)))
            (last? chunk) (format-chunk ch)]
        (assert-not last?)
        (assert-eq "2\r\n[\n\r\n" chunk)))))

(deftest stream-body-test
  (testing "streaming-body from string reader"
    (let [sw (string-writer)]
      (stream-body sw (string-reader "foobar") {:content-length 6})
      (assert-eq "foobar" (sw:string))))
  (testing "streaming-body from file reader"
    (with-open [r (file-reader "tests/data/valid.json")
                valid (io.open "tests/data/valid.json" :r)]
      (let [len (r:length)
            sw (string-writer)]
        (stream-body sw r {:content-length len})
        (assert-eq (valid:read :*a) (sw:string)))))
  (testing "chunked encoding from file"
    (with-open [r (file-reader "tests/data/valid.json")
                valid (io.open "tests/data/chunked-body" :r)]
      (let [sw (string-writer)]
        (stream-body sw r {:transfer-encoding "chunked"})
        (assert-eq (valid:read :*a) (sw:string)))))
  (testing "chunked encoding from channel"
    (with-open [data (io.open "tests/data/valid.json" :r)
                valid (io.open "tests/data/chunked-channel-body" :r)]
      (let [sw (string-writer)
            ch (chan)]
        (go #(with-open [body (io.open "tests/data/valid.json" :r)]
               (each [line (body:lines)]
                 (>! ch (.. line "\n")))
               (close! ch)))
        (stream-body sw ch {:transfer-encoding "chunked"})
        (assert-eq (valid:read :*a) (sw:string))))))

(deftest multipart-content-length-test
  (testing "multipart with no data"
    (assert-eq 12 (multipart-content-length [] "foobar")))
  (testing "multipart with string data"
    (assert-eq
     166
     (multipart-content-length [{:name "foo" :content "foo"}] "foobar"))
    (assert-eq
     320
     (multipart-content-length
      [{:name "foo" :content "foo"}
       {:name "bar" :content "bar"}]
      "foobar")))
  (testing "multipart with file data"
    (assert-eq
     nil
     (multipart-content-length
      [{:name "foo"
        :content (io.open "tests/data/valid.json")}]
      "foobar"))
    (assert-eq
     nil
     (multipart-content-length
      [{:name "foo"
        :content (io.open "tests/data/valid.fnl")}
       {:name "bar" :filename "valid.fnl"
        :content (io.open "tests/data/valid.fnl")}]
      "foobar"))
    (assert-eq
     nil
     (multipart-content-length
      [{:name "foo"
        :content (io.open "tests/data/valid.fnl")}
       {:name "bar" :filename* "valid file.fnl"
        :content (io.open "tests/data/valid.fnl")}]
      "foobar"))
    (assert-eq
     nil
     (multipart-content-length
      [{:name "foo"
        :content (io.open "tests/data/valid.fnl")}
       {:name "bar"
        :filename "valid file.fnl"
        :filename* "valid file.fnl"
        :content (io.open "tests/data/valid.fnl")}]
      "foobar")))
  (testing "multipart with channel data"
    (let [make-chan #(doto (chan 3)
                       (>!! "foo")
                       (>!! "bar")
                       (>!! "baz")
                       close!)]
      (let [ch (make-chan)]
        (assert-eq
         173
         (multipart-content-length
          [{:name "foo"
            :content ch
            :length 9}]
          "foobar")))
      (let [ch (make-chan)]
        (assert-eq
         170
         (multipart-content-length
          [{:name "foo"
            :content ch
            :length 6}]
          "foobar")))))
  (testing "multipart with mixed data"
    (assert-eq
     nil
     (multipart-content-length
      [{:name "foo"
        :content (io.open "tests/data/valid.json")}
       {:name "bar" :content "bar"}]
      "foobar"))))

(deftest multipart-stream-test
  (testing "streaming multipart from file and raw data"
    (with-open [valid (io.open "tests/data/multipart" :r)]
      (let [sw (string-writer)
            data (valid:read :*a)]
        (stream-multipart
         sw
         [{:name "foo"
           :content (io.open "tests/data/valid.json")
           :length (with-open [f (io.open "tests/data/valid.json")]
                     (f:seek :end))}
          {:name "bar" :content "bar"}]
         "foobar")
        (assert-eq data (sw:string))
        (assert-eq (length data) (length (sw:string))))))
  (testing "streaming multipart from channel and raw data"
    (with-open [valid (io.open "tests/data/multipart" :r)]
      (let [sw (string-writer)
            data (valid:read :*a)
            ch (chan)]
        (go #(with-open [body (io.open "tests/data/valid.json" :r)]
               (each [line (body:lines)]
                 (>! ch (.. line "\n")))
               (close! ch)))
        (stream-multipart
         sw
         [{:name "foo"
           :content ch
           :length (with-open [body (io.open "tests/data/valid.json" :r)] (body:seek :end))}
          {:name "bar" :content "bar"}]
         "foobar")
        (assert-eq (length data) (length (sw:string)))
        (assert-eq data (sw:string))))))
