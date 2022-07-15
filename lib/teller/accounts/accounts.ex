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
      {:ok, [%Account{}, ...]}

  """
  def list_accounts(timestamp) do
    result = Account.generate_all(timestamp)

    case result do
      {:ok, _} -> result
      {:error, message} -> message
    end
  end

  @doc """
  Gets a single account.

  Raises if the Account does not exist.

  ## Examples

      iex> get_account!("acc_123", ~U[2022-07-13 21:56:08.707934Z])
      {:ok, %Account{}}

  """
  def get_account(account_id, timestamp) do
    result = Account.generate_all(timestamp)

    case result do
      {:ok, accounts} ->
        account = Enum.find(accounts, fn account -> account.id == account_id end)

        case account do
          %Account{} -> {:ok, account}
          _ -> {:error, "Account does not exist"}
        end

      {:error, message} ->
        message
    end
  end

  @doc """
  Gets the details of an account

  Raises if the Account does not exist

  ## Examples

      iex> get_details!("acc_123")
      {:ok, %Details{}}

  """
  def get_details(account_id) do
    if Account.is_valid_id(account_id) do
      {:ok, Details.generate(account_id)}
    else
      {:error, "account_id must be a string that beings with acc_"}
    end
  end

  @doc """
  Gets the balances of an account

  Raises if the Account does not exist

  ## Examples

      iex> get_balance!("acc_123", ~U[2022-07-13 21:56:08.707934Z])
      {:ok, %Balance{}}

  """
  def get_balance(account_id, timestamp) do
    # Generate a list of dates 90 days in the past from the day the timestamp was created
    start_date = DateTime.to_date(timestamp) |> Date.add(-90)
    end_date = Date.utc_today()
    range = Date.range(start_date, end_date)

    with true <- Account.is_valid_id(account_id),
         {:ok, transactions} <- Transaction.generate_for_range(account_id, range) do
      # Get the available and ledger balances
      {ledger, available} = Balance.get_ledger_and_available(transactions)
      {:ok, Balance.generate(account_id, ledger, available)}
    else
      err -> err
    end
  end

  # ===================================
  #  ---------- TRANSACTIONS ----------
  # ===================================

  @doc """
  Returns a list of transactions for a given account_id and API key timestamp
  Only returns transactions going back 90 days

  ## Examples

      iex> list_transactions("acc_123", ~U[2022-07-13 21:56:08.707934Z])
      {:ok, [%Transaction{}, ...]}

  """
  def list_transactions(account_id, timestamp, opts \\ []) do
    # Generate a list of dates 90 days in the past from the day the timestamp was created
    start_date = DateTime.to_date(timestamp) |> Date.add(-90)
    end_date = Date.utc_today()
    range = Date.range(start_date, end_date)

    # Create the transactions
    if Account.is_valid_id(account_id) do
      results = Transaction.generate_for_range(account_id, range, opts)

      case results do
        {:ok, _} -> results
        {:error, _} -> results
      end
    else
      {:error, "Account ID is not valid"}
    end
  end

  @doc """
  Gets a single transaction.

  Raises if the Transaction or the Account it belongs to does not exist.

  ## Examples

      iex> get_transaction!("acc_123", "txn_456", ~U[2022-07-13 21:56:08.707934Z])
      {:ok, %Transaction{}}

  """
  def get_transaction(account_id, transaction_id, timestamp) do
    # Generate a list of dates 90 days in the past from the day the timestamp was created
    start_date = DateTime.to_date(timestamp) |> Date.add(-90)
    end_date = Date.utc_today()
    range = Date.range(start_date, end_date)

    # Create the transactions and find the right one
    with true <- Account.is_valid_id(account_id),
         true <- Transaction.is_valid_id(transaction_id),
         {:ok, transactions} <- Transaction.generate_for_range(account_id, range) do
      result =
        transactions
        |> Enum.find(fn transaction -> transaction.id == transaction_id end)

      case result do
        %Transaction{} -> {:ok, result}
        _ -> {:error, "transaction not found"}
      end
    else
      err -> err
    end
  end
end
