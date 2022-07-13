defmodule Teller.Accounts.Account do
  @enforce_keys [:id, :enrollment_id, :institution, :last_four]
  defstruct id: nil,
            enrollment_id: nil,
            currency: "USD",
            institution: nil,
            last_four: nil,
            links: [],
            name: "My Checking",
            type: "depository",
            subtype: "checking"

  @type t :: %__MODULE__{
          id: String.t(),
          enrollment_id: String.t(),
          name: String.t(),
          currency: String.t(),
          institution: %{
            id: String.t(),
            name: String.t()
          },
          last_four: integer(),
          links: %{
            balances: String.t(),
            details: String.t(),
            self: String.t(),
            transactions: String.t()
          },
          type: String.t(),
          subtype: String.t()
        }

  alias Teller.Accounts.Variance

  def account_names do
    [
      "My Checking",
      "Jimmy Carter",
      "Ronald Reagan",
      "George H. W. Bush",
      "Bill Clinton",
      "George W. Bush",
      "Barack Obama",
      "Donald Trump"
    ]
  end

  def institutions do
    ["Chase", "Bank of America", "Wells Fargo", "Citibank", "Capital One"]
  end

  def account_subtypes do
    ["checking", "savings", "money_market", "certificate_of_deposit", "treasury", "sweep"]
  end

  def generate_for_all(timestamp) do
    account_names()
    |> Enum.map(fn name -> generate(name, timestamp) end)
  end

  def generate(account_name, timestamp) do
    {account_id, enrollment_id} = ids(account_name, timestamp)
    {type, subtype} = type_and_subtype(account_name, timestamp)

    %__MODULE__{
      id: account_id,
      enrollment_id: enrollment_id,
      institution: institution(account_name, timestamp),
      last_four: last_4(account_name, timestamp),
      name: account_name,
      type: type,
      subtype: subtype,
      links: %{
        balances: "localhost:4000/api/accounts/" <> account_id <> "/balances",
        details: "localhost:4000/api/accounts/" <> account_id <> "/details",
        self: "localhost:4000/api/accounts/" <> account_id,
        transactions: "localhost:4000/api/accounts/" <> account_id <> "/transactions"
      }
    }
  end

  def type_and_subtype(account_name, timestamp) do
    {ms, _} = timestamp.microsecond

    account_name_number =
      Variance.number_from_account_name(account_name, word_op: :add, comb_op: :add)

    num =
      (ms + account_name_number + String.length(account_name))
      |> IO.inspect()
      |> Integer.digits()
      |> List.last()

    cond do
      account_name == "My Checking" ->
        {"depository", "checking"}

      rem(num, 25) == 0 ->
        {"depository", "sweep"}

      rem(num, 10) == 0 ->
        {"depository", "treasury"}

      rem(num, 8) == 0 ->
        {"depository", "certificate_of_deposit"}

      rem(num, 4) == 0 ->
        {"depository", "money_market"}

      rem(num, 3) == 0 ->
        {"depository", "savings"}

      rem(num, 2) == 0 ->
        {"depository", "checking"}

      true ->
        {"credit", "credit_card"}
    end
  end

  def last_4(account_name, timestamp) do
    {ms, _} = timestamp.microsecond

    {digits, _} =
      (ms * Variance.number_from_account_name(account_name, word_op: :add, comb_op: :add))
      |> Integer.digits()
      |> Enum.split(4)

    Integer.undigits(digits)
  end

  def ids(account_name, timestamp) do
    iso = DateTime.to_iso8601(timestamp)

    name_string =
      Variance.number_from_account_name(account_name, word_op: :add, comb_op: :add)
      |> Integer.to_string()

    seed = iso <> name_string

    account_id = UUID.uuid5(:dns, seed, :slug)
    enrollment_id = UUID.uuid5(:oid, seed, :slug)

    {"acc_" <> account_id, "enr_" <> enrollment_id}
  end

  def institution(account_name, timestamp) do
    # Get miliseconds from timestamp
    {ms, _} = timestamp.microsecond

    # Get sum of alphabet letters from account name
    account_name_number =
      Variance.number_from_account_name(account_name, word_op: :add, comb_op: :add)

    name = Variance.choose_from_list(ms, account_name_number, institutions(), op: :add)

    %{id: String.downcase(name), name: name}
  end
end
