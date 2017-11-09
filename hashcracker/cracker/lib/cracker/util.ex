defmodule Cracker.Util do
  def mask_to_enums(mask) do
    charsets = %{
      "l" => Cracker.Charsets.l,
      "u" => Cracker.Charsets.u,
      "d" => Cracker.Charsets.d,
      "s" => Cracker.Charsets.s,
      "a" => Cracker.Charsets.a
    }

    mask
    |> String.split("?", trim: true)
    |> Enum.map(fn c -> Map.get(charsets, c) end)
  end

  def string_list(range) do
    for n <- range, do: << n :: utf8 >>
  end

  def chunk(enum, num_chunks) do
    chunk_size = enum |> Enum.count |> div(num_chunks)

    chunk(enum, num_chunks, chunk_size, [])
    |> Enum.reverse
  end
  def chunk(enum, 1, chunk_size, acc) do
    [enum | acc]
  end
  def chunk(enum, num_chunks, chunk_size, acc) do
    acc = [ Enum.take(enum, chunk_size) | acc ]
    enum = Enum.drop(enum, chunk_size)
    chunk(enum, num_chunks-1, chunk_size, acc)
  end

  def product(enums) do
    Enum.reduce(enums, [[]], fn enum, acc ->
      for x <- enum, y <- acc, do: [x | y]
    end)
    |> Enum.map(&Enum.reverse/1)
  end

end
