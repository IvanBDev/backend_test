import app/exception/exception
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

type ErrorWrapper {
  QueryErrorType(message: String)
  RecordNotFound(message: String)
  ErrorNotSupported(message: String)
  DecodingErrorType(message: String)
}

pub fn get_one(id id: Int, context ctx: web.Context) -> wisp.Response {
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
        Ok(db_user_object) -> {
          let response =
            get_response_from_the_conversion_of_the_db_object_to_user_object(
              db_user_object:,
            )

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

    Error(error) -> {
      case error {
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

          pprint.debug("---------------- get_all (end) ------------------")

          response
        }
        Error(list_of_decode_error) -> {
          //In Gleam 1.4.x if you have the same name in both label and variable, you can write [variable_name:] 
          let message =
            string_builder.new()
            |> exception.decode_error_exeption(list_of_decode_error:)
            |> string_builder.to_string

          web.custom_internal_server_error(message:)
        }
      }
    }
    Error(error) -> {
      case error {
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

pub fn create_user(
  context ctx: web.Context,
  user_for_create user: user.UserForCreate,
) -> wisp.Response {
  pprint.debug("---------------- create_user (start) ------------------")

  let query = user_queries_holder.create_user_query(user)

  let user_created = query |> postgres.run_write_query(dynamic.dynamic, ctx.db)

  case user_created {
    Ok(value) -> {
      pprint.debug("Result from query: ")
      pprint.debug(value)

      pprint.debug("---------------- create_user (end) ------------------")

      wisp.created()
    }
    Error(error) -> {
      case error {
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

pub fn update_user(
  context ctx: web.Context,
  user_for_update user: user.User,
) -> wisp.Response {
  pprint.debug("---------------- update_user (start) ------------------")

  let query = user_queries_holder.update_user_query(user)

  let user_updated = query |> postgres.run_write_query(dynamic.dynamic, ctx.db)

  case user_updated {
    Ok(user_object) -> {
      pprint.debug("Result from query: ")
      pprint.debug(user_object)

      let single_user = list.first(user_object)

      case single_user {
        Ok(single_user) -> {
          let return =
            get_response_from_the_conversion_of_the_db_object_to_user_object(
              single_user,
            )

          pprint.debug("---------------- update_user (end) ------------------")

          return
        }

        Error(Nil) -> {
          web.custom_record_not_found(
            "Il record con id ["
            <> int.to_string(user.id)
            <> "] non è presente in base dati",
          )
        }
      }
    }
    Error(error) -> {
      case error {
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

pub fn delete_user(user_id user_id: Int, context ctx: web.Context) {
  case verify_if_record_exist(id: user_id, context: ctx) {
    Ok(existing_user) -> {
      pprint.debug("---------------- delete_user (start) ------------------")

      let delete_query = user_queries_holder.delete_user_query(existing_user.id)

      let user_deleted =
        delete_query |> postgres.run_write_query(dynamic.dynamic, ctx.db)

      case user_deleted {
        Ok(user_object) -> {
          pprint.debug("Result from delete_query: ")
          pprint.debug(user_object)

          pprint.debug("---------------- delete_user (end) ------------------")

          wisp.no_content()
        }

        Error(error) -> {
          case error {
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

    Error(error) -> {
      case error {
        QueryErrorType(message) -> web.custom_internal_server_error(message:)

        ErrorNotSupported(message) -> web.custom_internal_server_error(message:)

        RecordNotFound(message) -> web.custom_bad_request(message:)

        DecodingErrorType(message) -> web.custom_internal_server_error(message:)
      }
    }
  }
}

fn verify_if_record_exist(id id: Int, context ctx: web.Context) -> Result(user.User, ErrorWrapper) {
  pprint.debug(
    "---------------- checking if the user exist (start) ------------------",
  )

  let get_one_query = user_queries_holder.get_by_id_query(id)
  let user_from_query =
    get_one_query |> postgres.run_read_query(dynamic.dynamic, ctx.db)

  case user_from_query {
    Ok(users) -> {
      pprint.debug("Result from get_one_query: ")
      pprint.debug(users)

      let single_user = list.first(users)

      case single_user {
        Ok(user_object) -> {
          let user_converted = user.from_postgres(user_object)

          case user_converted {
            Ok(user) -> {
              pprint.debug(
                "---------------- checking if the user exist (end) ✅ ------------------",
              )

              Ok(user)
            }

            Error(list_of_decode_error) -> {
              //In Gleam 1.4.x if you have the same name in both label and variable, you can write [variable_name:] 
              let message =
                string_builder.new()
                |> exception.decode_error_exeption(list_of_decode_error:)
                |> string_builder.to_string

              Error(DecodingErrorType(message:))
            }
          }
        }

        Error(Nil) -> {
          pprint.debug(
            "---------------- checking if the user exist (end) ❌ ------------------",
          )

          let message =
            "Il record con id ["
            <> int.to_string(id)
            <> "] non è presente in base dati"

          Error(RecordNotFound(message:))
        }
      }
    }

    Error(error) -> {
      case error {
        pgo.PostgresqlError(code, name, message) -> {
          let message =
            "Error code: \t["
            <> code
            <> "]\nError type: \t["
            <> name
            <> "]\nReason: \t["
            <> message
            <> "]"

          Error(QueryErrorType(message:))
        }
        _ -> {
          let message =
            "An error occurred while processing your request\nWe will send our crack powered programming team to resolve this issue."

          Error(ErrorNotSupported(message:))
        }
      }
    }
  }
}

fn get_response_from_db_object_for_get_all_function(
  list_of_users list_in: List(user.User),
) -> string_builder.StringBuilder {
  // Converting the User type into a JSON Object (is basically a list of tuples)
  let json_user_list = convert_user_list_to_json_list(list_in, [])

  // Converting a List(StringBuilder) into one StringBuilder
  let return = string_builder.concat(json_user_list)

  return
}

fn get_response_from_the_conversion_of_the_db_object_to_user_object(
  db_user_object output: dynamic.Dynamic,
) -> wisp.Response {
  let converted_user = user.from_postgres(output)

  case converted_user {
    Ok(converted_user_object) -> {
      // Converting the User type into a JSON Object (is basically a list of tuples)
      let json_user =
        json.object([
          #("id", json.int(converted_user_object.id)),
          #("username", json.string(converted_user_object.username)),
          #("email", json.string(converted_user_object.email)),
        ])
        |> json.to_string_builder

      wisp.json_response(json_user, 200)
    }

    Error(list_of_decode_error) -> {
      //In Gleam 1.4.x if you have the same name in both label and variable, you can write [variable_name:] 
      let message =
        string_builder.new()
        |> exception.decode_error_exeption(list_of_decode_error:)
        |> string_builder.to_string

      web.custom_internal_server_error(message:)
    }
  }
}

fn convert_user_list_to_json_list(
  list list: List(user.User),
  accumulator acc: List(string_builder.StringBuilder),
) -> List(string_builder.StringBuilder) {
  case list {
    [] -> acc
    [first, ..rest] -> {
      let user = first

      let json_user = [
        json.object([
          #("id", json.int(user.id)),
          #("username", json.string(user.username)),
          #("email", json.string(user.email)),
        ])
        |> json.to_string_builder,
      ]

      let json_result = list.append(acc, json_user)
      convert_user_list_to_json_list(rest, json_result)
    }
  }
}
