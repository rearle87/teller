defmodule Teller.Accounts.Details do
  defstruct account_id: nil,
            account_number: nil,
            links: [],
            routing_numbers: %{}

  @type t :: %__MODULE__{
          account_id: String.t(),
          account_number: integer(),
          links: %{
            account: String.t(),
            self: String.t()
          },
          routing_numbers: %{
            ach: integer(),
            wire: integer()
          }
        }

  alias Teller.Accounts.{Account, Variance}

  def generate(account_name, timestamp) do
    {account_id, _} = Account.ids(account_name, timestamp)
    {account_number, routing_numbers} = account_and_routing(account_name, timestamp)

    %__MODULE__{
      account_id: account_id,
      account_number: account_number,
      links: %{
        account: "localhost:4000/api/accounts/" <> account_id,
        self: "localhost:4000/api/accounts/" <> account_id <> "/details"
      },
      routing_numbers: routing_numbers
    }
  end

  def account_and_routing(account_name, timestamp) do
    {ms, _} = timestamp.microsecond

    ms = if ms == 0, do: 9999, else: ms
    sec = if timestamp.second == 0, do: 59, else: timestamp.second
    min = if timestamp.minute == 0, do: 45, else: timestamp.minute
    hour = if timestamp.hour == 0, do: 21, else: timestamp.hour
    day = if timestamp.day == 0, do: 23, else: timestamp.day
    month = if timestamp.month == 0, do: 11, else: timestamp.month

    account_name_num =
      Variance.number_from_account_name(account_name, word_op: :mult, comb_op: :mult)

    # Account Number
    {account_digits, _} =
      (account_name_num * ms * sec * month) |> Integer.digits() |> Enum.split(11)

    account_number = Integer.undigits(account_digits)

    # ACH Routing Number
    {ach_digits, _} =
      (account_name_num * month * day * min * 13) |> Integer.digits() |> Enum.split(9)

    ach_number = Integer.undigits(ach_digits)

    # Wire Routing Number
    {wire_digits, _} =
      (account_name_num * hour * month * day * ms)
      |> Integer.digits()
      |> Enum.split(9)

    wire_number = Integer.undigits(wire_digits)

    # Return a tuple of the account number and routing numbers
    {account_number, %{ach: ach_number, wire: wire_number}}
  end
end
