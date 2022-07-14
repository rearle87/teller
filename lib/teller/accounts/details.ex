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

  alias Teller.Accounts.Variance

  def generate(account_id) do
    seed = Variance.id_to_number(account_id)
    {account_number, routing_numbers} = account_and_routing(seed)

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

  # ========================================
  #  ---------- PRIVATE FUNCTIONS ----------
  # ========================================

  defp account_and_routing(seed) do
    # Take the account_id seed and split it into 3 smaller numbers
    {account_seed, ach_and_wire_seed} = Variance.split_seed(seed, 11)
    {ach_seed, wire_seed} = Variance.split_seed(ach_and_wire_seed, 9)

    # Use those three smaller numbers to create account and routing numbers out of new UUIDs
    # This way, the account_num, ach_num, and wire_num aren't at risk of looking like the last_4
    account_num = create_number(account_seed, 11)
    ach_num = create_number(ach_seed, 9)
    wire_num = create_number(wire_seed, 9)

    # Return the correct numbers
    {account_num, %{ach: ach_num, wire: wire_num}}
  end

  defp create_number(seed, digits) do
    # Take the seed, turn it into a new UUID,
    # Turn that UUID back into another number,
    # and chop that new number to the appropriate number of digits
    id = UUID.uuid5(:oid, Integer.to_string(seed), :slug)
    {num, _} = ("num_" <> id) |> Variance.id_to_number() |> Variance.split_seed(digits)

    num
  end
end
