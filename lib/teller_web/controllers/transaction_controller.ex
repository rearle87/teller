defmodule TellerWeb.TransactionController do
  use TellerWeb, :controller

  alias Teller.Accounts

  def show_for_account(conn, %{"account_id" => account_id}) do
    transactions = Accounts.list_transactions(account_id, conn.assigns.token_timestamp)

    conn
    |> put_status(:accepted)
    |> json(transactions)
  end

  def show(conn, %{"account_id" => account_id, "transaction_id" => transaction_id}) do
    transaction =
      Accounts.get_transaction!(account_id, transaction_id, conn.assigns.token_timestamp)

    conn
    |> put_status(:accepted)
    |> json(transaction)
  end
end
