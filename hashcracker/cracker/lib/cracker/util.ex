defmodule Cracker.Util do

  alias Cracker.Charsets, as: Charsets

  def mask_to_enums(mask) do
    charsets = %{
      "l" => Charsets.l,
      "u" => Charsets.u,
      "d" => Charsets.d,
      "s" => Charsets.s,
      "a" => Charsets.a
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
  def chunk(enum, 1, _chunk_size, acc) do
    [enum | acc]
  end
  def chunk(enum, num_chunks, chunk_size, acc) do
    acc = [ Enum.take(enum, chunk_size) | acc ]
    enum = Enum.drop(enum, chunk_size)
    chunk(enum, num_chunks-1, chunk_size, acc)
  end

  def listify(x) when is_list(x) do
    x
  end
  def listify(x) do
    [x]
  end

  def product(enums, results \\ [[]]) do
    Enum.reduce(enums, results, fn enum, acc ->
      Stream.flat_map(enum, fn x ->
        Stream.map(acc, fn y -> listify(y) ++ listify(x) end)
      end)
    end)
  end

  def product_size(enums) do
    Enum.reduce(enums, 1, fn enum, size ->
      Enum.count(enum) * size
    end)
  end

  def wordlist_stream(wordlist_path, start) do
    f = File.open!(wordlist_path, [:read_ahead])
    {:ok, _} = :file.position(f, start)
    seek_file(f, start)
    IO.stream(f, :line)
  end

  def seek_file(_, 0) do
    nil
  end
  def seek_file(f, _) do
    IO.read(f, :line)
  end

end
