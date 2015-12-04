

type client_msg = ..
type client_msg +=
  | Stop
  | Restart
  | Status
  | Set_log_level of int

type server_msg = ..
type server_msg +=
  String of string

type socket_spec =
| Tmp of string
| Absolute of string
| Relative of string

let socket_spec_of_string = function
| str when Filename.is_implicit str -> Tmp str
| str when Filename.is_relative str -> Relative str
| str -> Absolute str

let string_of_socket_spec = function
| Tmp str -> str
| Relative str -> str
| Absolute str -> str

let replace_in_socket_filename str =
  let user = string_of_int (Unix.getuid()) in
  let re_user = Str.regexp_string "%{uid}" in
  Str.global_replace re_user str user

let socket_filename spec =
  let file =
    match spec with
      Tmp str ->
        Printf.sprintf "/tmp/%s" (Filename.quote str)
    | Relative str ->
        Filename.concat (Sys.getcwd()) (Filename.quote str)
    | Absolute str ->
        str
  in
  replace_in_socket_filename file

