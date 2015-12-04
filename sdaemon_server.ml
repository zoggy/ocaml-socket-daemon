open Sdaemon_common
open Lwt.Infix

type handlers = {
    on_stop : Lwt_io.output_channel -> unit Lwt.t ;
    on_restart : Lwt_io.output_channel -> unit Lwt.t ;
    on_set_log_level : Lwt_io.output_channel -> int -> unit Lwt.t ;
    on_status : unit -> string Lwt.t ;
    on_other : Lwt_io.input_channel -> Lwt_io.output_channel -> client_msg -> unit Lwt.t ;
  }

(* modified from Lwt_io *)
type server = { shutdown : unit Lazy.t }

let shutdown_server server = Lazy.force server.shutdown

let establish_server ?(backlog=5) sock_file f =
  let sockaddr = Unix.ADDR_UNIX sock_file in
  let sock = Lwt_unix.socket (Unix.domain_of_sockaddr sockaddr)
    Unix.SOCK_STREAM 0
  in
  Lwt_unix.setsockopt sock Unix.SO_REUSEADDR true;
  Lwt_unix.bind sock sockaddr;
  Lwt_unix.listen sock backlog;
  let abort_waiter, abort_wakener = Lwt.wait () in
  let abort_waiter = abort_waiter >>= fun _ -> Lwt.return `Shutdown in
  let rec on_value acc = function
  | [] -> Lwt.return acc
  | `Done :: q -> on_value acc q
  | `Shutdown :: _ ->
      begin
        Lwt_unix.close sock >>= fun () ->
          if sock_file <> "" && sock_file.[0] <> '\x00' then Unix.unlink sock_file ;
          Lwt.return []
      end
  | (`Accept (fd, addr) :: q) ->
      (try Lwt_unix.set_close_on_exec fd with Invalid_argument _ -> ());
      let close = lazy
        begin
          Lwt_unix.shutdown fd Unix.SHUTDOWN_ALL;
          Lwt_unix.close fd
        end
      in
      let t =
        let ic = Lwt_io.of_fd ~mode:Lwt_io.input ~close:(fun () -> Lazy.force close) fd
        and oc = Lwt_io.of_fd ~mode:Lwt_io.output ~close:(fun () -> Lazy.force close) fd in
        f ic oc >>= fun () -> Lwt.return `Done
      in
      let accept = Lwt_unix.accept sock >|= (fun x -> `Accept x) in
      on_value (t :: accept :: acc) q
  in
  let rec loop threads =
    let%lwt (values, threads) = Lwt.nchoose_split threads in
    match%lwt on_value threads values with
      [] -> Lwt.return_unit
    | threads -> loop threads
  in
  ignore (loop [abort_waiter]);
  { shutdown = lazy(Lwt.wakeup abort_wakener `Shutdown) }

let handle_connection handlers ic oc =
  try%lwt
    match%lwt Lwt_chan.input_value ic with
    | Stop -> handlers.on_stop oc
    | Restart -> handlers.on_restart oc
    | Set_log_level n -> handlers.on_set_log_level oc n
    | Status ->
        begin
          handlers.on_status () >>= fun str ->
            Lwt_chan.output_value oc (String str) >>= fun () ->
            Lwt_io.flush oc
        end
    | other -> handlers.on_other ic oc other
  with
    e ->
      Lwt.join [Lwt_chan.close_in ic ; Lwt_chan.close_out oc]

let socket_server socket_spec handlers =
  let sock_file = Sdaemon_common.socket_filename socket_spec in
  establish_server sock_file (handle_connection handlers)

let daemonize handlers socket_spec f =
  match Unix.fork () with
    0 ->
      begin
        let _pid = Unix.setsid () in
        Sys.set_signal Sys.sighup Sys.Signal_ignore ;
        Sys.set_signal Sys.sigpipe Sys.Signal_ignore ;
        match Unix.fork () with
          0 ->
            let null = Unix.openfile "/dev/null" [Unix.O_RDWR] 0o600 in
            List.iter (Unix.dup2 null) [ Unix.stdin; Unix.stdout ; Unix.stderr];
            let server = socket_server socket_spec handlers in
            f server
        | _ -> exit 0
      end
  | _ -> exit 0
  