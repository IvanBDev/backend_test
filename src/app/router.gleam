import app/controller/user_controller
import app/web.{type Context}
import gleam/string_builder
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    // Homepage
    [] -> wisp.html_response(string_builder.from_string("Home"), 200)

    // User endpoints
    ["users", "all"] -> user_controller.get_all(req, ctx)
    ["users", "get-user", id] -> user_controller.get_by_id(req, ctx, id)

    // All the empty responses
    ["internal-server-error"] -> wisp.internal_server_error()
    ["unprocessable-entity"] -> wisp.unprocessable_entity()
    ["method-not-allowed"] -> wisp.method_not_allowed([])
    ["entity-too-large"] -> wisp.entity_too_large()
    ["bad-request"] -> wisp.bad_request()
    _ -> wisp.not_found()
  }
}
