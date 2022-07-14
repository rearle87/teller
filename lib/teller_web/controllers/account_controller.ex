defmodule TellerWeb.AccountController do
  use TellerWeb, :controller

  alias Teller.Accounts

  def index(conn, _params) do
    with {:ok, accounts} <- Accounts.list_accounts(conn.assigns.token_timestamp) do
      conn
      |> put_status(:accepted)
      |> json(accounts)
    end
  end

  def show(conn, %{"id" => account_id}) do
    account = Accounts.get_account!(account_id, conn.assigns.token_timestamp)

    conn
    |> put_status(:accepted)
    |> json(account)
  end

  def show_details(conn, %{"account_id" => account_id}) do
    details = Accounts.get_details!(account_id)

    conn
    |> put_status(:accepted)
    |> json(details)
  end

  def show_balance(conn, %{"account_id" => account_id}) do
    balance = Accounts.get_balance!(account_id, conn.assigns.token_timestamp)

    conn
    |> put_status(:accepted)
    |> json(balance)
  end
end
