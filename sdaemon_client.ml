
open Lwt.Infix

type command =
  { name : string ;
    desc : string ;
    options : (Arg.key * Arg.spec * Arg.doc) list ;
    anon: (string -> unit) option ;
    action : (Sdaemon_common.socket_spec -> unit Lwt.t) option;
  }

let command ?(options=[]) ?anon ?action ~name ~desc () =
  { name ; desc ; options ; anon ; action }

let unknown_command str =
  prerr_endline (Printf.sprintf "Unknown command %S" str);
  exit 1

let unexpected_argument str =
  prerr_endline (Printf.sprintf "Unexpected argument %S" str);
  exit 1

let usage commands =
  Printf.sprintf
    "Usage: %s <command> [options]\nwhere commands are\n  %s\nand options are:"
    Sys.argv.(0)
    (String.concat "\n  " (List.map (fun c -> c.name) commands))

let connect socket_spec =
  let sock_file = Sdaemon_common.socket_filename socket_spec in
  let sockaddr = Unix.ADDR_UNIX sock_file in
  Lwt_io.open_connection sockaddr

let help commands =
  let anon str =
    match List.find (fun c -> c.name = str) commands with
    | exception Not_found -> unknown_command str
    | c ->
        let msg = Printf.sprintf "Usage: %s %s [options]%s\n%s\nwhere options are:"
          Sys.argv.(0) c.name
          (match c.anon with None -> "" | Some _ -> " [args]")
          c.desc
        in
        Arg.usage c.options msg
  in
  command ~anon ~name: "help" ~desc: "display help about a command" ()

let stop name =
  let action socket_spec =
    let%lwt (ic, oc) = connect socket_spec in
    Sdaemon_common.send_client_msg oc Sdaemon_common.Stop
  in
  command ~action ~name: "stop"
    ~desc:(Printf.sprintf "stop the %s daemon" name) ()

let restart name =
  let action socket_spec =
    let%lwt (ic, oc) = connect socket_spec in
    Sdaemon_common.send_client_msg oc Sdaemon_common.Restart
  in
  command ~action ~name: "restart"
    ~desc:(Printf.sprintf "restart the %s daemon" name) ()

let status name =
  let action socket_spec =
    let%lwt (ic, oc) = connect socket_spec in
    let%lwt () = Sdaemon_common.send_client_msg oc Sdaemon_common.Status in
    match%lwt Sdaemon_common.receive_server_msg ic with
      Sdaemon_common.String str -> Lwt_io.write_line Lwt_io.stdout str
    | e -> Lwt_io.write_line Lwt_io.stderr
        (Printf.sprintf "Unhandled server message: %s" (Printexc.to_string (Obj.magic e)))
  in
  command ~action ~name: "status"
    ~desc:(Printf.sprintf "print the status of the %s daemon" name) ()

let set_log_level name =
  let level = ref None in
  let anon str =
    match int_of_string str with
    | exception _ -> failwith (Printf.sprintf "Invalid interger %S" str)
    | n -> level := Some n
  in
  let action socket_spec =
    match !level with
      None -> Lwt.return_unit
    | Some n ->
        let%lwt (ic, oc) = connect socket_spec in
        Sdaemon_common.send_client_msg oc (Sdaemon_common.Set_log_level n)
  in
  command ~anon ~action ~name: "loglevel"
    ~desc:(Printf.sprintf "set the log level of the %s daemon" name) ()

let run ?(options=[]) ?(commands=[]) sock_spec ~name ~version =
  try
    let version () = print_endline version ; exit 0 in
    let commands = (help commands) :: commands in
    let options = ref
      ([
         "-v", Arg.Unit version, " print version and exit" ;
       ] @ options)
    in
    let action = ref None in
    let cmd_fun anon_ref str =
      match List.find (fun c -> c.name = str) commands with
      | exception Not_found -> unknown_command str
      | c ->
          options := !options @ c.options ;
          anon_ref := (match c.anon with None -> unexpected_argument | Some f -> f) ;
          action := c.action ;
    in
    let rec anon = ref (fun str -> cmd_fun anon str) in
    let anon str = !anon str in
    Arg.parse_dynamic options anon (usage commands);
    match !action with
      None -> ()
    | Some f -> Lwt_main.run (f sock_spec)
  with
    e ->
      let msg = match e with
          Failure msg | Sys_error msg -> msg
        | e -> Printexc.to_string e
      in
      prerr_endline msg;
      exit 1

