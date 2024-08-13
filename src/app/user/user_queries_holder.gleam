import app/user/user
import cake/insert
import cake/select
import cake/update
import cake/where

pub fn get_by_id_query(id id: Int) -> select.ReadQuery {
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

pub fn get_all_query() -> select.ReadQuery {
  select.new()
  |> select.select(select.col("*"))
  |> select.from_table("public.user")
  |> select.order_by("id", select.Asc)
  |> select.to_query()
}

pub fn create_user_query(
  user_from_request user: user.UserForCreate,
) -> insert.WriteQuery(_) {
  [[insert.string(user.username), insert.string(user.email)] |> insert.row]
  |> insert.from_values(table_name: "public.user", columns: [
    "username", "email",
  ])
  |> insert.to_query()
}

pub fn update_user_query(
  user_from_request user: user.User,
) -> update.WriteQuery(_) {
  update.new()
  |> update.table(table_name: "public.user")
  |> update.sets(set: [
    "username" |> update.set_string(user.username),
    "email" |> update.set_string(user.email),
  ])
  |> update.where(where.eq(where.col("id"), where.int(user.id)))
  |> update.returning(["id", "username", "email"])
  |> update.to_query()
}
