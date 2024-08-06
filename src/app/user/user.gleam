import gleam/dynamic

pub type User {
  User(id: Int, username: String, email: String)
}

pub fn from_postgres(row) {
  // NOTICE: This will crash, if the returned data from the SQL query does not match
  let assert Ok(user) =
    row
    |> dynamic.from
    |> dynamic.decode3(
      User,
      dynamic.element(0, dynamic.int),
      dynamic.element(1, dynamic.string),
      dynamic.element(2, dynamic.string),
    )

  user
}