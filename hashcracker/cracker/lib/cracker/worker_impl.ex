defmodule Cracker.WorkerImpl do
  @update_increment 10_000

  def attack(state=%{attack: :mask, incremental_start: start, incremental_stop: stop}) do
    mask_enums = Cracker.Util.mask_to_enums(state.mask)
    Enum.reduce(start..stop, fn i, result ->
      case result do
        {_pass, _} ->
          message_dispatcher(result, state)
        _ ->
          mask_enums
          |> Enum.take(i)
          |> Cracker.Perm.perm(state.start)
          |> Stream.map(&Enum.join/1)
          |> update_attempts(state.client_node, @update_increment)
          |> find_matching_hash(state.hash, state.hash_type)
      end
    end)
    |> message_dispatcher(state)
  end

  def attack(state=%{attack: :mask}) do
    state.mask
    |> Cracker.Util.mask_to_enums
    |> Cracker.Perm.perm(state.start)
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
