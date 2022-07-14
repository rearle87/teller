defmodule Teller.Accounts.Transaction do
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

  def merchants do
    [
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
  end

  def generate(account_id, timestamp, date, transaction_number) do
    account_name = Account.get_name_from_id(account_id, timestamp)

    {description, details} =
      description_and_details(account_name, timestamp, date, transaction_number)

    id = id(account_id, date, transaction_number)
    status = if Date.diff(Date.utc_today(), date) < 2, do: "pending", else: "posted"

    Date.diff(date, Date.utc_today())

    %__MODULE__{
      account_id: account_id,
      id: id,
      amount: amount(account_name, timestamp, date, transaction_number),
      date: Date.to_iso8601(date),
      description: description,
      details: details,
      links: %{
        self: "localhost:4000/api/accounts/" <> account_id <> "/transactions" <> id,
        account: "localhost:4000/api/accounts/" <> account_id
      },
      status: status
    }
  end

  def generate_for_range(range, account_name, account_id, timestamp) do
    Enum.flat_map(range, fn date ->
      transaction_count = count_for_day(account_name, timestamp, date)

      Enum.to_list(1..transaction_count)
      |> Enum.map(fn transaction_number ->
        generate(account_id, timestamp, date, transaction_number)
      end)
    end)
  end

  def generate_balances(transaction_list, account_name, timestamp) do
    Enum.map_reduce(transaction_list, 0, fn {index, transaction}, acc ->
      acc =
        if index == 0,
          do:
            (Account.starting_balance(account_name, timestamp) * 100 + transaction.amount * 100) /
              100,
          else: (acc * 100 + transaction.amount * 100) / 100

      {Map.put(transaction, :running_balance, acc), acc}
    end)
  end

  def id(account_id, date, transaction_number) do
    string =
      (Date.day_of_week(date) + Date.day_of_year(date) + date.day +
         date.month * transaction_number)
      |> Integer.to_string()

    seed = account_id <> string

    id = UUID.uuid5(:oid, seed, :slug)

    "txn_" <> id
  end

  def amount(account_name, timestamp, date, transaction_number) do
    # Determine size of the transaction
    account_name_number = Variance.number_from_account_name(account_name)
    {ms, _} = timestamp.microsecond

    # Give extra weight to the day and transaction number by multiplying everything by them
    size_num =
      (date.month +
         account_name_number + ms + timestamp.second +
         timestamp.minute + timestamp.day) * date.day * Date.day_of_week(date) *
        transaction_number

    # For verisimilitude's sake:
    # transactions that have 5 digits (i.e. that are in the hundred's) should be rare
    # transactions that have 3 digits (i.e. that cost less than 10) should be somewhat infrequent
    # transactions that have 4 digits (i.e. that are in the 10s) should be most common
    # N.B. This works well for USD and GBP and other strong currencies.
    # More inflated currencies shoudl probably have different weights. That's a problem for another time.

    sig_digits =
      cond do
        rem(size_num, 20) == 0 -> 5
        rem(size_num, 5) == 0 -> 3
        true -> 4
      end

    # Create large integer
    size_num = size_num * account_name_number * transaction_number * ms * timestamp.day

    # Pick the correct number of digits
    # from the front of the large integer
    {digits, _} = size_num |> Integer.digits() |> Enum.split(sig_digits)
    int = Integer.undigits(digits)

    # Create the float
    -(int / 100)
  end

  def description_and_details(account_name, timestamp, date, transaction_number) do
    account_name_number = Variance.number_from_account_name(account_name)
    {ms, _} = timestamp.microsecond

    account_and_timestamp_num =
      ms + timestamp.second +
        timestamp.minute + timestamp.day * account_name_number

    # Give extra weight to the date and the transaction_number by multiplying everything by them
    date_and_transaction_num =
      (date.month +
         account_name_number) * transaction_number * date.day * Date.day_of_week(date)

    merchant =
      Variance.choose_from_list(date_and_transaction_num, account_and_timestamp_num, merchants(),
        op: :add
      )

    {merchant.name,
     %{
       category: merchant.category,
       counterparty: %{
         name: String.upcase(merchant.name),
         type: "organization"
       }
     }}
  end

  def count_for_day(account_name, timestamp, date) do
    account_name_number = Variance.number_from_account_name(account_name)
    {ms, _} = timestamp.microsecond

    account_and_timestamp_num =
      ms + timestamp.second +
        timestamp.minute + timestamp.day * account_name_number

    date_and_transaction_num =
      (date.month +
         account_name_number) * Date.day_of_week(date) * Date.day_of_year(date) * date.day

    Variance.choose_from_list(
      date_and_transaction_num,
      account_and_timestamp_num,
      [0, 1, 2, 3, 4, 5],
      op: :add
    )
  end
end
