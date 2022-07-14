defmodule Teller.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Teller.Accounts.{Account, Balance, Details, Transaction}

  # ===================================
  #   ---------- ACCOUNTS -------------
  # ===================================

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts(~U[2022-07-13 21:56:08.707934Z])
      [%Account{}, ...]

  """
  def list_accounts(timestamp) do
    {:ok, Account.generate_all(timestamp)}
  end

  @doc """
  Gets a single account.

  Raises if the Account does not exist.

  ## Examples

      iex> get_account!("acc_123", ~U[2022-07-13 21:56:08.707934Z])
      %Account{}

  """
  def get_account!(account_id, timestamp) do
    Account.generate_all(timestamp)
    |> Enum.find(fn account -> account.id == account_id end)
  end

  @doc """
  Gets the details of an account

  Raises if the Account does not exist

  ## Examples

      iex> get_details!("acc_123")
      %Details{}

  """
  def get_details!(account_id) do
    Details.generate(account_id)
  end

  @doc """
  Gets the balances of an account

  Raises if the Account does not exist

  ## Examples

      iex> get_balance!("acc_123", ~U[2022-07-13 21:56:08.707934Z])
      %Balance{}

  """
  def get_balance!(account_id, timestamp) do
    # Generate a list of dates 90 days in the past from the day the timestamp was created
    start_date = DateTime.to_date(timestamp) |> Date.add(-90)
    end_date = Date.utc_today()
    range = Date.range(start_date, end_date)

    # Get the Transactions
    transactions = Transaction.generate_for_range(account_id, range)

    # Get the available and ledger balances
    {ledger, available} = Balance.get_ledger_and_available(transactions)

    Balance.generate(account_id, ledger, available)
  end

  # ===================================
  #  ---------- TRANSACTIONS ----------
  # ===================================

  @doc """
  Returns a list of transactions for a given account_id and API key timestamp
  Only returns transactions going back 90 days

  ## Examples

      iex> list_transactions("acc_123", ~U[2022-07-13 21:56:08.707934Z])
      [%Transaction{}, ...]

  """
  def list_transactions(account_id, timestamp) do
    # Generate a list of dates 90 days in the past from the day the timestamp was created
    start_date = DateTime.to_date(timestamp) |> Date.add(-90)
    end_date = Date.utc_today()
    range = Date.range(start_date, end_date)

    # Create the transactions
    Transaction.generate_for_range(account_id, range)
  end

  @doc """
  Gets a single transaction.

  Raises if the Transaction or the Account it belongs to does not exist.

  ## Examples

      iex> get_transaction!("acc_123", "txn_456", ~U[2022-07-13 21:56:08.707934Z])
      %Transaction{}

  """
  def get_transaction!(account_id, transaction_id, timestamp) do
    # Generate a list of dates 90 days in the past from the day the timestamp was created
    start_date = DateTime.to_date(timestamp) |> Date.add(-90)
    end_date = Date.utc_today()
    range = Date.range(start_date, end_date)

    # Create the transactions and find the right one
    Transaction.generate_for_range(account_id, range)
    |> Enum.find(fn transaction -> transaction.id == transaction_id end)
  end
end
