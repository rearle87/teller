defmodule Teller.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Teller.Accounts` context.
  """

  @doc """
  Generate a account.
  """
  def account_fixture(attrs \\ %{}) do
    {:ok, account} =
      attrs
      |> Enum.into(%{

      })
      |> Teller.Accounts.create_account()

    account
  end

  @doc """
  Generate a transaction.
  """
  def transaction_fixture(attrs \\ %{}) do
    {:ok, transaction} =
      attrs
      |> Enum.into(%{

      })
      |> Teller.Accounts.create_transaction()

    transaction
  end
end
