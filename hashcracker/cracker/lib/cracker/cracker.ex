defmodule Cracker.Cracker do
  def find_matching_hash(stream, hash, hash_type) do
    stream
    |> Stream.map(fn x -> {x, :crypto.hash(hash_type, x) } end)
    |> Stream.drop_while(fn { _, hash_ } -> hash_ != hash end)
    |> Enum.take(1)
    |> Enum.at(0)
  end
end
