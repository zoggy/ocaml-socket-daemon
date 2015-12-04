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

open Lwt.Infix

let send oc v =
  Lwt_chan.output_value oc v >>= fun () ->
    Lwt_chan.flush oc
let receive ic = Lwt_chan.input_value ic

type client_msg = ..
type client_msg +=
  | Stop
  | Restart
  | Status
  | Set_log_level of int

type server_msg = ..
type server_msg +=
  String of string

let send_client_msg = send
let send_server_msg = send
let receive_client_msg oc = (receive oc : client_msg Lwt.t)
let receive_server_msg oc = (receive oc : server_msg Lwt.t)

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
  Str.global_replace re_user str user

let socket_filename spec =
  let file =
    match spec with
      Tmp str ->
        Printf.sprintf "/tmp/%s" (Filename.quote str)
    | Relative str ->
        Filename.concat (Sys.getcwd()) (Filename.quote str)
    | Absolute str ->
        str
  in
  replace_in_socket_filename file

