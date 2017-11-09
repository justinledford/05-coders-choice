defmodule Cracker.Cracker do
  def find_matching_hash(enum, hash, hash_type) do
    enum
    |> Stream.map(fn x -> { x, :crypto.hash(hash_type, x) } end)
    |> Enum.find(fn { _, hash_ } -> hash_ == hash end)
  end
end
