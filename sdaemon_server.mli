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

type handlers = {
  on_stop : Lwt_io.output_channel -> unit Lwt.t;
  on_restart : Lwt_io.output_channel -> unit Lwt.t;
  on_set_log_level : Lwt_io.output_channel -> int -> unit Lwt.t;
  on_status : unit -> string Lwt.t;
  on_other :
    Lwt_io.input_channel ->
    Lwt_io.output_channel -> Sdaemon_common.client_msg -> unit Lwt.t;
}
val default_handlers : handlers

type server
val shutdown_server : server -> unit
val daemonize :
  handlers -> Sdaemon_common.socket_spec -> (server -> 'a Lwt.t) -> 'a Lwt.t
