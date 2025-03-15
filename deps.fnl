{:deps
 {:io.gitlab.andreyorst/async.fnl
  {:type :git :sha "ea0a63f2c87651f9c63ee775f2a066281b868573"}
  :io.gitlab.andreyorst/json.fnl
  {:type :git :sha "eebcb40750d6f41ed03fed04373f944dcf297383"}
  :io.gitlab.andreyorst/reader.fnl
  {:type :git :sha "252ea2474cb7399020e6922f700a5190373e6f98"}
  :io.gitlab.andreyorst/uuid.fnl
  {:type :git :sha "209ff4f3a70ba8354034eaf90b70ddb0d14ea254"}
  :luasocket
  {:type :rock :version "3.1.0-1"}}
 :paths
 {:fennel ["src/?.fnl" "src/?/init.fnl"]}
 :profiles
 {:dev
  {:deps {:io.gitlab.andreyorst/fennel-test
          {:type :git :sha "416895275e4f20c1c00ba15dd0e274d1b459c533"}}
   :paths {:fennel ["tests/?.fnl"]}}}}
