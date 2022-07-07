defmodule Teller.AccountsTest do
  use Teller.DataCase

  alias Teller.Accounts

  describe "accounts" do
    alias Teller.Accounts.Account

    import Teller.AccountsFixtures

    @invalid_attrs %{}

    test "list_accounts/0 returns all accounts" do
      account = account_fixture()
      assert Accounts.list_accounts() == [account]
    end

    test "get_account!/1 returns the account with given id" do
      account = account_fixture()
      assert Accounts.get_account!(account.id) == account
    end
  end

  describe "transactions" do
    alias Teller.Accounts.Transaction

    import Teller.AccountsFixtures

    @invalid_attrs %{}

    test "list_transactions/0 returns all transactions" do
      transaction = transaction_fixture()
      assert Accounts.list_transactions() == [transaction]
    end

    test "get_transaction!/1 returns the transaction with given id" do
      transaction = transaction_fixture()
      assert Accounts.get_transaction!(transaction.id) == transaction
    end
  end
end
