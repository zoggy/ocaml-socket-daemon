open Lwt.Infix

let send oc v =
  Lwt_chan.output_value oc v >>= fun () ->
    Lwt_chan.flush oc
let receive ic = Lwt_chan.input_value ic

type client_msg = .. [@@deriving yojson]
type client_msg +=
  | Stop
  | Restart
  | Status
  | Set_log_level of int [@@deriving yojson]

type server_msg = ..  [@@deriving yojson]
type server_msg +=
  String of string  [@@deriving yojson]

let send_client_msg oc msg = send oc (client_msg_to_yojson msg)

let send_server_msg oc msg = send oc (server_msg_to_yojson msg)

let receive_client_msg ic =
  (receive ic) >>= fun json ->
    match client_msg_of_yojson json with
    | Ok v -> Lwt.return v
    | Error msg -> Lwt.fail_with msg

let receive_server_msg ic =
  (receive ic) >>= fun json ->
      match server_msg_of_yojson json with
    | Ok v -> Lwt.return v
    | Error msg -> Lwt.fail_with msg

let receive_server_msg_opt ic =
  try%lwt receive_server_msg ic >>= fun msg -> Lwt.return (Some msg)
  with _ -> Lwt.return_none

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
  Str.global_replace re_user user str

let socket_filename spec =
  let file =
    match spec with
      Tmp str ->
        Printf.sprintf "/tmp/%s" str
    | Relative str ->
        Filename.concat (Sys.getcwd()) str
    | Absolute str ->
        str
  in
  replace_in_socket_filename file

