defmodule TellerWeb.TransactionController do
  use TellerWeb, :controller

  alias Teller.Accounts
  alias Teller.Accounts.Transaction

  def index(conn, %{"account_id" => account_id}) do
    transactions = Accounts.list_transactions(account_id)
    render(conn, "index.html", transactions: transactions)
  end

  def show_for_account(conn, %{"account_id" => account_id}) do
    transactions = Accounts.list_transactions(account_id)
    render(conn, "index.html", transactions: transactions)
  end

  def show(conn, %{"account_id" => account_id, "transaction_id" => transaction_id}) do
    transaction = Accounts.get_transaction!(account_id, transaction_id)
    render(conn, "show.html", transaction: transaction)
  end
end
