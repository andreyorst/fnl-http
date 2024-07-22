;;; project configuration file for fennel-ls

{:fennel-path "./?.fnl;./?/init.fnl;src/?.fnl;src/?/init.fnl;lib/?.fnl"
 :macro-path "./?.fnl;./?/init-macros.fnl;./?/init.fnl;src/?.fnl;src/?/init-macros.fnl;src/?/init.fnl;lib/?.fnl"
 :lua-version "lua54"
 :libraries {:tic-80 false}
 :extra-globals ""
 :lints {:unused-definition true
         :unknown-module-field true
         :unnecessary-method true
         :bad-unpack true
         :var-never-set true
         :op-with-no-arguments true
         :multival-in-middle-of-call true}}
