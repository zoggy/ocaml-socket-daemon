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

(** Common definitions for client and server. *)

(** The type of messages sent by the client to the server through a socket.
  Messages are converted to JSON and sent using [Lwt_chan.output_value].
  They are read from input channels with [Lwt_chan.input_value] and converted
  from JSON to the message type.
  This is an extensible type, so that additional messages (for additional
  commands) can be sent to the server.
*)
type client_msg = ..  [@@deriving yojson]
type client_msg +=
  | Stop
  | Restart
  | Status
  | Set_log_level of int  [@@deriving yojson]


(** The type of messages sent by the server to the client. *)
type server_msg = ..  [@@deriving yojson]
type server_msg +=
| String of string (** used by server to send a string to client *)
  [@@deriving yojson]

(** {2 Sending and receiving messages} *)

val send_client_msg : Lwt_io.output_channel -> client_msg -> unit Lwt.t
val send_server_msg : Lwt_io.output_channel -> server_msg -> unit Lwt.t

val receive_client_msg : Lwt_io.input_channel -> client_msg Lwt.t
val receive_server_msg : Lwt_io.input_channel -> server_msg Lwt.t
val receive_server_msg_opt : Lwt_io.input_channel -> server_msg option Lwt.t

(** {2 Socket filename specification} *)

type socket_spec =
| Tmp of string (** a filename from "/tmp" *)
| Absolute of string (** an absolute filename *)
| Relative of string (** a filename relative to current working directory *)

(** [socket_spec_of_string str] returns:
- [Absolute str] if [str] is an absolute filename name,
- [Relative str] if [str] starts with "." or "..",
- [Tmp str] if [str] is implicitely relative. *)
val socket_spec_of_string : string -> socket_spec

val string_of_socket_spec : socket_spec -> string

(** Return the absolute filename from the given spcification.
  The string "%\{uid\}" is replaced by the program uid.
*)
val socket_filename : socket_spec -> string
