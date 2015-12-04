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

type client_msg = ..  [@@deriving yojson]
type client_msg +=
  | Stop
  | Restart
  | Status
  | Set_log_level of int  [@@deriving yojson]
type server_msg = ..  [@@deriving yojson]
type server_msg += String of string  [@@deriving yojson]

val send_client_msg : Lwt_io.output_channel -> client_msg -> unit Lwt.t
val send_server_msg : Lwt_io.output_channel -> server_msg -> unit Lwt.t
val receive_client_msg : Lwt_io.input_channel -> client_msg Lwt.t
val receive_server_msg : Lwt_io.input_channel -> server_msg Lwt.t
val receive_server_msg_opt : Lwt_io.input_channel -> server_msg option Lwt.t

type socket_spec = Tmp of string | Absolute of string | Relative of string
val socket_spec_of_string : string -> socket_spec
val string_of_socket_spec : socket_spec -> string
val replace_in_socket_filename : string -> string
val socket_filename : socket_spec -> string
