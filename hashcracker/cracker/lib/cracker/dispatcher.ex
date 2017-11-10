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

  def not_found(pid) do
    GenServer.cast __MODULE__, {:not_found, pid}
  end

  def found_pass(pass) do
    GenServer.cast __MODULE__, {:found_pass, pass}
  end

  #####
  # GenServer implementation
  def handle_cast({:mask, num_workers, hash, hash_type, mask, client_pid}, _) do
    # Start up workers
    workers = Enum.reduce(1..num_workers, [], fn _, workers ->
      {:ok, pid} = Cracker.Worker.start_link
      [pid | workers]
    end)

    # Get chunks of first enum, and remaining mask and send to workers
    [ h | [ mask ] ] = String.split(mask, "?", trim: true, parts: 2)
    [ h_enum | _ ] = Cracker.Util.mask_to_enums(h)
    h_enum
    |> Cracker.Util.chunk(num_workers)
    |> Enum.zip(workers)
    |> Enum.map(fn {chunk, worker} ->
         Cracker.Worker.mask_attack(chunk, mask, hash, hash_type, worker)
       end)
    {:noreply, {workers, hash, hash_type, client_pid}}
  end

  # TODO: DRY
  def handle_cast({:mask, num_workers, hash, hash_type,
                   mask, start, stop, client_pid}, _) do
    # Start up workers
    workers = Enum.reduce(1..num_workers, [], fn _, workers ->
      {:ok, pid} = Cracker.Worker.start_link
      [pid | workers]
    end)

    # Get chunks of first enum, and remaining mask and send to workers
    [ h | [ mask ] ] = String.split(mask, "?", trim: true, parts: 2)
    [ h_enum | _ ] = Cracker.Util.mask_to_enums(h)
    h_enum
    |> Cracker.Util.chunk(num_workers)
    |> Enum.zip(workers)
    |> Enum.map(fn {chunk, worker} ->
       Cracker.Worker.mask_attack_increment(chunk, mask, start, stop,
                                            hash, hash_type, worker)
       end)
    {:noreply, {workers, hash, hash_type, client_pid}}
  end

  # Found pass, but last worker sent not found
  def handle_cast({:not_found, _}, {[], hash, hash_type, client_pid}) do
    {:noreply, {[], hash, hash_type}}
  end

  def handle_cast({:not_found, pid}, {[ _ | [] ], hash, hash_type, client_pid}) do
    case Process.alive?(pid) do
      true ->
        GenServer.stop(pid)
        IO.puts "pass not found"
      false ->
        nil
    end
    # TODO: report to client that pass not found
    {:noreply, {[], hash, hash_type}}
  end

  def handle_cast({:not_found, pid}, {workers, hash, hash_type, client_pid}) do
    case Process.alive?(pid) do
      true ->
        GenServer.stop(pid)
      false ->
        nil
    end
    workers = Enum.filter(workers, fn worker_pid -> worker_pid != pid end)
    {:noreply, {workers, hash, hash_type}}
  end

  def handle_cast({:found_pass, pass}, {workers, hash, hash_type, client_pid}) do
    Enum.map(workers, fn worker ->
      Process.exit(worker, :kill)
    end)
    # TODO: report to client that pass found
    send client_pid, {:pass_found, pass}
    {:noreply, {workers, hash, hash_type}}
  end
end
