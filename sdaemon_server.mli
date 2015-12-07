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

(** Server-side: creating local socket and handling messages. *)

(** Handlers for predefined messages and other messages. *)
type handlers = {
  on_stop : Lwt_io.output_channel -> unit Lwt.t;
    (** [on_stop] is called when the [Sdameon_common.Stop] message is received.
       The function can send messages to the client through the output channel
       before exiting (or not).*)

  on_restart : Lwt_io.output_channel -> unit Lwt.t;
    (** [on_restart] is called when the [Sdameon_common.Restart] message is received.
       The function can send messages to the client through the output channel
       before restarting (or not).*)

  on_set_log_level : Lwt_io.output_channel -> int -> unit Lwt.t;
    (** [on_set_log_loevel] is called when the [Sdameon_common.Set_log_level]
        message is received.
       The function can send messages to the client through the output channel,
       for example to signal that the log level changed (or not).*)

  on_status : unit -> string Lwt.t;
    (** [on_set_log_level] is called when the [Sdameon_common.Status]
        message is received. The function returns a status string, which
        will then be sent back to the client in a [Sdaemon.String] server
        message. *)

  on_other :
    Lwt_io.input_channel ->
    Lwt_io.output_channel -> Sdaemon_common.client_msg -> unit Lwt.t;
    (** [on_other] is called when another {!Sdaemon_common.client_msg} message
        is received. The function can communicate with the client
        with the given input and output channels.*)
}

(** Default handlers for client messages.
  For [Stop], [exit 0] is called.
  For [Restart] and [Set_log_level] the function just [Lwt.return_unit].
  For Status, the function returns ["Running"]. For any other message,
  the [on_other] function returns a [String] server message indicating
  that the message could not be handled.*)
val default_handlers : handlers

(** Handler for the server listening to the local socket. *)
type server

(** Stop the given server, if it was not stopped yet. *)
val shutdown_server : server -> unit

(** [daemonize handlers spec f] changes into a daemon using a double fork,
  then creates the local socket according to [spec]. Then a server is
  created, listening on this socket and handling messages according to
  the given [handlers]. Then [f] is called with the server so that it
  can stop the server eventually.
  When [f] returns, the server is shutdown and the Lwt thread
  returned by [daemonize] terminates. *)
val daemonize :
  handlers -> Sdaemon_common.socket_spec -> (server -> 'a Lwt.t) -> 'a Lwt.t
