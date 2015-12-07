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

(** Client-side: connecting to local socket, and specifying command line options
  and subcommands. *)

(** A subcommand on the executable. *)
type command = {
  name : string;
  desc : string;  (** help text for the subcommand *)
  options : (Arg.key * Arg.spec * Arg.doc) list; (** this subcommand's options *)
  anon : (string -> unit) option; (** the function to call on each argument *)
  action : (Sdaemon_common.socket_spec -> unit Lwt.t) option;
    (** the function to call when this subcommand is triggered;
        it is given the socket filename specification to use to connect
        to the server. *)
}

(** Construct a {!command} structure. *)
val command :
  ?options:(Arg.key * Arg.spec * Arg.doc) list ->
  ?anon:(string -> unit) ->
  ?action:(Sdaemon_common.socket_spec -> unit Lwt.t) ->
  name:string -> desc:string -> unit -> command

(** [connect spec] connects to the server using the socket filename obtainerd
  from the given specification. Channels are closed automatically when
  garbage-collected. *)
val connect :
  Sdaemon_common.socket_spec ->
  (Lwt_io.input_channel * Lwt_io.output_channel) Lwt.t


(** Parse command line arguments and run the action function associated
       to the subcommand corresponding to arguments.
   @param options common options for all subcommands
   @param commands subcommands besides the default ones (stop, restart, loglevel
   and status). Subcommands in parameter can mask default ones if they have
   the same name.
   @param name the name of the software, used in help messages.
   @param version version of the software, used in help messages.
*)
val run :
  ?options:(Arg.key * Arg.spec * Arg.doc) list ->
  ?commands:command list ->
  (unit -> Sdaemon_common.socket_spec) -> name:string -> version:string -> unit
