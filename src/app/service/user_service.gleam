import app/helper/postgres
import app/user/user
import app/user/user_queries_holder
import app/web
import gleam/dynamic
import gleam/int
import gleam/json
import gleam/list
import gleam/pgo
import gleam/result
import gleam/string_builder
import pprint
import wisp

pub fn get_one(id id: Int, context ctx: web.Context) {
  pprint.debug("---------------- get_one (start) ------------------")
  let query = user_queries_holder.get_by_id_query(id)

  // Executing the query
  let list_of_users_from_query =
    query |> postgres.run_read_query(dynamic.dynamic, ctx.db)

  case list_of_users_from_query {
    Ok(users) -> {
      pprint.debug("Result from query: ")
      pprint.debug(users)

      let single_user = list.first(users)

      case single_user {
        Ok(user_object) -> {
          let response =
            get_response_from_db_object_for_get_one_function(user_object)

          pprint.debug("---------------- get_one (end) ------------------")
          response
        }

        Error(Nil) -> {
          web.custom_record_not_found(
            "Il record con id ["
            <> int.to_string(id)
            <> "] non è presente in base dati",
          )
        }
      }
    }

    Error(query_error) -> {
      case query_error {
        pgo.PostgresqlError(code, name, message) -> {
          let message =
            "Error code: \t["
            <> code
            <> "]\nError type: \t["
            <> name
            <> "]\nReason: \t["
            <> message
            <> "]"
          message
          |> web.custom_internal_server_error
        }
        _ ->
          web.custom_internal_server_error(
            "An error occurred while processing your request\nWe will send our crack powered programming team to resolve this issue.",
          )
      }
    }
  }
}

pub fn get_all(context ctx: web.Context) -> wisp.Response {
  pprint.debug("---------------- get_all (start) ------------------")

  let query = user_queries_holder.get_all_query()

  // Executing the query
  let list_of_dynamic_users_from_query =
    query |> postgres.run_read_query(dynamic.dynamic, ctx.db)

  case list_of_dynamic_users_from_query {
    Ok(dynamic_users) -> {
      pprint.debug("Result from query: ")
      pprint.debug(dynamic_users)

      // Combines a list of results into a single result.
      let list_of_users =
        list.map(dynamic_users, user.from_postgres) |> result.all()

      case list_of_users {
        Ok(users) -> {
          let response =
            users
            |> get_response_from_db_object_for_get_all_function
            |> wisp.json_response(200)

          pprint.debug("---------------- get_all (finish) ------------------")

          response
        }
        Error(list_of_decode_error) -> {
          let message = decode_error_exeption(list_of_decode_error: list_of_decode_error, message_for_user: string_builder.new())
          web.custom_internal_server_error(message: string_builder.to_string(message))
        }
      }
    }
    Error(query_error) -> {
      case query_error {
        pgo.PostgresqlError(code, name, message) -> {
          let message =
            "Error code: \t["
            <> code
            <> "]\nError type: \t["
            <> name
            <> "]\nReason: \t["
            <> message
            <> "]"
          message
          |> web.custom_internal_server_error
        }
        _ ->
          web.custom_internal_server_error(
            "An error occurred while processing your request\nWe will send our crack powered programming team to resolve this issue.",
          )
      }
    }
  }
}

fn get_response_from_db_object_for_get_all_function(
  list_of_users list_in: List(user.User),
) {
  // Converting the User type into a JSON Object (is basically a list of tuples)
  let json_user_list = convert_user_list_to_json_list(list_in, [])

  // Converting a List(StringBuilder) into one StringBuilder
  let return = string_builder.concat(json_user_list)

  return
}

pub fn create_user(
  context ctx: web.Context,
  user_for_create user: user.UserForCreate,
) -> wisp.Response {
  pprint.debug("---------------- create_user (start) ------------------")

  let query = user_queries_holder.create_user_query(user)

  let assert Ok(user_created) =
    query |> postgres.run_write_query(dynamic.dynamic, ctx.db)
  pprint.debug("Result from query: ")
  pprint.debug(user_created)

  pprint.debug("---------------- create_user (start) ------------------")

  wisp.created()
}

pub fn update_user(context ctx: web.Context, user_for_update user: user.User) {
  pprint.debug("---------------- update_user (start) ------------------")

  let query = user_queries_holder.update_user_query(user)

  let assert Ok(user_updated) =
    query |> postgres.run_write_query(dynamic.dynamic, ctx.db)

  pprint.debug("Result from query: ")
  pprint.debug(user_updated)

  pprint.debug("---------------- update_user (end) ------------------")

  web.custom_created("Record aggiornato correttamente")
}

fn get_response_from_db_object_for_get_one_function(
  result_from_query output: dynamic.Dynamic,
) {
  let converted_user = user.from_postgres(output)

  case converted_user {
    Ok(converted_user_object) -> {
      // Converting the User type into a JSON Object (is basically a list of tuples)
      let json_user =
        json.to_string_builder(
          json.object([
            #("id", json.int(converted_user_object.id)),
            #("username", json.string(converted_user_object.username)),
            #("email", json.string(converted_user_object.email)),
          ]),
        )

      wisp.json_response(json_user, 200)
    }

    Error(err) -> {
      let message = decode_error_exeption(err, string_builder.new())
      web.custom_internal_server_error(string_builder.to_string(message))
    }
  }
}

fn decode_error_exeption(
  list_of_decode_error list_decode_error: List(dynamic.DecodeError),
  message_for_user message: string_builder.StringBuilder,
) {
  case list_decode_error {
    [] -> message
    [first, ..rest] -> {
      let return =
        string_builder.append(
          message,
          "Expected: \t[" <> first.expected <> "]\n",
        )
        |> string_builder.append("Found: \t[" <> first.found <> "\n")

      decode_error_exeption(rest, return)
    }
  }
}

fn convert_user_list_to_json_list(
  list list: List(user.User),
  accumulator acc: List(string_builder.StringBuilder),
) {
  case list {
    [] -> acc
    [first, ..rest] -> {
      let user = first

      let json_user = [
        json.to_string_builder(
          json.object([
            #("id", json.int(user.id)),
            #("username", json.string(user.username)),
            #("email", json.string(user.email)),
          ]),
        ),
      ]

      let json_result = list.append(acc, json_user)
      convert_user_list_to_json_list(rest, json_result)
    }
  }
}
