import app/service/user_service
import app/user/user
import app/web
import gleam/http
import gleam/int
import wisp

// pub fn get_all(request req: wisp.Request, context ctx: web.Context) {
//   let request_method = req.method

//   case request_method {
//     http.Get -> user_service.get_all(ctx)
//     _ -> wisp.method_not_allowed(allowed: [http.Get])
//   }
// }

pub fn get_by_id(
  request req: wisp.Request,
  context ctx: web.Context,
  id id: String,
) {
  let request_method = req.method

  case request_method {
    http.Get -> {
      let user_id = int.parse(id)

      case user_id {
        Ok(id) -> user_service.get_one(id: id, context: ctx)
        Error(Nil) -> web.custom_bad_request("Invalid ID: \t[" <> id <> "]")
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
