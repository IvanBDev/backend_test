import app/web
import app/router
import app/helper/postgres
import gleam/pgo
import gleam/erlang/process
import dot_env
import dot_env/env
import wisp
import mist

pub fn main() {
  wisp.configure_logger()

  dot_env.new() 
  |> dot_env.set_path(".env") 
  |> dot_env.set_debug(False) 
  |> dot_env.load 
  let assert Ok(secret_key_base) = env.get_string("SECRET_KEY_BASE")

  // Start a database connection pool.
  let conn = postgres.set_connection()
  let db = conn |> postgres.get_connection()

  // A context is constructed to hold the database connection and other informations (user-session, cookies, etc...)
  let context = web.Context(db |> pgo.connect)

  let handler = router.handle_request(_, context)

  let assert Ok(_) =
    wisp.mist_handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  wisp.log_info("Server started!")

  process.sleep_forever()

  wisp.log_info("Server closed")
}
