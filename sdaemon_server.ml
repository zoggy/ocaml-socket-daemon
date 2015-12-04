(*********************************************************************************)
(*                Socket-daemon                                                  *)
(*                                                                               *)
(*    Copyright (C) 2015 Institut National de Recherche en Informatique          *)
(*    et en Automatique. All rights reserved.                                    *)
(*                                                                               *)
(*    This program is free software; you can redistribute it and/or modify       *)
(*    it under the terms of the GNU Lesser General Public License version        *)
(*    3 as published by the Free Software Foundation.                            *)
(*                                                                               *)
(*    This program is distributed in the hope that it will be useful,            *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of             *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *)
(*    GNU Library General Public License for more details.                       *)
(*                                                                               *)
(*    You should have received a copy of the GNU Lesser General Public           *)
(*    License along with this program; if not, write to the Free Software        *)
(*    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   *)
(*    02111-1307  USA                                                            *)
(*                                                                               *)
(*    Contact: Maxence.Guesdon@inria.fr                                          *)
(*                                                                               *)
(*                                                                               *)
(*********************************************************************************)

open Sdaemon_common
open Lwt.Infix

type handlers = {
    on_stop : Lwt_io.output_channel -> unit Lwt.t ;
    on_restart : Lwt_io.output_channel -> unit Lwt.t ;
    on_set_log_level : Lwt_io.output_channel -> int -> unit Lwt.t ;
    on_status : unit -> string Lwt.t ;
    on_other : Lwt_io.input_channel -> Lwt_io.output_channel -> client_msg -> unit Lwt.t ;
  }

let default_handlers = {
  on_stop = (fun _ -> exit 0) ;
  on_restart = (fun _ -> Lwt.return_unit) ;
  on_set_log_level = (fun _ _ -> Lwt.return_unit) ;
  on_status = (fun _ -> Lwt.return "Running") ;
  on_other = (fun _ oc msg ->
       let msg = Printf.sprintf "Unhandled message %s" (Printexc.to_string (Obj.magic msg)) in
       Sdaemon_common.send_server_msg oc (String msg)
    ) ;
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
  Lwt_unix.bind sock sockaddr ;
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
            let null = Unix.openfile "/tmp/sdaemon" (*"/dev/null"*)
              [Unix.O_CREAT ; Unix.O_RDWR] 0o600
            in
            List.iter (Unix.dup2 null) [ Unix.stdin; Unix.stdout ; Unix.stderr];
            let server = socket_server socket_spec handlers in
            Pervasives.at_exit (fun () -> shutdown_server server) ;
            f server >>= fun x -> shutdown_server server; Lwt.return x
        | _ -> exit 0
      end
  | _ -> exit 0
  