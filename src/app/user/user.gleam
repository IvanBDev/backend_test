import gleam/dynamic

pub type User {
  User(id: Int, username: String, email: String)
}

pub type UserForCreate {
  UserForCreate(username: String, email: String)
}

pub fn from_postgres(database_row data: dynamic.Dynamic) -> Result(User, List(dynamic.DecodeError)) {
  let user =
    data
    |> dynamic.from
    |> dynamic.decode3(
      User,
      dynamic.element(at: 0, of: dynamic.int),
      dynamic.element(at: 1, of: dynamic.string),
      dynamic.element(at: 2, of: dynamic.string),
    )

  user
}

pub fn from_create_user_request(json: dynamic.Dynamic) -> Result(UserForCreate, List(dynamic.DecodeError)) {
  // Checks to see if a Dynamic value is a map with a specific field, and returns the value of that field if it is. -gleam_stdlib docs
  // Given this description from the documentation we can use .field beacause the JSON format is essentially a map
  let user =
    json
    |> dynamic.from
    |> dynamic.decode2(
      UserForCreate,
      dynamic.field(named: "username", of: dynamic.string),
      dynamic.field(named: "email", of: dynamic.string),
    )

  user
}

pub fn from_update_user_request(json: dynamic.Dynamic) {
  // Checks to see if a Dynamic value is a map with a specific field, and returns the value of that field if it is. -gleam_stdlib docs
  // Given this description from the documentation we can use .field beacause the JSON format is essentially a map
  let assert Ok(user) =
    json
    |> dynamic.from
    |> dynamic.decode3(
      User,
      dynamic.field(named: "id", of: dynamic.int),
      dynamic.field(named: "username", of: dynamic.string),
      dynamic.field(named: "email", of: dynamic.string),
    )

  user
}
