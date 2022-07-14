defmodule Teller.Accounts.Balance do
  defstruct account_id: nil, available: nil, ledger: nil, links: []

  @type t :: %__MODULE__{
          account_id: String.t(),
          available: Float.t(),
          ledger: Float.t(),
          links: %{
            account: String.t(),
            self: String.t()
          }
        }

  def generate(account_id, ledger, available) do
    %__MODULE__{
      account_id: account_id,
      available: available,
      ledger: ledger,
      links: %{
        account: "localhost:4000/api/accounts/" <> account_id,
        self: "localhost:4000/api/accounts/" <> account_id <> "/balances"
      }
    }
  end

  def get_ledger_and_available(transactions) do
    ledger = transactions |> List.last() |> Map.get(:running_balance)

    pending_amount =
      transactions
      |> Enum.filter(fn transaction -> transaction.status == "pending" end)
      |> Enum.map(fn transaction -> transaction.amount end)
      |> Enum.sum()

    available = (ledger - pending_amount) |> Float.round(2)

    {ledger, available}
  end
end
