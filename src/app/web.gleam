import gleam/bool
import gleam/pgo
import gleam/string_builder
import pprint
import wisp

pub type Context {
  Context(db: pgo.Connection)
}

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  use <- default_responses
  handle_request(req)
}

pub fn default_responses(handle_request: fn() -> wisp.Response) -> wisp.Response {
  let response = handle_request()

  use <- bool.guard(when: response.body != wisp.Empty, return: response)

  case response.status {
    404 | 405 ->
      "<h1>Not Found</h1>"
      |> string_builder.from_string
      |> wisp.html_body(response, _)

    400 | 422 ->
      "<h1>Bad request</h1>"
      |> string_builder.from_string
      |> wisp.html_body(response, _)

    413 ->
      "<h1>Request entity too large</h1>"
      |> string_builder.from_string
      |> wisp.html_body(response, _)

    500 ->
      "<h1>Internal server error</h1>"
      |> string_builder.from_string
      |> wisp.html_body(response, _)

    _ -> response
  }
}

pub fn custom_record_not_found(message message: String) -> wisp.Response {
  let resp = message |> string_builder.from_string |> wisp.html_response(404)
  pprint.debug(resp)
  resp
}

pub fn custom_bad_request(message message: String) -> wisp.Response {
  let resp = message |> string_builder.from_string |> wisp.html_response(400)
  pprint.debug(resp)
  resp
}

pub fn custom_internal_server_error(message message: String) -> wisp.Response {
  let resp = message |> string_builder.from_string |> wisp.html_response(500)
  pprint.debug(resp)
  resp
}

pub fn custom_created(message message: String) -> wisp.Response {
  let resp = message |> string_builder.from_string |> wisp.html_response(201)
  pprint.debug(resp)
  resp
}
