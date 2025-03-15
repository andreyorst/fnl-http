(require-macros :io.gitlab.andreyorst.fennel-test)

(local {: capitalize-header}
  (require :io.gitlab.andreyorst.fnl-http.impl.headers))

(deftest capitalize-header-test
  (testing "different separators"
    (assert-eq "Foo-Bar" (capitalize-header "foo-bar"))
    (assert-eq "Foo-Bar" (capitalize-header "Foo-Bar"))
    (assert-eq "Foo-Bar" (capitalize-header "foo_bar"))
    (assert-eq "Foo-Bar" (capitalize-header "foo bar"))
    (assert-eq "Foo-Bar" (capitalize-header "fooBar"))
    (assert-eq "Foo-Bar" (capitalize-header "FooBar"))
    (assert-eq "Foo-Bar" (capitalize-header "FOO BAR"))
    (assert-eq "Foo-Bar" (capitalize-header "FOO_BAR"))
    (assert-eq "Foo-Bar" (capitalize-header "FOO-BAR"))))
