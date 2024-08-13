import app/exception/exception
import app/service/user_service
import app/user/user
import app/web
import gleam/http
import gleam/int
import gleam/io
import gleam/string_builder
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
  let request_method = req.method

  case request_method {
    http.Post -> {
      use json_body <- wisp.require_json(req)
      let request_body = user.from_create_user_request(json_body)

      case request_body {
        Ok(body) -> {
          user_service.create_user(context: ctx, user_for_create: body)
        }

        Error(list_of_decode_error) -> {
          io.debug(list_of_decode_error)
          //In Gleam 1.4.x if you have the same name in both label and variable, you can write [variable_name:] 
          let message =
            string_builder.new()
            |> exception.decode_error_exeption(list_of_decode_error:)
            |> string_builder.to_string

          web.custom_internal_server_error(message:)
        }
      }
    }

    _ -> wisp.method_not_allowed(allowed: [http.Post])
  }
}

pub fn update_user(request req: wisp.Request, context ctx: web.Context) {
  let request_method = req.method

  case request_method {
    http.Put -> {
      use json_body <- wisp.require_json(req)
      let request_body = user.from_update_user_request(json_body)

      case request_body {
        Ok(body) -> {
          user_service.update_user(context: ctx, user_for_update: body)
        }

        Error(list_of_decode_error) -> {
          io.debug(list_of_decode_error)
          //In Gleam 1.4.x if you have the same name in both label and variable, you can write [variable_name:] 
          let message =
            string_builder.new()
            |> exception.decode_error_exeption(list_of_decode_error:)
            |> string_builder.to_string

          web.custom_internal_server_error(message:)
        }
      }
    }
    _ -> wisp.method_not_allowed(allowed: [http.Post])
  }
}

pub fn delete_user(
  request req: wisp.Request,
  context ctx: web.Context,
  id id: String,
) {
  let request_method = req.method

  case request_method {
    http.Delete -> {
      let id_from_request = int.parse(id)

      case id_from_request {
        Ok(user_id) -> {
          user_service.delete_user(user_id:, context: ctx)
        }
        Error(Nil) -> web.custom_bad_request("Invalid ID: \t[" <> id <> "]")
      }
    }
    
    _ -> {
      wisp.method_not_allowed(allowed: [http.Delete])
    }
  }
}
