defmodule TellerWeb.APITokenController do
  use TellerWeb, :controller

  def new(conn, _params) do
    datetime = DateTime.now!("Etc/UTC") |> DateTime.to_iso8601()
    token = Phoenix.Token.encrypt(TellerWeb.Endpoint, "accounts", datetime)

    token = "test_" <> token
    json(conn, %{token: token})
  end
end
