(require-macros (doto :lib.fennel-test require))

(local {: skip-test}
  (require :lib.fennel-test))

(local {: decode : encode}
  (require :http.json))

(local readers
  (require :http.readers))

(local body
  (require :http.body))

(deftest parse-test
  (testing "parsing from string"
    (assert-eq {:foo :bar :baz [1 2 3]}
               (decode "{\"foo\": \"bar\", \"baz\": [1, 2, 3], \"qux\": null}"))))

(deftest parse-reader-test
  (when (not _G.utf8)
    (skip-test "no utf8 module found"))
  (testing "parsing from file reader"
    (assert-eq (require :test.data.valid)
               (decode (readers.file-reader "test/data/valid.json"))))
  (testing "parsing from string reader"
    (assert-eq (require :test.data.valid)
               (decode (: (readers.file-reader "test/data/valid.json") :read :*a)))))

(deftest parse-body-test
  (when (not _G.utf8)
    (skip-test "no utf8 module found"))
  (testing "parsing from body reader"
    (with-open [valid (io.open "test/data/valid.json")]
      (assert-eq (require :test.data.valid)
                 (decode (body.body-reader valid)))))
  (testing "parsing from chunked body reader"
    (with-open [chunked (io.open "test/data/chunked-body")]
      (assert-eq (require :test.data.valid)
                 (decode (body.chunked-body-reader chunked))))))
