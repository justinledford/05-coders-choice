#
# Most of this written by Dave Thomas aka pragdave
#
# Justin Ledford: Added halt/ok tuples in cascade_shift to stop at end of perms
#
defmodule Cracker.Perm do

  def perm(list_of_lists, start_at \\ 0) do

    list_of_lists
    |> cycle_to(start_at)
    |> Stream.unfold(
    fn
      []    -> nil
      lists ->
        case cascade_shift(lists, list_of_lists) do
          {:halt} ->
            {head_of(lists), []}
          {:ok, next_state} ->
            { head_of(lists), next_state }
        end
      end
    )
  end


  def cycle_to(list_of_lists, offset, factor \\ 1)
  def cycle_to([ ], _offset, _factor), do: []
  def cycle_to([ sublist | rest ], offset, factor) do
    size = length(sublist)
    new_sublist = sublist |> Enum.drop(rem(div(offset, factor), size))
    [ new_sublist | cycle_to(rest, offset, factor*size) ]
  end

  def head_of(lists), do: Enum.map(lists, &hd/1)

  def cascade_shift([], []), do: {:halt}
  def cascade_shift(lists, [ next_original | rest_of_original ]) do
    case lists do

      # we've to exhausted the first list
      [ [ _ ] | rest_of_list ] ->
        case cascade_shift(rest_of_list, rest_of_original) do
          {:ok, tail} ->
            {:ok, [next_original | tail]}
          {:halt} ->
            {:halt}
        end

      # otherwise just cycle and we're done
      [ [ _head | rest ] | rest_of_list ] ->
        {:ok, [ rest | rest_of_list ]}
    end
  end
end
