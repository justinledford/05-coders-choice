defmodule Cracker.Dispatcher do
  use GenServer

  @brute_force_upper_bound 64

  #####
  # External API
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Just mask increment with mask ?a up to 64 (arbitrary upper bound)
  def start_brute_force(num_workers, hash, hash_type, client_pid) do
    mask = String.duplicate("?a", @brute_force_upper_bound)
    GenServer.cast(__MODULE__,
                   {:mask, num_workers, hash, hash_type,
                     mask, 1, @brute_force_upper_bound, client_pid})
  end

  def start_mask(num_workers, hash, hash_type, mask, client_pid) do
    GenServer.cast(__MODULE__,
                   {:mask, num_workers, hash, hash_type, mask, client_pid})
  end

  def start_mask_increment(num_workers, hash, hash_type, mask,
                           start, stop, client_pid) do
    GenServer.cast(__MODULE__,
                   {:mask, num_workers, hash, hash_type,
                     mask, start, stop, client_pid})
  end

  def start_dictionary(num_workers, hash, hash_type, wordlist_path, client_pid) do
    GenServer.cast(__MODULE__,
                   {:dictionary, num_workers, hash, hash_type,
                     wordlist_path, client_pid})
  end

  def not_found(pid) do
    GenServer.cast __MODULE__, {:not_found, pid}
  end

  def found_pass(pass) do
    GenServer.cast __MODULE__, {:found_pass, pass}
  end

  #####
  # GenServer implementation
  def handle_cast({:mask, num_workers, hash, hash_type, mask, client_pid}, _) do
    workers = start_workers(num_workers)
    {mask_h, mask_t} = split_mask_head_tail(mask)
    dispatch_mask(mask_h, mask_t, num_workers, workers, hash, hash_type)
    {:noreply, {workers, hash, hash_type, client_pid}}
  end

  def handle_cast({:mask, num_workers, hash, hash_type,
                   mask, start, stop, client_pid}, _) do
    workers = start_workers(num_workers)
    {mask_h, mask_t} = split_mask_head_tail(mask)

    dispatch_mask_increment(mask_h, mask_t, num_workers, workers,
                            hash, hash_type, start, stop)
    {:noreply, {workers, hash, hash_type, client_pid}}
  end

  def handle_cast({:dictionary, num_workers, hash, hash_type, wordlist_path, client_pid}, _) do
    workers = start_workers(num_workers)

    # Get length of file in bytes, find start/stop bytes
    # for each worker
    chunk_size = wordlist_path
    |> File.stat!
    |> Map.get(:size)
    |> div(num_workers)

    chunk_bounds = Enum.map(0..num_workers-1, fn i ->
      {i*chunk_size, (i+1)*chunk_size}
    end)

    Enum.zip(workers, chunk_bounds)
    |> Enum.map(fn {worker, bounds} ->
        Cracker.Worker.dictionary_attack(bounds, wordlist_path,
                                         hash, hash_type, worker)
    end)

    {:noreply, {workers, hash, hash_type, client_pid}}
  end

  ##################################################
  # Messages from workers
  ##################################################
  def handle_cast({:not_found, pid}, {workers, hash, hash_type, client_pid}) do
    case Process.alive?(pid) do
      true ->
        GenServer.stop(pid)
      false ->
        nil
    end
    workers = Enum.filter(workers, fn worker_pid -> worker_pid != pid end)
    {:noreply, {workers, hash, hash_type, client_pid}}
  end

  def handle_cast({:found_pass, pass}, {workers, hash, hash_type, client_pid}) do
    Enum.map(workers, fn worker ->
      Process.exit(worker, :kill)
    end)
    send client_pid, {:pass_found, pass}
    {:noreply, {workers, hash, hash_type, client_pid}}
  end

  #####
  #

  def start_workers(num_workers) do
    Enum.reduce(1..num_workers, [], fn _, workers ->
      {:ok, pid} = Cracker.Worker.start_link
      [pid | workers]
    end)
  end

  def split_mask_head_tail(mask) do
    case String.split(mask, "?", trim: true, parts: 2) do
      [ h | [ mask ] ] ->
        {h, mask}
      [ h | [] ] ->
        {h, ""}
    end
  end

  def dispatch_mask(mask_h, mask_t, num_workers, workers, hash, hash_type) do
    [ h_enum | _ ] = Cracker.Util.mask_to_enums(mask_h)
    h_enum
    |> Cracker.Util.chunk(num_workers)
    |> Enum.zip(workers)
    |> Enum.map(fn {chunk, worker} ->
         Cracker.Worker.mask_attack(chunk, mask_t, hash, hash_type, worker)
       end)
  end

  def dispatch_mask_increment(mask_h, mask_t, num_workers, workers, hash, hash_type, start, stop) do
    [ h_enum | _ ] = Cracker.Util.mask_to_enums(mask_h)
    h_enum
    |> Cracker.Util.chunk(num_workers)
    |> Enum.zip(workers)
    |> Enum.map(fn {chunk, worker} ->
       Cracker.Worker.mask_attack_increment(chunk, mask_t, start, stop,
                                            hash, hash_type, worker)
       end)
  end
end
