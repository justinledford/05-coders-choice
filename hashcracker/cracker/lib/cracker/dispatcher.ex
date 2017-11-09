defmodule Cracker.Dispatcher do
  use GenServer

  @num_strings 65536
  @ascii_upperbound 50

  #####
  # External API
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_brute_force(num_workers, hash, hash_type) do
    GenServer.cast(__MODULE__,
                   {:init_dispatch, :brute, num_workers, hash, hash_type})
  end

  def start_mask(num_workers, hash, hash_type, mask) do
    GenServer.cast(__MODULE__,
                   {:init_dispatch, :mask, num_workers, hash, hash_type, mask})
  end

  def work_ready(work) do
    GenServer.cast __MODULE__, {:work_ready, work}
  end

  def not_found(pid) do
    GenServer.cast __MODULE__, {:not_found, pid}
  end

  def found_pass(pass) do
    GenServer.cast __MODULE__, {:found_pass, pass}
  end

  #####
  # GenServer implementation
  def handle_cast({:init_dispatch, :brute, num_workers, hash, hash_type}, _) do
    Cracker.Generator.init_ascii(@ascii_upperbound)

    # Start up workers
    workers = Enum.reduce(1..num_workers, [], fn _, workers ->
      {:ok, pid} = Cracker.Worker.start_link
      [pid | workers]
    end)

    {:noreply, {workers, hash, hash_type}}
  end

  def handle_cast({:init_dispatch, :mask, num_workers, hash, hash_type, mask}, _) do
    # Start up workers
    workers = Enum.reduce(1..num_workers, [], fn _, workers ->
      {:ok, pid} = Cracker.Worker.start_link
      [pid | workers]
    end)

    [ h | t ] = Cracker.Util.mask_to_enums(mask)

    h
    |> Cracker.Util.chunk(num_workers)
    |> Enum.map(fn enum -> [enum | t] end)
    |> Enum.zip(workers)
    |> Enum.map(fn {enums, worker} ->
         Cracker.Worker.mask_attack(enums, hash, hash_type, worker)
       end)


    {:noreply, {workers, hash, hash_type}}
  end



  def handle_cast({:work_ready, enum}, {workers, hash, hash_type}) do
    pid = Enum.random workers
    Cracker.Worker.start_work(enum, hash, hash_type, pid)
    {:noreply, {workers, hash, hash_type}}
  end

  def handle_cast({:not_found, pid}, {[ worker | [] ], hash, hash_type}) do
    GenServer.stop(pid)
    IO.puts "pass not found"
    # TODO: report to client that pass not found
    {:noreply, {[], hash, hash_type}}
  end

  def handle_cast({:not_found, pid}, {workers, hash, hash_type}) do
    GenServer.stop(pid)
    workers = Enum.filter(workers, fn worker_pid -> worker_pid != pid end)
    {:noreply, {workers, hash, hash_type}}
  end

  def handle_cast({:found_pass, pass}, {workers, hash, hash_type}) do
    Enum.map(workers, fn worker ->
      GenServer.stop(worker)
    end)
    IO.puts pass
    IO.puts DateTime.utc_now()
    # TODO: report to client that pass found
    {:noreply, {workers, hash, hash_type}}
  end
end
