defmodule Cracker.Worker do
  use GenServer

  ##################################################
  # External API
  ##################################################

  def start_link(num) do
    GenServer.start_link(__MODULE__, [], name: String.to_atom("Worker-#{num}"))
  end

  def start_work(state) do
    GenServer.cast(state.worker, {:start_work, state})
  end

  ##################################################
  # GenServer implementation
  ##################################################

  def handle_cast({:start_work, state}, _) do
    attack(state)
    {:noreply, nil}
  end

  ##################################################
  # Implementation
  ##################################################

  defp attack(state=%{attack: :mask, start: start, stop: stop}) do
    tail_enums = Cracker.Util.mask_to_enums(state.mask_t)
    enums = [ state.chunk | tail_enums ]
    enums_partial = Enum.take(enums, start)
    enums = Enum.drop(enums, start)
    Map.merge(state, %{enums: enums, enums_partial: enums_partial})
    |> mask_increment_loop(stop-start, [[]])
    |> message_dispatcher
  end

  defp attack(state=%{attack: :mask}) do
    tail_enums = Cracker.Util.mask_to_enums(state.mask_t)
    enums = [ state.chunk | tail_enums ]
    Cracker.Util.product(enums)
    |> Stream.map(&Enum.join/1)
    |> Cracker.Cracker.find_matching_hash(state.hash, state.hash_type)
    |> message_dispatcher
  end

  defp attack(state=%{attack: :dictionary}) do
    wordlist_stream(state.wordlist_path, state.start)
    |> Stream.map(&String.trim_trailing/1)
    |> Stream.transform(0, fn line, bytes_read ->
         if bytes_read < state.chunk_size do
           {[line], bytes_read + (String.length line) + 1}
         else
           {:halt, bytes_read}
         end
       end)
    |> Cracker.Cracker.find_matching_hash(state.hash, state.hash_type)
    |> message_dispatcher
  end

  defp mask_increment_loop(_state,-1,_results) do
    nil
  end
  defp mask_increment_loop(state, i, results) do
    results = Cracker.Util.product(state.enums_partial, results)
    results
    |> Stream.map(&Enum.join/1)
    |> Cracker.Cracker.find_matching_hash(state.hash, state.hash_type)
    |> _mask_increment_loop(state, i, results)
  end

  defp _mask_increment_loop(nil, state, i, results) do
    enums_partial = Enum.take(state.enums, 1)
    enums = Enum.drop(state.enums, 1)
    state
    |> Map.merge(%{enums: enums, enums_partial: enums_partial})
    |> mask_increment_loop(i-1, results)
  end
  defp _mask_increment_loop(found, _, _, _) do
    found
  end

  defp message_dispatcher(nil) do
    Cracker.Dispatcher.not_found(self())
  end

  defp message_dispatcher({pass, _}) do
    Cracker.Dispatcher.found_pass(pass)
  end

  defp wordlist_stream(wordlist_path, start) do
    f = File.open!(wordlist_path, [:read_ahead])
    {:ok, _} = :file.position(f, start)
    seek_file(f, start)
    IO.stream(f, :line)
  end

  defp seek_file(_, 0) do
    nil
  end
  defp seek_file(f, _) do
    IO.read(f, :line)
  end

end
