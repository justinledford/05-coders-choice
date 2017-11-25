defmodule Cracker.WorkerImpl do
  @update_increment 10_000

  def attack(state=%{attack: :mask, start: start, stop: stop}) do
    tail_enums = Cracker.Util.mask_to_enums(state.mask_t)
    enums = [ state.chunk | tail_enums ]
    enums_partial = Enum.take(enums, start)
    enums = Enum.drop(enums, start)
    Map.merge(state, %{enums: enums, enums_partial: enums_partial})
    |> mask_increment_loop(stop-start, [[]])
    |> message_dispatcher(state)
  end

  def attack(state=%{attack: :mask}) do
    tail_enums = Cracker.Util.mask_to_enums(state.mask_t)
    enums = [ state.chunk | tail_enums ]
    Cracker.Util.product(enums)
    |> Stream.map(&Enum.join/1)
    |> update_attempts(state.client_node, @update_increment)
    |> find_matching_hash(state.hash, state.hash_type)
    |> message_dispatcher(state)
  end

  def attack(state=%{attack: :dictionary}) do
    wordlist_stream(state.wordlist_path, state.start)
    |> Stream.map(&String.trim_trailing/1)
    |> stream_file_chunk(state.chunk_size)
    |> update_attempts(state.client_node, @update_increment)
    |> find_matching_hash(state.hash, state.hash_type)
    |> message_dispatcher(state)
  end

  defp mask_increment_loop(_state,-1,_results) do
    nil
  end
  defp mask_increment_loop(state, i, results) do
    results = Cracker.Util.product(state.enums_partial, results)
    results
    |> Stream.map(&Enum.join/1)
    |> update_attempts(state.client_node, @update_increment)
    |> find_matching_hash(state.hash, state.hash_type)
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

  defp message_dispatcher(nil, state) do
    Cracker.Dispatcher.not_found(state.worker_pid, state.client_node)
  end

  defp message_dispatcher({pass, _}, state) do
    Cracker.Dispatcher.found_pass(pass, state.client_node)
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

  # Stop stream once chunk_size has been read
  defp stream_file_chunk(stream, chunk_size) do
    Stream.transform(stream, 0, fn line, bytes_read ->
       if bytes_read < chunk_size do
         {[line], bytes_read + (String.length line) + 1}
       else
         {:halt, bytes_read}
       end
     end)
  end

  def update_attempts(stream, client_node, increment) do
    Stream.transform(stream, 0, fn candidate, attempts ->
      attempts = attempts + 1
      attempts = if attempts >= increment do
        Cracker.Dispatcher.update_attempts(attempts, client_node)
        0
      else
        attempts
      end
      { [candidate], attempts }
    end)
  end

  defp find_matching_hash(stream, hash, hash_type) do
    stream
    |> Stream.map(fn x -> {x, :crypto.hash(hash_type, x) } end)
    |> Stream.drop_while(fn { _, hash_ } -> hash_ != hash end)
    |> Enum.take(1)
    |> Enum.at(0)
  end

end
