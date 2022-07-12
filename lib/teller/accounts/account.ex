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

    num =
      (ms * account_name_sum(account_name, operation: :multiplication))
      |> IO.inspect()

    cond do
      rem(num, 1000) == 0 ->
        {"depository", "sweep"}

      rem(num, 250) == 0 ->
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

  def last_4(account_name, timestamp) do
    {ms, _} = timestamp.microsecond

    {digits, _} =
      (ms * account_name_sum(account_name))
      |> Integer.digits()
      |> Enum.split(4)

    Integer.undigits(digits)
  end

  def ids(account_name, timestamp) do
    iso = DateTime.to_iso8601(timestamp)
    name_string = account_name_sum(account_name, operation: :addition) |> Integer.to_string()
    seed = iso <> name_string

    account_id = UUID.uuid5(:dns, seed, :slug)
    enrollment_id = UUID.uuid5(:oid, seed, :slug)

    {"acc_" <> account_id, "enr_" <> enrollment_id}
  end

  def institution(account_name, timestamp) do
    # Get miliseconds from timestamp
    {ms, _} = timestamp.microsecond

    # Get sum of alphabet letters from account name
    IO.inspect(account_name_sum(account_name))
    name = choose_from_list(ms, account_name_sum(account_name), institutions())

    %{id: String.downcase(name), name: name}
  end

  def account_name_sum(account_name, opts \\ []) do
    first_name_list =
      account_name
      |> String.upcase()
      |> String.split(" ", trim: true)
      |> List.first()
      |> String.replace([" ", ".", "-"], "")
      |> String.split("", trim: true)

    name_list =
      account_name
      |> String.upcase()
      |> String.replace([" ", ".", "-"], "")
      |> String.split("", trim: true)

    first_name_sum =
      first_name_list
      |> Enum.map(fn letter -> get_alphabet_number(letter) end)
      |> Enum.sum()

    name_sum =
      name_list
      |> Enum.map(fn letter -> get_alphabet_number(letter) end)
      |> Enum.sum()

    case Keyword.get(opts, :operation) do
      :addition -> first_name_sum + name_sum
      :multiplication -> first_name_sum * name_sum
      :division -> first_name_sum / name_sum
      _ -> first_name_sum + name_sum
    end
  end

  def get_alphabet_number(letter) do
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    |> String.split("", trim: true)
    |> Enum.find_index(fn alph_letter -> alph_letter == letter end)
    |> Kernel.+(1)
  end

  # Generic function that takes any two numbers and
  # combines them to choose an item from a list of choices
  defp choose_from_list(num_1, num_2, list, opts \\ []) do
    rem_1 = rem(num_1, length(list)) - 1

    new_number =
      case Keyword.get(opts, :operation) do
        :addition -> rem_1 + num_2
        :multiplication -> rem_1 * num_2
        :division -> rem_1 / num_2
        _ -> rem_1 + num_2
      end

    list_index = rem(new_number, length(list)) - 1
    Enum.at(list, list_index)
  end
end
