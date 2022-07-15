defmodule TellerWeb.TransactionController do
  use TellerWeb, :controller

  alias Teller.Accounts

  def show_for_account(conn, %{"account_id" => account_id}) do
    # Get query params
    from_id = Map.get(conn.query_params, "from_id")
    count = Map.get(conn.query_params, "count")

    opts = if from_id, do: [from_id: from_id], else: []
    opts = if count, do: opts ++ [count: String.to_integer(count)], else: opts

    with {:ok, transactions} <-
           Accounts.list_transactions(account_id, conn.assigns.token_timestamp, opts) do
      conn
      |> put_status(:accepted)
      |> json(transactions)
    else
      {_, error} ->
        conn
        |> put_status(:not_found)
        |> json(error: error)
    end
  end

  def show(conn, %{"account_id" => account_id, "transaction_id" => transaction_id}) do
    with {:ok, transaction} <-
           Accounts.get_transaction(account_id, transaction_id, conn.assigns.token_timestamp) do
      conn
      |> put_status(:accepted)
      |> json(transaction)
    else
      {_, error} ->
        conn
        |> put_status(:not_found)
        |> json(error: error)
    end
  end
end
