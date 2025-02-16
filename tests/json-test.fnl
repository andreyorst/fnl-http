(require-macros (doto :io.gitlab.andreyorst.fennel-test require))

(local {: skip-test}
  (require :io.gitlab.andreyorst.fennel-test))

(local {: decode : encode : register-encoder : unregister-encoder}
  (require :io.gitlab.andreyorst.json))

(local body
  (require :io.gitlab.andreyorst.fnl-http.body))

(deftest parse-body-test
  (when (not _G.utf8)
    (skip-test "no utf8 module found"))
  (testing "parsing from body reader"
    (with-open [valid (io.open "tests/data/valid.json")]
      (assert-eq (require :data.valid)
                 (decode (body.body-reader valid)))))
  (testing "parsing from chunked body reader"
    (with-open [chunked (io.open "tests/data/chunked-body")]
      (assert-eq (require :data.valid)
                 (decode (body.chunked-body-reader chunked))))))
