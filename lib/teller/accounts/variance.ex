defmodule Teller.Accounts.Variance do
  # Generic function that takes any two numbers and
  # combines them to choose an item from a list of choices
  def choose_from_list(num_1, num_2, list, opts \\ []) do
    rem_1 = rem(num_1, length(list)) - 1

    new_number =
      case Keyword.get(opts, :op) do
        :add -> rem_1 + num_2
        :mult -> rem_1 * num_2
        :div -> rem_1 / num_2
        _ -> rem_1 + num_2
      end

    list_index = rem(new_number, length(list)) - 1

    Enum.at(list, list_index)
  end

  def id_to_number(id) do
    # Strip out first four characters
    {_, list} = id |> String.split("", trim: true) |> Enum.split(4)

    # Turn the list into a char list
    # Since a charlist is a list of numbers, we join them into a string of numbers
    # Then we convert the string back into a really big integer!
    List.to_string(list)
    |> to_charlist()
    |> Enum.join()
    |> String.to_integer()
  end

  def split_seed(seed, size) do
    {list_1, list_2} = seed |> Integer.digits() |> Enum.split(size)
    num_1 = Integer.undigits(list_1)
    {num_2, _} = Enum.split(list_2, size)
    num_2 = Integer.undigits(num_2)

    {num_1, num_2}
  end
end
