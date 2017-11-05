defmodule Cracker do
  def crack(hash, hash_type, :brute) do
    string_list(?\ ..?~)
    |> generate(50)
    |> Stream.map(fn x -> { x, :crypto.hash(hash_type, x) } end)
    |> Enum.find(fn { _, hash_ } -> hash_ == hash end)
  end

  ####
  #
  # Utilities for generating strings
  #
  ####

  def string_list(range) do
    for n <- range, do: << n :: utf8 >>
  end

  def _generate(source, target) do
    Stream.flat_map(source, fn x ->
      Stream.map(target,
                 &(Enum.join([x, &1])))
    end)
  end

  def generate(source, n) do
    Enum.reduce(1..n, [source], fn _, [last | acc] ->
      generated = _generate(source, last)
      [generated | [last | acc]]
    end)
    |> Enum.reverse
    |> Stream.concat
  end


end
