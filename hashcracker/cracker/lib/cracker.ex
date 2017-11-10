defmodule Cracker do
  def crack(hash, hash_type, :brute, num_workers) do
    Cracker.Dispatcher.start_brute_force(num_workers, hash, hash_type, self())
    receive do
      {:pass_found, pass} ->
        pass
      {:pass_not_found, nil} ->
        nil
    end
  end

  def crack(hash, hash_type, :mask, mask, num_workers) do
    Cracker.Dispatcher.start_mask(num_workers, hash, hash_type, mask, self())
    receive do
      {:pass_found, pass} ->
        pass
      {:pass_not_found, nil} ->
        nil
    end
  end

  def crack(hash, hash_type, :mask_increment, mask, start, stop, num_workers) do
    Cracker.Dispatcher.start_mask_increment(num_workers, hash, hash_type,
                                            mask, start, stop, self())
    receive do
      {:pass_found, pass} ->
        pass
      {:pass_not_found, nil} ->
        nil
    end
  end
end
