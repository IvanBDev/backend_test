import gleam/dynamic
import gleam/string
import gleam/string_builder

pub fn decode_error_exeption(
  list_of_decode_error list_decode_error: List(dynamic.DecodeError),
  message_for_user message: string_builder.StringBuilder,
) {
  case list_decode_error {
    [] -> message
    [first, ..rest] -> {
      let paths = get_path_from_decode_error(first.path, "")

      let return =
        string_builder.append(
          message,
          "Expected: \t[" <> first.expected <> "]\n",
        )
        |> string_builder.append("Found: \t[" <> first.found <> "]\n")
        |> string_builder.append("Error while parsing: \t[" <> paths <> "]\n")

      decode_error_exeption(rest, return)
    }
  }
}

fn get_path_from_decode_error(
  list_of_string list_in: List(String),
  strings_of_path string_out: String,
) {
  case list_in {
    [] -> string_out
    [first, ..rest] -> {
      let return = string_out |> string.append(first)
      get_path_from_decode_error(rest, return)
    }
  }
}
