import app/service/user_service
import app/user/user
import app/web
import gleam/http
import gleam/int
import gleam/result
import wisp

pub fn get_all(request req: wisp.Request, context ctx: web.Context) {
  let request_method = req.method

  case request_method {
    http.Get -> user_service.get_all(ctx)
    _ -> wisp.method_not_allowed(allowed: [http.Get])
  }
}

pub fn get_by_id(
  request req: wisp.Request,
  context ctx: web.Context,
  id id: String,
) -> wisp.Response {
  let request_method = req.method
  let user_id = result.try(Ok(id), int.parse)

  // Dispatch to the appropriate handler based on the HTTP method.
  case request_method {
    http.Get -> {
      case user_id {
        Ok(id) -> {
          user_service.get_one(id, ctx)
        }
        // If I'm here it means that the parsing gave as result a Nil so the id isn't valid
        Error(Nil) -> web.custom_bad_request("Invalid id [" <> id <> "]")
      }
    }
    _ -> wisp.method_not_allowed(allowed: [http.Get])
  }
}

pub fn create_user(request req: wisp.Request, context ctx: web.Context) {
  use json_body <- wisp.require_json(req)

  let request_method = req.method
  let request_body = user.from_create_user_request(json_body)

  case request_method {
    http.Post ->
      user_service.create_user(context: ctx, user_for_create: request_body)
    _ -> wisp.method_not_allowed(allowed: [http.Post])
  }
}

pub fn update_user(request req: wisp.Request, context ctx: web.Context) {
  use json_body <- wisp.require_json(req)
  
  let request_method = req.method
  let request_body = user.from_update_user_request(json_body)

  case request_method {
    http.Put -> {
      user_service.update_user(context: ctx, user_for_update: request_body)
    }
    _ -> wisp.method_not_allowed(allowed: [http.Put])
  }
}
