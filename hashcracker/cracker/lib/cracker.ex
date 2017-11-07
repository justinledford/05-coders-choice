defmodule Cracker do
  def crack(hash, hash_type, :brute) do
    Cracker.Generator.init_ascii(50)
    Cracker.Generator.get_stream()
    |> find_matching_hash(hash, hash_type)
  end

  def crack(hash, hash_type, :dictionary, wordlist_path) do
    Cracker.Generator.init_dictionary(wordlist_path)
    Cracker.Generator.get_stream()
    |> find_matching_hash(hash, hash_type)
  end

  def find_matching_hash(enum, hash, hash_type) do
    enum
    |> Stream.map(fn x -> { x, :crypto.hash(hash_type, x) } end)
    |> Enum.find(fn { _, hash_ } -> hash_ == hash end)
  end

end
