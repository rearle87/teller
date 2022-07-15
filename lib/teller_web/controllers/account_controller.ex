defmodule TellerWeb.AccountController do
  use TellerWeb, :controller

  alias Teller.Accounts

  def index(conn, _params) do
    with {:ok, accounts} <- Accounts.list_accounts(conn.assigns.token_timestamp) do
      conn
      |> put_status(:accepted)
      |> json(%{"data" => accounts})
    else
      {_, error} ->
        conn
        |> put_status(:not_found)
        |> json(%{"error" => error})
    end
  end

  def show(conn, %{"id" => account_id}) do
    with {:ok, account} <- Accounts.get_account(account_id, conn.assigns.token_timestamp) do
      conn
      |> put_status(:accepted)
      |> json(%{"data" => account})
    else
      {_, error} ->
        conn
        |> put_status(:not_found)
        |> json(%{"error" => error})
    end
  end

  def show_details(conn, %{"account_id" => account_id}) do
    with {:ok, details} <- Accounts.get_details(account_id) do
      conn
      |> put_status(:accepted)
      |> json(%{"data" => details})
    else
      {_, error} ->
        conn
        |> put_status(:not_found)
        |> json(%{"error" => error})
    end
  end

  def show_balance(conn, %{"account_id" => account_id}) do
    with {:ok, balance} <- Accounts.get_balance(account_id, conn.assigns.token_timestamp) do
      conn
      |> put_status(:accepted)
      |> json(%{"data" => balance})
    else
      {_, error} ->
        conn
        |> put_status(:not_found)
        |> json(%{"error" => error})
    end
  end
end
