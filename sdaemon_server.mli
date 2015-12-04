type handlers = {
  on_stop : Lwt_io.output_channel -> unit Lwt.t;
  on_restart : Lwt_io.output_channel -> unit Lwt.t;
  on_set_log_level : Lwt_io.output_channel -> int -> unit Lwt.t;
  on_status : unit -> string Lwt.t;
  on_other :
    Lwt_io.input_channel ->
    Lwt_io.output_channel -> Sdaemon_common.client_msg -> unit Lwt.t;
}
type server
val shutdown_server : server -> unit
val daemonize :
  handlers -> Sdaemon_common.socket_spec -> (server -> 'a Lwt.t) -> 'a Lwt.t
