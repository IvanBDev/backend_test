import app/controller/user_controller
import app/web
import gleam/string_builder
import wisp

pub fn handle_request(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    // Homepage
    [] -> wisp.html_response(string_builder.from_string("Home"), 200)

    // User endpoints
    // ["users", "all"] -> user_controller.get_all(request: req, context: ctx)
    ["users", "get-user", id] ->
      user_controller.get_by_id(request: req, context: ctx, id: id)
    ["users", "update-user"] ->
      user_controller.update_user(request: req, context: ctx)

    // All the empty responses
    ["internal-server-error"] -> wisp.internal_server_error()
    ["unprocessable-entity"] -> wisp.unprocessable_entity()
    ["method-not-allowed"] -> wisp.method_not_allowed([])
    ["entity-too-large"] -> wisp.entity_too_large()
    ["bad-request"] -> wisp.bad_request()
    _ -> wisp.not_found()
  }
}
