defmodule Teller.AccountsTest do
  use ExUnit.Case, aync: true

  alias Teller.Accounts

  @timestamp DateTime.from_iso8601("2022-07-15T18:08:06.088293Z")
  @account_1 %{id: "acc_9hve8a3eXgKl1XLjlNipPQ"}
  @account_2 %{id: "acc_PsQ0x-3VX4KXSmHLjaqpbw"}

  describe "accounts" do
    test "list_accounts/0 returns all accounts" do
      {:ok, timestamp, _} = @timestamp
      {:ok, accounts} = Accounts.list_accounts(timestamp)

      are_accounts =
        Enum.map(accounts, fn account ->
          %type{} = account
          Teller.Accounts.Account == type
        end)

      assert length(accounts) == 8
      assert !Enum.member?(are_accounts, false)
    end

    test "get_account/1 returns the account with given id" do
      {:ok, timestamp, _} = @timestamp
      {:ok, account_1} = Accounts.get_account(@account_1.id, timestamp)
      {:ok, account_2} = Accounts.get_account(@account_2.id, timestamp)

      %type{} = account_1

      assert type == Teller.Accounts.Account
      assert account_1.id == @account_1.id
      assert account_1 !== account_2
    end

    test "get_details/1 returns the details with given id" do
      {:ok, details_1} = Accounts.get_details(@account_1.id)
      {:ok, details_2} = Accounts.get_details(@account_2.id)

      %type{} = details_1

      assert type == Teller.Accounts.Details
      assert details_1.account_id == @account_1.id
      assert details_1 !== details_2
    end

    test "get_balances/1 returns the balances with given id" do
      {:ok, timestamp, _} = @timestamp
      {:ok, balance_1} = Accounts.get_balance(@account_1.id, timestamp)
      {:ok, balance_2} = Accounts.get_balance(@account_2.id, timestamp)

      %type{} = balance_1

      assert type == Teller.Accounts.Balance
      assert balance_1.account_id == @account_1.id
      assert balance_1 !== balance_2
    end
  end

  describe "transactions" do
    test "list_transactions/2 returns all transactions" do
      {:ok, timestamp, _} = @timestamp
      {:ok, transactions} = Accounts.list_transactions(@account_1.id, timestamp)

      unique_transactions = Enum.uniq(transactions)

      date_counts =
        transactions
        |> Enum.group_by(fn transaction -> transaction.date end)
        |> Map.to_list()
        |> Enum.map(fn {k, v} -> Enum.count(v) end)
        |> Enum.map(fn count -> Enum.member?([1, 2, 3, 4, 5], count) end)

      date_counts_are_less_than_five = if !Enum.member?(date_counts, false), do: true, else: false

      assert transactions == unique_transactions
      assert date_counts_are_less_than_five
    end

    test "list_transactions/2 with from_id returns that as second transaction in list" do
      {:ok, timestamp, _} = @timestamp
      {:ok, transactions} = Accounts.list_transactions(@account_1.id, timestamp)

      transaction_50 = transactions |> Enum.at(50)

      {:ok, transactions} =
        Accounts.list_transactions(@account_1.id, timestamp, from_id: transaction_50.id)

      transaction_2 = transactions |> Enum.at(1)

      assert transaction_50 == transaction_2
    end

    test "list_transactions/2 with count returns that many transactions" do
      {:ok, timestamp, _} = @timestamp
      count = 10
      {:ok, transactions} = Accounts.list_transactions(@account_1.id, timestamp, count: count)

      assert length(transactions) == count
    end

    test "get_transaction!/3 returns the transaction with given id" do
      {:ok, timestamp, _} = @timestamp
      {:ok, transactions} = Accounts.list_transactions(@account_1.id, timestamp)

      transaction_50 = transactions |> Enum.at(50)

      {:ok, new_transaction} =
        Accounts.get_transaction(@account_1.id, transaction_50.id, timestamp)

      assert transaction_50 == new_transaction
    end
  end
end
