(require-macros (doto :lib.fennel-test require))

(local {: decode : encode}
  (require :http.json))

(local readers
  (require :http.readers))

(deftest parse-test
  (testing "parsing from file reader"
    (let [valid (require :test.data.valid)
          parsed (decode (readers.file-reader "test/data/valid.json"))]
      (assert-eq valid parsed)))
  (testing "parsing from string reader"
    (let [valid (require :test.data.valid)
          parsed (decode (: (readers.file-reader "test/data/valid.json") :read :*a))]
      (assert-eq valid parsed)))
  (testing "parsing from string"
    (let [valid {:foo :bar :baz [1 2 3]}
          parsed (decode "{\"foo\": \"bar\", \"baz\": [1, 2, 3], \"qux\": null}")]
      (assert-eq valid parsed))))
