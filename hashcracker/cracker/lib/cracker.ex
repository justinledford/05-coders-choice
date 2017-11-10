defmodule Cracker do
  def crack(hash, hash_type, :brute, num_workers) do
    Cracker.Dispatcher.start_brute_force(num_workers, hash, :sha, self())
    receive do
      {:pass_found, pass} ->
        pass
      {:pass_not_found, nil} ->
        nil
    end
  end

  def crack(hash, hash_type, :mask, mask, num_workers) do
    Cracker.Dispatcher.start_mask(num_workers, hash, :sha, mask, self())
    receive do
      {:pass_found, pass} ->
        pass
      {:pass_not_found, nil} ->
        nil
    end
  end
  #def crack(hash, hash_type, :dictionary, wordlist_path) do
  #  Cracker.Generator.init_dictionary(wordlist_path)
  #  Cracker.Generator.get_stream()
  #  |> find_matching_hash(hash, hash_type)
  #end
end
