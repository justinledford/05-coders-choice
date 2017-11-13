defmodule Cracker.Worker do
  use GenServer

  #####
  # External API
  def start_link(num) do
    GenServer.start_link(__MODULE__, [], name: String.to_atom("Worker-#{num}"))
  end

  # Take enum and start hasing
  def start_work(enum, hash, hash_type, pid) do
    GenServer.cast(pid, {:work, enum, hash, hash_type})
  end

  # Given enums, get product to generate candidates
  def mask_attack(chunk, mask, hash, hash_type, pid) do
    GenServer.cast(pid, {:mask_attack, chunk, mask, hash, hash_type})
  end

  def mask_attack_increment(chunk, mask, start, stop, hash, hash_type, pid) do
    GenServer.cast(pid, {:mask_attack_increment, chunk, mask, start, stop,
                         hash, hash_type})
  end

  def dictionary_attack(chunk_size, wordlist_path, hash, hash_type, pid) do
    GenServer.cast(pid, {:dictionary_attack, chunk_size,
                         wordlist_path, hash, hash_type})
  end

  #####
  # GenServer implementation
  def handle_cast({:work, enum, hash, hash_type}, _) do
    enum
    |> Cracker.Cracker.find_matching_hash(hash, hash_type)
    |> message_dispatcher
    {:noreply, nil}
  end

  def handle_cast({:mask_attack, chunk, mask, hash, hash_type}, _) do
    tail_enums = Cracker.Util.mask_to_enums(mask)
    enums = [ chunk | tail_enums ]
    Cracker.Util.product(enums)
    |> Stream.map(&Enum.join/1)
    |> Cracker.Cracker.find_matching_hash(hash, hash_type)
    |> message_dispatcher
    {:noreply, nil}
  end

  def handle_cast(
    {:mask_attack_increment, chunk, mask, start, stop, hash, hash_type}, _) do
    tail_enums = Cracker.Util.mask_to_enums(mask)
    enums = [ chunk | tail_enums ]

    enums_partial = Enum.take(enums, start)
    enums = Enum.drop(enums, start)
    mask_increment_loop(hash, hash_type, stop-start,
                        enums, enums_partial, [[]])
    |> message_dispatcher

    {:noreply, nil}
  end

  def handle_cast({:dictionary_attack, {start, stop}, wordlist_path, hash, hash_type}, _) do
    f = File.open!(wordlist_path, [:read_ahead])
    {:ok, _} = :file.position(f, start)

    case start do
      0 ->
        nil
      _ ->
      # seek file to next non newline
        IO.read(f, :line)
    end

    f
    |> IO.stream(:line)
    |> Stream.map(&String.trim_trailing/1)
    |> Stream.transform(0, fn line, bytes_read ->
         if (stop-start) > bytes_read do
           {[line], bytes_read + (String.length line) + 1}
         else
           {:halt, bytes_read}
         end
       end)
    |> Cracker.Cracker.find_matching_hash(hash, hash_type)
    |> message_dispatcher

    {:noreply, nil}
  end

  #####
  #

  def mask_increment_loop(_,_,-1,_,_,_) do
    nil
  end
  def mask_increment_loop(hash, hash_type, i, enums, enums_partial, results) do
    results = Cracker.Util.product(enums_partial, results)
    found = results
    |> Stream.map(&Enum.join/1)
    |> Cracker.Cracker.find_matching_hash(hash, hash_type)

    case found do
      nil ->
        enums_partial = Enum.take(enums, 1)
        enums = Enum.drop(enums, 1)
        mask_increment_loop(hash, hash_type, i-1, enums, enums_partial, results)
      found ->
        found
    end
  end

  defp message_dispatcher(nil) do
    Cracker.Dispatcher.not_found(self())
  end

  defp message_dispatcher({pass, _}) do
    Cracker.Dispatcher.found_pass(pass)
  end

end
