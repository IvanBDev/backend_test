import app/helper/postgres
import app/user/user
import app/web
import cake/select
import cake/where
import gleam/dynamic
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import pprint
import wisp.{type Response}

pub fn get_one(id id: Int, context ctx: web.Context) -> Response {
  let user = {
    let query = get_by_id_query(id)

    // use connection <- postgres.with_connection()

    let assert Ok(user_from_query) =
      query |> postgres.run_read_query(dynamic.dynamic, ctx.db)

    wisp.log_info("user_from_query: ")
    pprint.debug(user_from_query)

    let output = result.try(Ok(user_from_query), list.first)

    case output {
      Ok(value) -> {
        let user_converted = user.from_postgres(value)
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

  user
}

fn get_by_id_query(id id: Int) {
  select.new()
  |> select.selects([
    select.col("u.id"),
    select.col("u.username"),
    select.col("u.email"),
  ])
  |> select.from_table("public.user u")
  |> select.where(where.eq(where.col("u.id"), where.int(id)))
  |> select.to_query()
}
