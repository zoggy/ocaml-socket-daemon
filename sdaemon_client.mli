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

type command = {
  name : string;
  desc : string;
  options : (Arg.key * Arg.spec * Arg.doc) list;
  anon : (string -> unit) option;
  action : (Sdaemon_common.socket_spec -> unit Lwt.t) option;
}
val command :
  ?options:(Arg.key * Arg.spec * Arg.doc) list ->
  ?anon:(string -> unit) ->
  ?action:(Sdaemon_common.socket_spec -> unit Lwt.t) ->
  name:string -> desc:string -> unit -> command

val connect :
  Sdaemon_common.socket_spec ->
  (Lwt_io.input_channel * Lwt_io.output_channel) Lwt.t

val run :
  ?options:(Arg.key * Arg.spec * Arg.doc) list ->
  ?commands:command list ->
  (unit -> Sdaemon_common.socket_spec) -> name:'a -> version:string -> unit
