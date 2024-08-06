
import app/service/user_service
import app/web
import gleam/http
import gleam/int
import gleam/result
import wisp

pub fn get_by_id(
  request req: wisp.Request,
  context ctx: web.Context,
  id id: String,
) {
  let method = req.method

  let user_id = result.try(Ok(id), int.parse)

  // Dispatch to the appropriate handler based on the HTTP method.
  case user_id {
    Ok(id) -> {
      case method {
        http.Get -> user_service.get_one(id, ctx)
        _ -> wisp.method_not_allowed([http.Get])
      }
    }
    Error(_) -> wisp.bad_request()
  }
}

pub fn get_all(request req: wisp.Request, context ctx: web.Context) {
  let method = req.method

  case method {
    http.Get -> user_service.get_all(ctx)
    _ -> wisp.method_not_allowed([http.Get])
  }
}
