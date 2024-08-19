(comment
 "MIT License

  Copyright (c) 2021 Andrey Listopadov

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the “Software”), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.")

;;; Macros

(eval-compiler
  (local state
    (-> :fennel-test/state_
        (.. (math.random (or math.maxinteger 10000000)))
        gensym))
  (local lib-name (or ... "fennel-test"))

  (fn string-len [s]
    (if (and _G.utf8 _G.utf8.len)
        (_G.utf8.len s)
        (length s)))

  (fn assert-eq [expr1 expr2 msg]
    "Like `assert', except compares results of `expr1' and `expr2' for equality.
Generates formatted message if `msg' is not set to other message.

# Example
Compare two expressions:

``` fennel :skip-test
(assert-eq 1 (+ 1 2))
;; => runtime error: equality assertion failed
;; =>   Left: 1
;; =>   Right: 3
```

Deep compare values:

``` fennel :skip-test
(assert-eq [1 {[2 3] [4 5 6]}] [1 {[2 3] [4 5]}])
;; => runtime error: equality assertion failed
;; =>   Left:  [1 {[2 3] [4 5 6]}]
;; =>   Right: [1 {[2 3] [4 5]}]
```"
    (let [s1 (view expr1 {:one-line? true})
          s2 (view expr2 {:one-line? true})
          formatted (if (> (string-len (.. "(eq )" s1 s2)) 80)
                        (string.format "(eq %s\n    %s)" s1 s2)
                        (string.format "(eq %s %s)" s1 s2))]
      `(let [{:eq eq# :wrap-test-error wrap-test-error#} (require ,lib-name)
             tostring# (match (pcall require :fennel)
                         (true fennel#) #(fennel#.view $ {:one-line? true})
                         false tostring)
             traceback# (or (. (or package.loaded.fennel _G.debug {})
                               :traceback)
                            (fn [x#] x#))
             (lok# left#) ,(if (. (get-scope) :vararg)
                               `(xpcall (fn [...] ,expr1) traceback# ...)
                               `(xpcall (fn [] ,expr1) traceback#))
             (rok# right#) ,(if (. (get-scope) :vararg)
                                `(xpcall (fn [...] ,expr2) traceback# ...)
                                `(xpcall (fn [] ,expr2) traceback#))
             description# ,(if (in-scope? state)
                               `(or (and (. ,state :description)
                                         (next (. ,state :description))
                                         (: "testing: %s\n" :format (table.concat (. ,state :description) " ")))
                                    "")
                               "")
             assert-eq# (fn [left# right#]
                          (assert (eq# left# right#)
                                  (: "assertion failed for expression:\n%s\n Left: %s\nRight: %s\n%s" :format
                                     ,formatted
                                     (tostring# left#)
                                     (tostring# right#)
                                     ,(if msg `(.. " Info: " (tostring# ,msg)) ""))))]
         (if (not lok#)
             (-> (: "%sin expression:\n%s\n%s\n" :format description# ,s1 left#)
                 wrap-test-error#
                 error)
             (not rok#)
             (-> (: "%sin expression:\n%s\n%s\n" :format description# ,s2 right#)
                 wrap-test-error#
                 error))
         ,(when (in-scope? state)
            `(tset ,state :assertions
               (+ (. ,state :assertions) 1)))
         (case (xpcall assert-eq# traceback# left# right#)
           (false msg#)
           (-> (: "%s%s" :format description# msg#)
               wrap-test-error#
               error)))))

  (fn assert-ne
    [expr1 expr2 msg]
    "Assert for unequality.  Like `assert', except compares results of
`expr1' and `expr2' for unequality.  Generates formatted message if
`msg' is not set to other message.  Same as `assert-eq'."
    (let [s1 (view expr1 {:one-line? true})
          s2 (view expr2 {:one-line? true})
          formatted (if (> (string-len (.. "(not (eq ))" s1 s2)) 80)
                        (: "(not (eq %s\n         %s))" :format s1 s2)
                        (: "(not (eq %s %s))" :format s1 s2))]
      `(let [{:eq eq# :wrap-test-error wrap-test-error#} (require ,lib-name)
             tostring# (match (pcall require :fennel)
                         (true fennel#) #(fennel#.view $ {:one-line? true})
                         false tostring)
             traceback# (or (. (or package.loaded.fennel _G.debug {})
                               :traceback)
                            (fn [x#] x#))
             (lok# left#) ,(if (. (get-scope) :vararg)
                               `(xpcall (fn [...] ,expr1) traceback# ...)
                               `(xpcall (fn [] ,expr1) traceback#))
             (rok# right#) ,(if (. (get-scope) :vararg)
                                `(xpcall (fn [...] ,expr2) traceback# ...)
                                `(xpcall (fn [] ,expr2) traceback#))
             description# ,(if (in-scope? state)
                               `(or (and (. ,state :description)
                                         (next (. ,state :description))
                                         (: "testing: %s\n" :format (table.concat (. ,state :description) " ")))
                                    "")
                               "")
             eq# (fn [left# right#]
                   (assert (not (eq# left# right#))
                           (: "assertion failed for expression:\n%s\n Left: %s\nRight: %s\n%s" :format
                              ,formatted
                              (tostring# left#)
                              (tostring# right#)
                              ,(if msg `(.. " Info: " (tostring# ,msg)) ""))))]
         (if (not lok#)
             (-> (: "%sin expression:\n%s\n%s\n" :format description# ,s1 left#)
                 wrap-test-error#
                 error)
             (not rok#)
             (-> (: "%sin expression:\n%s\n%s\n" :format description# ,s2 right#)
                 wrap-test-error#
                 error))
         ,(when (in-scope? state)
            `(tset ,state :assertions
               (+ (. ,state :assertions) 1)))
         (case (xpcall eq# traceback# left# right#)
           (false msg#)
           (-> (: "%s%s" :format description# msg#)
               wrap-test-error#
               error)))))

  (fn assert-is
    [expr msg]
    "Assert `expr' for truth. Same as inbuilt `assert', except generates more
  verbose message unless the `msg` is provided.

``` fennel :skip-test
(assert-is (= 1 2 3))
;; => runtime error: assertion failed for (= 1 2 3)
```"
    `(let [{:wrap-test-error wrap-test-error#} (require ,lib-name)
           tostring# (match (pcall require :fennel)
                       (true fennel#) #(fennel#.view $ {:one-line? true})
                       false tostring)
           traceback# (or (. (or package.loaded.fennel _G.debug {})
                             :traceback)
                          (fn [x#] x#))
           (suc# res#) ,(if (. (get-scope) :vararg)
                            `(xpcall (fn [...] ,expr) traceback# ...)
                            `(xpcall (fn [] ,expr) traceback#))
           description# ,(if (in-scope? state)
                             `(or (and (. ,state :description)
                                       (next (. ,state :description))
                                       (: "testing: %s\n" :format (table.concat (. ,state :description) " ")))
                                  "")
                             "")
           is# (fn [expr#]
                 (assert expr#
                         (: "assertion failed for expression:\n%s\nResult: %s\n%s" :format
                            ,(view expr {:one-line? true})
                            (tostring res#)
                            ,(if msg `(.. "  Info: " (tostring# ,msg)) ""))))]
       (when (not suc#)
         (-> (: "%sin expression: %s: %s\n" :format description# ,(view expr {:one-line? true}) res#)
             wrap-test-error#
             error))
       ,(when (in-scope? state)
          `(tset ,state :assertions
             (+ (. ,state :assertions) 1)))
       (case (xpcall is# traceback# res#)
         (false msg#)
         (-> (: "%s%s" :format description# msg#)
             wrap-test-error#
             error))))

  (fn assert-not
    [expr msg]
    "Assert `expr' for not truth. Generates more verbose message unless the
`msg` is provided.  Works the same as `assert-is'."
    `(let [{:wrap-test-error wrap-test-error#} (require ,lib-name)
           tostring# (match (pcall require :fennel)
                       (true fennel#) #(fennel#.view $ {:one-line? true})
                       false tostring)
           traceback# (or (. (or package.loaded.fennel _G.debug {})
                             :traceback)
                          (fn [x#] x#))
           (suc# res#) ,(if (. (get-scope) :vararg)
                            `(xpcall (fn [...] ,expr) traceback# ...)
                            `(xpcall (fn [] ,expr) traceback#))
           description# ,(if (in-scope? state)
                             `(or (and (. ,state :description)
                                       (next (. ,state :description))
                                       (: "testing: %s\n" :format (table.concat (. ,state :description) " ")))
                                  "")
                             "")
           isnt# (fn [expr#]
                   (assert (not expr#)
                           (: "assertion failed for expression:\n%s\nResult: %s\n%s" :format
                              ,(view expr {:one-line? true})
                              (tostring res#)
                              ,(if msg `(.. "  Info: " (tostring# ,msg)) ""))))]
       (when (not suc#)
         (-> (: "%sin expression: %s: %s\n" :format description# ,(view expr {:one-line? true}) res#)
             wrap-test-error#
             error))
       ,(when (in-scope? state)
          `(tset ,state :assertions
             (+ (. ,state :assertions) 1)))
       (case (xpcall isnt# traceback# res#)
         (false msg#)
         (-> (: "%s%s" :format description# msg#)
             wrap-test-error#
             error))))

  (fn deftest
    [name ...]
    "Simple way of grouping tests with `name'.

# Example
``` fennel :skip-test
(deftest some-test
  ;; tests
  )
```
"
    `(let [(_# test-ns# _# state#) ...]
       (fn ,name [,state]
         ,...)
       (if (= :table (type test-ns#))
           (table.insert test-ns# [,(tostring name) ,name])
           (,name {:assertions 0}))))

  (fn testing
    [description ...]
    "Wraps the test code with a `description` such that
assertions would report the testing context.

# Example

Wrapping a single test:

``` fennel :skip-test
(deftest something-test
  (testing \"testing something\"
    ;; test body
  ))
```

Wrapping multiple tests with nested messages:

``` fennel :skip-test
(deftest something-test
  (testing \"testing\"
    (testing \"something\"
      ;; test body
      )
    (testing \"something else\"
      ;; test body
      )))
```

When an error occurs, nested `testing` descriptions are accumulated
into a single string."
    (assert-compile (= :string (type description))
                    "description must be a string"
                    description)
    `(do ,(when (in-scope? state)
            `(if (. ,state :description)
                 (table.insert (. ,state :description) ,description)
                 (tset ,state :description [,description])))
         (let [pack# (fn [...] (doto [...] (tset :n (select :# ...))))
               (ok# res#) (pcall (fn [] (pack# ((fn [] ,...)))))]
           ,(when (in-scope? state)
              `(table.remove (or (. ,state :description) [])))
           (if ok#
               (table.unpack res# 1 res#.n)
               (error res#)))))

  (fn use-fixtures [fixture-type ...]
    "Wrap test runs in a `fixture` function to perform setup and
teardown.  Using a `fixture-type` of `:each` wraps every test
individually, while `:once` wraps the whole run in a single function.
Multiple `fixtures` and fixture-types are supported in one form.

Firstures are active only when the thests are being run by the
`run-test' function.

# Example

``` fennel :skip-test
(use-fixtures
 :once
 (fn [test]
   (setup1) (test) (teardown1))
 (fn [test]
   (setup2) (test) (teardown2))
 :each
 (fn [test]
   (setup3) (test) (teardown3)))
```
"
    {:fnl/arglist [fixture-type fixture & fixtures]}
    (assert-compile (or (= fixture-type :once) (= fixture-type :each))
                    "Expected :once or :each as the first argument"
                    fixture-type)
    `(let [(ns# _# fixtures#) ...]
       (var fixture-type# ,fixture-type)
       (when (= :table (type fixtures#))
         (each [_# fixture# (ipairs ,[...])]
           (if (or (= fixture# :each) (= fixture# :once))
               (set fixture-type# fixture#)
               (do
                 (when (not (. fixtures# fixture-type# ns#))
                   (tset fixtures# fixture-type# ns# []))
                 (tset fixtures# fixture-type# ns#
                       (+ 1 (length (. fixtures# fixture-type# ns#)))
                       fixture#)))))))

  (tset macro-loaded lib-name
    {: deftest
     : testing
     : assert-eq
     : assert-ne
     : assert-is
     : assert-not
     : use-fixtures}))

;;; Equality

(fn eq [...]
  "Comparison function.

Accepts arbitrary amount of values, and does the deep comparison.  If
values implement `__eq` metamethod, tries to use it, by checking if
first value is equal to second value, and the second value is equal to
the first value.  If values are not equal and are tables does the deep
comparison.  Tables as keys are supported."
  (match (select "#" ...)
    0 true
    1 true
    2 (let [(a b) ...]
        (if (and (= a b) (= b a))
            true
            (= :table (type a) (type b))
            (do (var (res count-a) (values true 0))
                (each [k v (pairs a) :until (not res)]
                  (set res (eq v (do (var (res done) (values nil nil))
                                     (each [k* v (pairs b) :until done]
                                       (when (eq k* k)
                                         (set (res done) (values v true))))
                                     res)))
                  (set count-a (+ count-a 1)))
                (when res
                  (let [count-b (accumulate [res 0 _ _ (pairs b)]
                                  (+ res 1))]
                    (set res (= count-a count-b))))
                res)
            false))
    _ (let [(a b) ...]
        (and (eq a b) (eq (select 2 ...))))))

;;; Test Runner

(local Skip
  (setmetatable
   {}
   {:__tostring #:Skip
    :__fennelview #:Skip}))

;;;; Reporters

(fn default-stats-report [warnings errors skipped-tests assertions total-tests test-times]
  (-> "\nRan %d tests in %0.4f seconds with %d assertions, %d skipped, %d warnings, %d errors\n\n"
      (: :format total-tests
         (accumulate [total-time 0 _ time (pairs test-times)]
           (+ total-time time))
         assertions
         (accumulate [n 0 _ test (ipairs skipped-tests)]
           (case test
             {: test-count
              :test-name nil} (+ n test-count)
             _ (+ n 1)))
         (length warnings)
         (length errors))
      io.write)
  (each [_ message (ipairs warnings)]
    (io.stderr:write (: "Warning: %s\n" :format message)))
  (when (and (next warnings) (next skipped-tests))
    (io.stderr:write "\n"))
  (each [_ {: ns : test-name : message} (ipairs skipped-tests)]
    (if test-name
        (io.stderr:write
         (: "In '%s' skipped test '%s'%s" :format ns test-name
            (if message (: ": %s\n" :format message) "\n")))
        (io.stderr:write
         (: "In '%s' skipped all tests%s" :format ns
            (if message (: ": %s\n" :format message) "\n")))))
  (when (and (next skipped-tests) (next errors))
    (io.stderr:write "\n"))
  (each [_ {: ns : test-name : message : stdout : stderr} (ipairs errors)]
    (io.stderr:write
     (: "Error in '%s'%s%s" :format ns
        (if test-name
            (: " in test '%s'" :format test-name)
            "")
        (if message (: ":\n%s\n" :format message) "\n")))
    (when (and stdout (not= "" stdout))
      (io.stderr:write
       (: "Test stdout:\n%s" :format stdout)))
    (when (and stderr (not= "" stderr))
      (io.stderr:write
       (: "Test stderr:\n%s" :format stderr)))))

(local dots
  {:ns-start #(do (io.stdout:write "(") (io.stdout:flush))
   :ns-report #(do (io.stdout:write ")") (io.stdout:flush))
   :test-start #nil
   :test-report (fn [ok? test-name msg]
                  (io.stdout:write
                   (case ok?
                     (where (or true :warn)) "."
                     :skip "-"
                     _ "F"))
                  (io.stdout:flush))
   :stats-report default-stats-report})

(local namespaces
  {:ns-start (fn [ns]
               (io.stdout:write ns ": ")
               (io.stdout:flush))
   :ns-report (fn [ns ok?] (io.stdout:write
                            (case ok?
                              true "PASS"
                              :warn "WARN"
                              :skip "SKIP"
                              _ "FAIL")
                            "\n"))
   :test-start #nil
   :test-report #nil
   :stats-report default-stats-report})

;;;; Configuration

(fn file-exists? [file]
  {:private true}
  (let [fh (io.open file)]
    (when fh (fh:close))
    (not= fh nil)))

(fn setup-runner [config]
  {:private true}
  (let [{: dofile : view} (require config.fennel-lib)
        config (if (file-exists? ".fennel-test")
                   (collect [k v (pairs (dofile :.fennel-test))
                             :into config]
                     k v)
                   config)]
    (if (= config.reporter :dots)
        (set config.reporter dots)
        (= config.reporter :namespaces)
        (set config.reporter namespaces)
        (and (= :table (type config.reporter))
             (= :function (type config.reporter.ns-start))
             (= :function (type config.reporter.ns-report))
             (= :function (type config.reporter.test-start))
             (= :function (type config.reporter.test-report))
             (= :function (type config.reporter.stats-report)))
        nil
        (not= nil config.reporter)
        (do (io.stderr:write
             "Warning: unknown or malformed reporter: "
             (view config.reporter)
             "\nUsing default reporter: dots\n")
            (set config.reporter dots)))
    (math.randomseed config.seed)
    config))

;;;; Utils

(fn join [sep ...]
  ;; Concatenate multiple values into a string using `sep` as a
  ;; separator.
  {:private true}
  (table.concat
   (fcollect [i 1 (select :# ...)]
     (tostring (select i ...))) sep))

(local unpack (or table.unpack _G.unpack))

(fn with-no-output [out err fn1 ...]
  "Redirects output from stdout and stderr to `out` and `err` tables."
  {:private true}
  (let [{:write io/write :read io/read
         : stdin : stdout : stderr} io
        {:write fd/write :read fd/read &as fd}
        (. (getmetatable io.stdin) :__index)
        lua-print print
        pack #(doto [$...] (tset :n (select "#" $...)))
        args (pack ...)]
    (fn fd.write [fd ...]
      (if (or (= fd stdout) (= fd stderr))
          (table.insert (if (= fd stdout) out err) (join "" ...))
          (fd/write fd ...))
      fd)
    (fn _G.print [...]
      (io.write (.. (join "\t" ...) "\n"))
      nil)
    (fn io.write [...]
      (: (io.output) :write ...))
    (let [(_ res) (pcall #(pack (fn1 (unpack args 1 args.n))))]
      (set _G.print lua-print)
      (set io.wirte io/write)
      (set fd.write fd/write)
      (unpack res 1 res.n))))

(fn wrap-test-error [msg-or-fn]
  "Wraps error message `msg-or-fn` in a stack-preserving form.
Error message can be a string or a function that returns the error
string.  Only for internal use."
  (let [msg-fn (case (type msg-or-fn)
                 :function msg-or-fn
                 _ (fn [] msg-or-fn))]
    (->> {:__tostring msg-fn
          :__fennelview msg-fn}
         (setmetatable {}))))

;;;; Test loading

(fn load-tests [modules config tests fixtures state]
  {:private true}
  (let [{: make-searcher : view} (require config.fennel-lib)
        searcher (make-searcher
                  (collect [k v (pairs (or config.searcher-opts {}))
                            :into {:correlate true}]
                    k v))]
    (each [_ module-name (ipairs modules)]
      (let [module-tests []
            fn1 (searcher module-name)]
        (if (= :function (type fn1))
            (do (fn1 module-name module-tests fixtures state)
                (table.insert tests [module-name module-tests]))
            (error fn1 2))))))

(fn shuffle-table [t]
  {:private true}
  (for [i (length t) 2 -1]
    (let [j (math.random i)
          ti (. t i)]
      (tset t i (. t j))
      (tset t j ti))))

(fn shuffle-tests [tests]
  {:private true}
  (each [_ [_ test-ns] (ipairs tests)]
    (shuffle-table test-ns))
  (shuffle-table tests))

;;;; Fixtures

(fn default-fixture [f]
  {:private true}
  (f))

(fn compose-fixtures [f1 f2]
  {:private true}
  (fn [g] (f1 (fn [] (f2 g)))))

(fn join-fixtures [fixtures]
  {:private true}
  (accumulate [f default-fixture _ fixture (ipairs fixtures)]
    (compose-fixtures f fixture)))

(fn setup-fixtures [once-each fixtures]
  {:private true}
  (each [ns fs (pairs (. fixtures once-each))]
    (tset fixtures once-each ns (join-fixtures fs))))

;;;; Runner

(local socket
  (case (pcall require :socket) (true s) s _ nil))

(local posix
  (case (pcall require :posix) (true p) p _ nil))

(local time
  (if (?. socket :gettime)
      socket.gettime
      (?. posix :clock_gettime)
      (let [gettime posix.clock_gettime]
        #(let [(s ns) (gettime)]
           (+ s (/ ns 1000000000))))
      os.clock))

(local difftime #(- $1 $2))

(fn run-ns-tests [ns tests config fixtures
                  {: warnings : errors : skipped-tests : test-times &as state}]
  {:private true}
  (let [{: reporter} config
        oncef (or (. fixtures.once ns) default-fixture)]
    (var ok? true)
    (reporter.ns-start ns)
    (if (= 0 (length tests))
        (do (table.insert warnings (: "namespace '%s' has no tests" :format ns))
            (reporter.ns-report ns :warn))
        (let [ns-runner (fn []
                          (let [eachf (or (. fixtures.each ns) default-fixture)]
                            (each [test-n [test-name test-fn] (ipairs tests)]
                              (let [ns-test [ns test-name]]
                                (reporter.test-start ns test-name test-n (length tests))
                                (let [err [] out []]
                                  (when time
                                    (tset test-times ns-test (time)))
                                  (match (if config.capture-output?
                                             (with-no-output out err #(pcall eachf #(test-fn state)))
                                             (pcall eachf #(test-fn state)))
                                    (_ [Skip ?message])
                                    (do (reporter.test-report
                                         :skip ns test-name)
                                        (set state.executed-test-count (math.max 0 (- state.executed-test-count 1)))
                                        (when time
                                          (tset test-times ns-test nil))
                                        (table.insert skipped-tests
                                                      {: ns : test-name :message ?message}))
                                    (false message)
                                    (do (set ok? false)
                                        (reporter.test-report
                                         false ns test-name (tostring message))
                                        (table.insert errors {: ns : test-name : message
                                                              :stdout (table.concat out "")
                                                              :stderr (table.concat err "")}))
                                    _ (reporter.test-report true ns test-name))
                                  (when (and time (. test-times ns-test))
                                    (tset test-times ns-test (difftime (time) (. test-times ns-test)))))))))]
          (match (pcall oncef ns-runner)
            (_ [Skip ?message])
            (let [test-count (length tests)]
              (reporter.ns-report ns :skip)
              (set state.executed-test-count
                (math.max 0 (- state.executed-test-count test-count)))
              (table.insert skipped-tests {: ns :message ?message : test-count}))
            (false message)
            (do (table.insert errors {: ns : message})
                (reporter.ns-report ns false))
            _ (reporter.ns-report ns ok?))))))

(fn merge [t1 t2]
  (if (and (= :table (type t1)) (= :table (type t2)))
      (collect [k v (pairs t2) :into t1]
        k v)
      t1))

(fn run-tests [modules opts]
  "Run tests in the given `modules` accordingly to the `opts` table.
Each module is loaded and inspected for tests defined with the
`deftest' macro.  Then, according to the configuration file
`.fennel-test`, the tests are shuffled, ran, and report is constructed
by the reporter specified in the config.

The `modules` argument is a sequential table of module names relative
to the script that runs the tests.

If the test module sets up fixtures with the `use-fixtures'
macro. these fixtures are used accordingly to their specs.

# Example

``` fennel :skip-tests
(run-tests [:tests.fixture-test :tests.equality-test])
```"
  (let [tests []
        fixtures {:once {} :each {}}
        tests []
        state {:errors []
               :warnings []
               :skipped-tests []
               :test-times {}
               :executed-test-count 0
               :assertions 0}
        config
        (setup-runner
         (merge {:seed
                 (tonumber
                  (or (os.getenv "FENNEL_TEST_SEED")
                      (math.floor (* 1000 (+ (os.time) (os.clock))))))
                 :reporter :dots
                 :capture-output? true
                 :fennel-lib :fennel
                 :shuffle? true}
                opts))]
    (io.stdout:write
     "Test run at " (os.date) ", seed: " config.seed "\n\n")
    (load-tests modules config tests fixtures state)
    (setup-fixtures :once fixtures)
    (setup-fixtures :each fixtures)
    (when config.shuffle?
      (shuffle-tests tests))
    (set state.executed-test-count
      (accumulate [total 0 _ [_ tests] (ipairs tests)]
        (+ total (length tests))))
    (each [_ [ns tests] (ipairs tests)]
      (run-ns-tests ns tests config fixtures state))
    (let [{: warnings : errors : skipped-tests : executed-test-count : test-times : assertions} state]
      (config.reporter.stats-report warnings errors skipped-tests assertions executed-test-count test-times)
      (when (next errors)
        (os.exit 1)))))

(fn skip-test [reason]
  "Calling this function inside a test or a fixture will stop the test
early and mark it as skipped. The optional `reason` argument is a
message to display in the log if the reporter is configured to do so."
  (error [Skip reason]))

{: eq : run-tests : skip-test : wrap-test-error}
