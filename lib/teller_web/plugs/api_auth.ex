defmodule TellerWeb.Plugs.APIAuth do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(%Plug.Conn{path_info: ["api", "request_token"]} = conn, _opts) do
    conn
  end

  def call(conn, _opts) do
    [auth_type, auth] =
      Plug.Conn.get_req_header(conn, "authorization")
      |> List.first()
      |> String.split(" ")

    case auth_type do
      "Basic" ->
        if !auth,
          do:
            conn
            |> resp(401, "Please include an authorization token in the username field")
            |> send_resp()
            |> halt()

        token = extract_token(auth)

        if !String.starts_with?(token, "test_"),
          do:
            conn
            |> resp(401, "Authorization tokens must start with test_")
            |> send_resp()
            |> halt()

        token = String.split(token, "test_") |> List.last()

        case Phoenix.Token.decrypt(TellerWeb.Endpoint, "accounts", token) do
          {:ok, timestamp} ->
            {:ok, timestamp, _} = DateTime.from_iso8601(timestamp)
            assign(conn, :token_timestamp, timestamp)

          {:error, _} ->
            conn |> resp(401, "Invalid authorization token") |> send_resp() |> halt()
        end

      _ ->
        conn
        |> resp(
          401,
          "Please use Basic authorization and put your auth token in the username field"
        )
        |> send_resp()
        |> halt()
    end
  end

  # ========================================
  #  ---------- PRIVATE FUNCTIONS ----------
  # ========================================

  defp extract_token(auth) do
    auth
    |> Base.decode64!()
    |> String.split(":")
    |> List.first()
  end
end
