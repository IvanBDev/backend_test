// PostgreSQL adapter which which passes `PreparedStatements`
// to the `gleam_pgo` library for execution.

import cake.{type PreparedStatement, type ReadQuery, type WriteQuery}
import cake/dialect/postgres_dialect
import cake/param.{
  type Param, BoolParam, FloatParam, IntParam, NullParam, StringParam,
}
import dot_env
import dot_env/env
import gleam/dynamic
import gleam/list
import gleam/option.{Some}
import gleam/pgo.{type Connection, type Value}
import pprint

pub fn read_query_to_prepared_statement(
  query qry: ReadQuery,
) -> PreparedStatement {
  qry |> postgres_dialect.query_to_prepared_statement
}

pub fn write_query_to_prepared_statement(
  query qry: WriteQuery(t),
) -> PreparedStatement {
  qry |> postgres_dialect.write_query_to_prepared_statement
}

pub fn set_connection() {
  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(False)
  |> dot_env.load

  let assert Ok(host) = env.get_string("DB_HOST")
  let assert Ok(user) = env.get_string("DB_USER")
  let assert Ok(password) = env.get_string("DB_PASSWORD")
  let assert Ok(database) = env.get_string("DB_DBNAME")

  let connection =
    pgo.Config(
      ..pgo.default_config(),
      host: host,
      user: user,
      password: Some(password),
      database: database,
    )

  connection
}

pub fn get_connection(config config: pgo.Config) {
  let connection = config

  connection
}

pub fn with_connection(f: fn(Connection) -> a, config config: pgo.Config) -> a {
  let connection =
    get_connection(config)
    |> pgo.connect
  let value = f(connection)
  pgo.disconnect(connection)

  value
}

pub fn run_read_query(query qry: ReadQuery, decoder dcdr, db_connection db_conn) {
  let prp_stm = read_query_to_prepared_statement(qry)

  let sql = cake.get_sql(prp_stm)
  pprint.debug("Query: [" <> sql <> "]")

  let params = cake.get_params(prp_stm)

  let db_params =
    params
    |> list.map(fn(param: Param) -> Value {
      case param {
        BoolParam(param) -> pgo.bool(param)
        FloatParam(param) -> pgo.float(param)
        IntParam(param) -> pgo.int(param)
        StringParam(param) -> pgo.text(param)
        NullParam -> pgo.null()
      }
    })

  pprint.debug("Parametri passati al Database: ")
  pprint.debug(db_params)

  let result = sql |> pgo.execute(on: db_conn, with: db_params, expecting: dcdr)

  case result {
    Ok(pgo.Returned(_result_count, v)) -> Ok(v)
    Error(e) -> Error(e)
  }
}

pub fn run_write_query(
  query qry: WriteQuery(t),
  decoder dcdr,
  db_connection db_conn,
) {
  let prp_stm = write_query_to_prepared_statement(qry)

  let sql = cake.get_sql(prp_stm)
  pprint.debug("Query: [" <> sql <> "]")

  let params = cake.get_params(prp_stm)

  let db_params =
    params
    |> list.map(fn(param: Param) -> Value {
      case param {
        BoolParam(param) -> pgo.bool(param)
        FloatParam(param) -> pgo.float(param)
        IntParam(param) -> pgo.int(param)
        StringParam(param) -> pgo.text(param)
        NullParam -> pgo.null()
      }
    })

  pprint.debug("Parametri passati al Database: ")
  pprint.debug(db_params)

  let result = sql |> pgo.execute(on: db_conn, with: db_params, expecting: dcdr)

  case result {
    Ok(pgo.Returned(_result_count, v)) -> Ok(v)
    Error(e) -> Error(e)
  }
}

pub fn execute_raw_sql(sql sql: String, connection conn: Connection) {
  sql |> pgo.execute(conn, with: [], expecting: dynamic.dynamic)
}
