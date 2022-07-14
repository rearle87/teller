defmodule Teller.Accounts.Account do
  @derive Jason.Encoder
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

  def generate(account_name, timestamp) do
    {account_id, enrollment_id} = ids(account_name, timestamp)
    seed = Variance.id_to_number(account_id)
    {type, subtype} = type_and_subtype(seed, account_name)

    %__MODULE__{
      id: account_id,
      enrollment_id: enrollment_id,
      institution: institution(seed),
      last_four: last_four(seed),
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

  def generate_all(timestamp) do
    names = [
      "My Checking",
      "Jimmy Carter",
      "Ronald Reagan",
      "George H. W. Bush",
      "Bill Clinton",
      "George W. Bush",
      "Barack Obama",
      "Donald Trump"
    ]

    Enum.map(names, fn name -> generate(name, timestamp) end)
  end

  def starting_balance(account_id) do
    {balance, _} =
      account_id
      |> Variance.id_to_number()
      |> Variance.split_seed(7)

    Float.round(balance / 100, 2)
  end

  # ========================================
  #  ---------- PRIVATE FUNCTIONS ----------
  # ========================================

  defp ids(account_name, timestamp) do
    IO.inspect(timestamp)
    string = account_name <> DateTime.to_iso8601(timestamp)

    account_id = UUID.uuid5(:dns, string, :slug)
    enrollment_id = UUID.uuid5(:oid, string, :slug)

    {"acc_" <> account_id, "enr_" <> enrollment_id}
  end

  defp type_and_subtype(seed, account_name) do
    {num, _} = Variance.split_seed(seed, 6)

    # Determine the type of account. For verisimilitude's sake:
    # "My Checking" should always be "checking"
    # "Treastury" and "Sweep" should be very rare
    # "CDs" and "Money Markets" should be rare
    # "Savings" should be uncommon
    # "Checking" and "Credit Card" should be equally likely
    cond do
      account_name == "My Checking" ->
        {"depository", "checking"}

      rem(num, 50) == 0 ->
        {"depository", "sweep"}

      rem(num, 25) == 0 ->
        {"depository", "treasury"}

      rem(num, 10) == 0 ->
        {"depository", "certificate_of_deposit"}

      rem(num, 5) == 0 ->
        {"depository", "money_market"}

      rem(num, 3) == 0 ->
        {"depository", "savings"}

      rem(num, 2) == 0 ->
        {"depository", "checking"}

      true ->
        {"credit", "credit_card"}
    end
  end

  defp last_four(seed) do
    {_, num} = Variance.split_seed(seed, 6)

    {digits, _} =
      num
      |> Integer.digits()
      |> Enum.split(4)

    Integer.undigits(digits)
  end

  defp institution(seed) do
    institutions = ["Chase", "Bank of America", "Wells Fargo", "Citibank", "Capital One"]
    {num_1, num_2} = Variance.split_seed(seed, 2)
    name = Variance.choose_from_list(num_1, num_2, institutions, op: :add)

    %{id: String.downcase(name), name: name}
  end
end
