defmodule Teller.Accounts.Variance do
  def number_from_account_name(account_name, opts \\ []) do
    number_list =
      account_name
      |> String.split(" ", trim: true)
      |> Enum.map(fn word ->
        case Keyword.get(opts, :word_op) do
          :add -> number_from_word(word, op: :add)
          :mult -> number_from_word(word, op: :mult)
          _ -> number_from_word(word, op: :add)
        end
      end)

    case Keyword.get(opts, :comb_op) do
      :add -> Enum.sum(number_list)
      :mult -> Enum.product(number_list)
      :div -> List.first(number_list) / List.last(number_list)
      _ -> Enum.sum(number_list)
    end
  end

  def number_from_word(word, opts \\ []) do
    number_list =
      word
      |> String.upcase()
      |> String.replace([" ", ".", "-"], "")
      |> String.split("", trim: true)
      |> Enum.map(fn letter -> get_alphabet_number(letter) end)

    case Keyword.get(opts, :op) do
      :add -> Enum.sum(number_list)
      :mult -> Enum.product(number_list)
      _ -> Enum.sum(number_list)
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
end
