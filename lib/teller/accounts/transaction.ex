defmodule Teller.Accounts.Transaction do
  @derive Jason.Encoder
  defstruct account_id: nil,
            amount: nil,
            date: nil,
            description: nil,
            details: %{},
            processing_status: "complete",
            id: nil,
            links: %{},
            running_balance: 0,
            status: "posted",
            type: "card_payment"

  @type t :: %__MODULE__{
          account_id: String.t(),
          id: String.t(),
          amount: Float.t(),
          date: String.t(),
          description: String.t(),
          details: %{
            category: String.t(),
            counterparty: %{
              name: String.t(),
              type: String.t()
            }
          },
          processing_status: String.t(),
          links: %{
            account: String.t(),
            self: String.t()
          },
          running_balance: Float.t(),
          status: String.t(),
          type: String.t()
        }

  alias Teller.Accounts.{Variance, Account}

  def generate(account_id, date, transaction_number) do
    # Get transaction_id & seed from that id
    id = id(account_id, date, transaction_number)
    seed = Variance.id_to_number(id)

    # Build the struct
    # Note: transactions in the last two days are "pending".
    status = if Date.diff(Date.utc_today(), date) < 2, do: "pending", else: "posted"
    {description, details} = description_and_details(seed, transaction_number)

    %__MODULE__{
      account_id: account_id,
      id: id,
      amount: amount(seed, transaction_number),
      date: Date.to_iso8601(date),
      description: description,
      details: details,
      links: %{
        self: "localhost:4000/api/accounts/" <> account_id <> "/transactions/" <> id,
        account: "localhost:4000/api/accounts/" <> account_id
      },
      status: status
    }
  end

  def generate_for_range(account_id, range, opts \\ []) do
    {transactions, _} =
      range

      # Generate transactions
      |> Enum.flat_map(fn date ->
        transaction_count = count_for_day(account_id, date)
        list = if transaction_count == 0, do: [], else: Enum.to_list(1..transaction_count)

        Enum.map(list, fn transaction_number ->
          generate(account_id, date, transaction_number)
        end)
      end)
      |> Enum.with_index(fn transaction, index -> {index, transaction} end)

      # Calculate the balances
      |> Enum.map_reduce(0, fn {index, transaction}, acc ->
        acc =
          if index == 0,
            do: Account.starting_balance(account_id) + transaction.amount,
            else: acc + transaction.amount

        acc = Float.round(acc, 2)

        {Map.put(transaction, :running_balance, acc), acc}
      end)

    # Pagination Controls
    from_id = Keyword.get(opts, :from_id)
    transactions = if from_id, do: start_list_at(transactions, from_id), else: transactions

    count = Keyword.get(opts, :count)
    if count, do: paginate(transactions, count), else: transactions
  end

  # =============================================================
  #  ---------- PRIVATE FUNCTIONS - SINGLE TRANSACTION ----------
  # =============================================================

  defp id(account_id, date, transaction_number) do
    string =
      (Date.day_of_week(date) * date.day * transaction_number + date.month)
      |> Integer.to_string()

    combined_string = account_id <> string

    id = UUID.uuid5(:oid, combined_string, :slug)
    "txn_" <> id
  end

  defp amount(seed, transaction_number) do
    # Get seeds
    {size_seed, amount_seed} = Variance.split_seed(seed, transaction_number + 5)

    # Determine size of the transaction. For verisimilitude's sake:
    # 5 digits (i.e. in the 100s) are rare
    # 4 digit (i.e. in the 10s) are common
    # 3 digit (i.e. less than 10) are less common, but still frequent
    # N.B. This works well for USD, GBP, and other strong currencies.
    # More inflated currencies should probably have different weights. That's a problem for another time.
    sig_digits =
      cond do
        rem(size_seed, 5) == 0 -> 5
        rem(size_seed, 3) == 0 -> 3
        true -> 4
      end

    # Take the amount_seed, and starting with the second digit,
    # reverse the digits in chunks of x, where x is the number of digits
    # Then take the correct number of digits from the front of the resulting list
    {digits, _} =
      amount_seed
      |> Integer.digits()
      |> Enum.reverse_slice(1, sig_digits)
      |> Enum.split(sig_digits)

    # Take the resulting list of digits and turn them into a Float with two decimal places
    int = Integer.undigits(digits)

    -(int / 100)
  end

  defp count_for_day(account_id, date) do
    # Get a seed number from the account_id and the date
    string = account_id <> Date.to_iso8601(date)
    seed = UUID.uuid5(:oid, string, :slug) |> Variance.id_to_number()

    # Get two three digit numbers by pulling digits out of the seed
    {num_1, num_2} = Variance.split_seed(seed, 3)

    Variance.choose_from_list(
      num_1,
      num_2,
      [0, 1, 2, 3, 4, 5],
      op: :add
    )
  end

  defp description_and_details(seed, transaction_number) do
    merchants = [
      %{name: "Uber", category: "transportation"},
      %{name: "Uber Eats", category: "dining"},
      %{name: "Lyft", category: "transportation"},
      %{name: "Five Guys", category: "dining"},
      %{name: "In-N-Out Burger", category: "dining"},
      %{name: "Chick-Fil-A", category: "dining"},
      %{name: "Apple", category: "electronics"},
      %{name: "Amazon", category: "shopping"},
      %{name: "Walmart", category: "shopping"},
      %{name: "Target", category: "shopping"},
      %{name: "Hotel Tonight", category: "accommodation"},
      %{name: "Misson Ceviche", category: "dining"},
      %{name: "Caltrain", category: "transportation"},
      %{name: "Wingstop", category: "dining"},
      %{name: "Slim Chickens", category: "dining"},
      %{name: "CVS", category: "health"},
      %{name: "Duane Reade", category: "health"},
      %{name: "Walgreens", category: "health"},
      %{name: "McDonald's", category: "dining"},
      %{name: "Burger King", category: "dining"},
      %{name: "KFC", category: "dining"},
      %{name: "Popeye's", category: "dining"},
      %{name: "Shake Shack", category: "dining"},
      %{name: "Lowe's", category: "home"},
      %{name: "Costco", category: "groceries"},
      %{name: "Kroger", category: "groceries"},
      %{name: "iTunes", category: "software"},
      %{name: "Spotify", category: "software"},
      %{name: "Best Buy", category: "electronics"},
      %{name: "TJ Maxx", category: "clothing"},
      %{name: "Aldi", category: "groceries"},
      %{name: "Dollar General", category: "general"},
      %{name: "Macy's", category: "clothing"},
      %{name: "H.E. Butt", category: "groceries"},
      %{name: "Dollar Tree", category: "general"},
      %{name: "Verizon Wireless", category: "phone"},
      %{name: "Sprint PCS", category: "phone"},
      %{name: "T-Mobile", category: "phone"},
      %{name: "Starbucks", category: "dining"},
      %{name: "7-Eleven", category: "general"},
      %{name: "AT&T Wireless", category: "phone"},
      %{name: "Rite Aid", category: "health"},
      %{name: "Nordstrom", category: "clothing"},
      %{name: "Ross", category: "clothing"},
      %{name: "Gap", category: "clothing"},
      %{name: "Bed, Bath & Beyond", category: "homme"},
      %{name: "J.C. Penney", category: "clothing"},
      %{name: "Subway", category: "dining"},
      %{name: "O'Reilly", category: "transportation"},
      %{name: "Wendy's", category: "dining"},
      %{name: "Dunkin' Donuts", category: "dining"},
      %{name: "Petsmart", category: "shopping"},
      %{name: "Dick's Sporting Goods", category: "entertainment"},
      %{name: "Sears", category: "home"},
      %{name: "Staples", category: "office"},
      %{name: "Domino's Pizza", category: "dining"},
      %{name: "Pizza Hut", category: "dining"},
      %{name: "Papa John's", category: "dining"},
      %{name: "IKEA", category: "home"},
      %{name: "Office Depot", category: "office"},
      %{name: "Foot Locker", category: "clothing"},
      %{name: "Lids", category: "clothing"},
      %{name: "GameStop", category: "entertainment"},
      %{name: "Sephora", category: "shopping"},
      %{name: "Panera", category: "dining"},
      %{name: "Williams-Sonoma", category: "home"},
      %{name: "Saks Fifth Avenue", category: "clothing"},
      %{name: "Chipotle Mexican Grill", category: "dining"},
      %{name: "Neiman Marcus", category: "clothing"},
      %{name: "Jack In The Box", category: "dining"},
      %{name: "Sonic", category: "dining"},
      %{name: "Shell", category: "fuel"}
    ]

    {num_1, num_2} = Variance.split_seed(seed, transaction_number)
    merchant = Variance.choose_from_list(num_1, num_2, merchants, op: :add)

    {merchant.name,
     %{
       category: merchant.category,
       counterparty: %{
         name: String.upcase(merchant.name),
         type: "organization"
       }
     }}
  end

  # ===========================================================
  #  ---------- PRIVATE FUNCTIONS - TRANSACTION LIST ----------
  # ===========================================================

  def start_list_at(transactions, from_id) do
    starting_index =
      Enum.find_index(transactions, fn transaction ->
        transaction.id == from_id
      end)

    # Split the list, and ensure that the first result is
    # the transaction BEFORE the one requested
    split_index = if starting_index == 0, do: 0, else: starting_index - 1
    {_, new_transactions} = Enum.split(transactions, split_index)

    new_transactions
  end

  def paginate(transactions, count) do
    {transactions, _} = Enum.split(transactions, count)
    Enum.split(transactions, count) |> IO.inspect()
    transactions
  end
end
