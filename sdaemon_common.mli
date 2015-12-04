type client_msg = ..
type client_msg += Stop | Restart | Status | Set_log_level of int
type server_msg = ..
type server_msg += String of string
type socket_spec = Tmp of string | Absolute of string | Relative of string
val socket_spec_of_string : string -> socket_spec
val string_of_socket_spec : socket_spec -> string
val replace_in_socket_filename : string -> string
val socket_filename : socket_spec -> string
