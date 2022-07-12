defmodule TellerWeb.AccountController do
  use TellerWeb, :controller

  alias Teller.Accounts
  alias Teller.Accounts.Account

  def index(conn, _params) do
    accounts = Accounts.list_accounts()
    render(conn, "index.html", accounts: accounts)
  end

  def show(conn, %{"id" => id}) do
    # account = Accounts.get_account!(id)
    # render(conn, "show.html", account: account)

    json(conn, %{assigns: conn.assigns})
  end
end
