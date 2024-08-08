import app/user/user
import cake/insert
import cake/select
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
