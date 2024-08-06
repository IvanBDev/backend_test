import app/helper/postgres
import app/user/user
import app/user/user_queries_holder
import app/web
import gleam/dynamic
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string_builder
import pprint
import wisp

pub fn get_one(id id: Int, context ctx: web.Context) -> wisp.Response {
  pprint.debug("---------------- get_one (start) ------------------")
  let query = user_queries_holder.get_by_id_query(id)

  let assert Ok(user_from_query) =
    query |> postgres.run_read_query(dynamic.dynamic, ctx.db)

  pprint.debug("Result from query: ")
  pprint.debug(user_from_query)

  // The default behavor is to give a List(Dynamic) but since I nedd only one element and the first
  // I can use list.first function to retrive only one element
  let output = result.try(Ok(user_from_query), list.first)

  let user_for_get_by_id =
    get_response_from_db_object_for_get_one_function(output, id)
  pprint.debug("---------------- get_one (finish) ------------------")
  user_for_get_by_id
}

pub fn get_all(context ctx: web.Context) -> wisp.Response {
  pprint.debug("---------------- get_all (start) ------------------")

  let query = user_queries_holder.get_all_query()

  let assert Ok(list_of_users) =
    query |> postgres.run_read_query(dynamic.dynamic, ctx.db)
  pprint.debug("Result from query: ")
  pprint.debug(list_of_users)

  let output = list.map(list_of_users, user.from_postgres)

  let user_list_for_get_all =
    get_response_from_db_object_for_get_all_function(output)
  pprint.debug("---------------- get_all (finish) ------------------")
  user_list_for_get_all
}

fn get_response_from_db_object_for_get_one_function(
  result_from_query output: Result(dynamic.Dynamic, Nil),
  params_needed_for_query id: Int,
) -> wisp.Response {
  case output {
    Ok(value) -> {
      // Converting the value from the database (Dynamic) to the needed type (User)
      let user_converted = user.from_postgres(value)

      // Converting the User type into a JSON Object (is basically a list of tuples)
      let json_user =
        json.to_string_builder(
          json.object([
            #("id", json.int(user_converted.id)),
            #("username", json.string(user_converted.username)),
            #("email", json.string(user_converted.email)),
          ]),
        )

      // Return an appropriate response.
      wisp.json_response(json_user, 200)
    }
    Error(Nil) ->
      web.record_not_found(
        "Il record con id ["
        <> int.to_string(id)
        <> "] non è presente in base dati",
      )
  }
}

fn get_response_from_db_object_for_get_all_function(
  list_of_users list: List(user.User),
) {
  case !list.is_empty(list) {
    True -> {
      // Converting the User type into a JSON Object (is basically a list of tuples)
      let json_user_list = user_list_to_json_converter(list, [])

      // Converting a List(StringBuilder) into one StringBuilder
      let one_for_all = string_builder.concat(json_user_list)

      wisp.json_response(one_for_all, 200)
    }
    False -> web.record_not_found("Nessun record presente in base dati")
  }
}

fn user_list_to_json_converter(
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
      user_list_to_json_converter(rest, json_result)
    }
  }
}
