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
  def mask_attack(state) do
    GenServer.cast(state.worker, {:mask_attack, state})
  end

  def mask_attack_increment(state) do
    GenServer.cast(state.worker, {:mask_attack_increment, state})
  end

  def dictionary_attack(state) do
    GenServer.cast(state.worker, {:dictionary_attack, state})
  end

  #####
  # GenServer implementation
  def handle_cast({:work, enum, hash, hash_type}, _) do
    enum
    |> Cracker.Cracker.find_matching_hash(hash, hash_type)
    |> message_dispatcher
    {:noreply, nil}
  end

  def handle_cast({:mask_attack, state}, _) do
    tail_enums = Cracker.Util.mask_to_enums(state.mask_t)
    enums = [ state.chunk | tail_enums ]
    Cracker.Util.product(enums)
    |> Stream.map(&Enum.join/1)
    |> Cracker.Cracker.find_matching_hash(state.hash, state.hash_type)
    |> message_dispatcher
    {:noreply, nil}
  end

  def handle_cast({:mask_attack_increment, state}, _) do
    tail_enums = Cracker.Util.mask_to_enums(state.mask_t)
    enums = [ state.chunk | tail_enums ]

    enums_partial = Enum.take(enums, state.start)
    enums = Enum.drop(enums, state.start)
    Map.merge(state, %{enums: enums, enums_partial: enums_partial})
    |> mask_increment_loop(state.stop-state.start, [[]])
    |> message_dispatcher

    {:noreply, nil}
  end

  def handle_cast({:dictionary_attack, state}, _) do
    f = File.open!(state.wordlist_path, [:read_ahead])
    {:ok, _} = :file.position(f, state.start)

    case state.start do
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
         if (state.stop-state.start) > bytes_read do
           {[line], bytes_read + (String.length line) + 1}
         else
           {:halt, bytes_read}
         end
       end)
    |> Cracker.Cracker.find_matching_hash(state.hash, state.hash_type)
    |> message_dispatcher

    {:noreply, nil}
  end

  #####
  #

  def mask_increment_loop(_state,-1,_results) do
    nil
  end
  def mask_increment_loop(state, i, results) do
    results = Cracker.Util.product(state.enums_partial, results)
    found = results
    |> Stream.map(&Enum.join/1)
    |> Cracker.Cracker.find_matching_hash(state.hash, state.hash_type)

    case found do
      nil ->
        enums_partial = Enum.take(state.enums, 1)
        enums = Enum.drop(state.enums, 1)

        state
        |> Map.merge(%{enums: enums, enums_partial: enums_partial})
        |> mask_increment_loop(i-1, results)
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
