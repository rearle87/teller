defmodule Teller.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Teller.Accounts.Account

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts do
    raise "TODO"
  end

  @doc """
  Gets a single account.

  Raises if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

  """
  def get_account!(id), do: raise("TODO")

  @doc """
  Creates a account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, ...}

  """

  alias Teller.Accounts.Transaction

  @doc """
  Returns a list of transactions for a given account_id and API key timestamp
  Only returns transactions going back 90 days

  ## Examples

      iex> list_transactions()
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

  Raises if the Transaction does not exist.

  ## Examples

      iex> get_transaction!(123)
      %Transaction{}

  """
  def get_transaction!(account_id, transaction_id), do: raise("TODO")

  @doc """
  Creates a transaction.

  ## Examples

      iex> create_transaction(%{field: value})
      {:ok, %Transaction{}}

      iex> create_transaction(%{field: bad_value})
      {:error, ...}

  """
end
