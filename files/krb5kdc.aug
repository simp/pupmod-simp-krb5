module Krb5Kdc =

autoload xfm

let comment = Inifile.comment "#" "#"
let empty = Inifile.empty
let eol = Inifile.eol
let dels = Util.del_str

let indent = del /[ \t]*/ ""
let eq = del /[ \t]*=[ \t]*/ " = "
let eq_openbr = del /[ \t]*=[ \t\n]*\{([ \t]*\n)*/ " = {"
let closebr = del /[ \t]*\}/ "}"

(* These two regexps for realms and apps are not entirely true
   - strictly speaking, there's no requirement that a realm is all upper case
   and an application only uses lowercase. But it's what's used in practice.

   Without that distinction we couldn't distinguish between applications
   and realms in the [appdefaults] section.
*)

let realm_re = /[A-Z][.a-zA-Z0-9-]*/
let app_re = /[a-z][a-zA-Z0-9_]*/
let name_re = /[.a-zA-Z0-9_-]+/

(* let value = store /[^;# \t\n{}]+/ *)
let value = store /[^;# \t\n{}]|[^;# \t\n{}][^#\n]*[^;# \t\n{}]/
let entry (kw:regexp) (sep:lens) (comment:lens)
    = [ indent . key kw . sep . value . (comment|eol) ] | comment

let simple_section (n:string) (k:regexp) =
  let title = Inifile.indented_title n in
  let entry = entry k eq comment in
    Inifile.record title entry

let record (t:string) (e:lens) =
  let title = Inifile.indented_title t in
    Inifile.record title e

let kdcdefaults =
  let keys = /kdc_ports|kdc_tcp_ports|v4_mode/ in
    simple_section "kdcdefaults" keys

let realms =
  let simple_option = /acl_file|admin_keytab|database_name|
    default_principal_expiration|default_principal_flags|dict_file|
    kadmind_port|kpasswd_port|key_stash_file|kdc_ports|kdc_tcp_ports|
    master_key_name|master_key_type|max_life|max_renewable_life|
    iprop_enable|iprop_master_ulogsize|iprop_slave_poll|
    supported_enctypes|reject_bad_transit/ in
  let option = entry simple_option eq comment in
  let realm = [ indent . label "realm" . store realm_re .
                  eq_openbr . option* . closebr . eol ] in
    record "realms" (realm|comment)

let lns = (comment|empty)* .
  (kdcdefaults|realms)*

let xfm = transform lns (incl "/var/kerberos/kdc.conf")
