defmodule Cracker.Dispatcher do
  use GenServer

  @brute_force_upper_bound 64

  #####
  # External API
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start(state=%{attack: mode}) do
    GenServer.cast(__MODULE__, {mode, state})
  end

  def not_found(pid) do
    GenServer.cast __MODULE__, {:not_found, pid}
  end

  def found_pass(pass) do
    GenServer.cast __MODULE__, {:found_pass, pass}
  end

  ##################################################
  # GenServer implementation
  ##################################################

  def handle_cast({:not_found, worker}, state) do
    alive = Process.alive?(worker)
    state = worker_done(worker, state, Enum.count(state.workers), alive)
    {:noreply, state}
  end

  def handle_cast({:found_pass, pass}, state) do
    Supervisor.stop(Cracker.DispatcherSupervisor)
    send state.client_pid, {:pass_found, pass}
    {:noreply, state}
  end

  def handle_cast({_mode, state}, _) do
    workers = start_workers(state.num_workers)
    state = Map.put(state, :workers, workers)
    dispatch(state)
    {:noreply, state}
  end


  #####
  #

  def start_workers(num_workers) do
    {:ok, _} = Cracker.DispatcherSupervisor.start_link(num_workers)
    Supervisor.which_children(Cracker.DispatcherSupervisor)
    |> Enum.map(fn {_, pid, _, _} -> pid end)
  end

  def split_mask_head_tail(mask) do
    case String.split(mask, "?", trim: true, parts: 2) do
      [ h | [ mask ] ] ->
        {h, mask}
      [ h | [] ] ->
        {h, ""}
    end
  end

  def dispatch(state=%{attack: :brute}) do
    mask = String.duplicate("?a", @brute_force_upper_bound)
    state
    |> Map.merge(%{mask: mask, start: 1, stop: @brute_force_upper_bound})
    |> Map.put(:attack, :mask_increment)
    |> dispatch
  end

  def dispatch(state=%{attack: :mask}) do
    {mask_h, mask_t} = split_mask_head_tail(state.mask)
    [ h_enum | _ ] = Cracker.Util.mask_to_enums(mask_h)
    h_enum
    |> Cracker.Util.chunk(state.num_workers)
    |> Enum.zip(state.workers)
    |> Enum.map(
      fn {chunk, worker} ->
        Map.drop(state, [:workers])
        |> Map.merge(%{chunk: chunk, worker: worker, mask_t: mask_t})
        |> Cracker.Worker.mask_attack
      end)
  end

  def dispatch(state=%{attack: :mask_increment}) do
    {mask_h, mask_t} = split_mask_head_tail(state.mask)
    [ h_enum | _ ] = Cracker.Util.mask_to_enums(mask_h)
    h_enum
    |> Cracker.Util.chunk(state.num_workers)
    |> Enum.zip(state.workers)
    |> Enum.map(
      fn {chunk, worker} ->
        Map.drop(state, [:workers])
        |> Map.merge(%{chunk: chunk, worker: worker, mask_t: mask_t})
        |> Cracker.Worker.mask_attack_increment
      end)
  end

  def dispatch(state=%{attack: :dictionary}) do
    chunk_size = state.wordlist_path
    |> File.stat!
    |> Map.get(:size)
    |> div(state.num_workers)

    chunk_bounds = Enum.map(0..state.num_workers-1, fn i ->
      {i*chunk_size, (i+1)*chunk_size}
    end)

    Enum.zip(state.workers, chunk_bounds)
    |> Enum.map(fn {worker, {start, stop}} ->
        state
        |> Map.drop([:workers])
        |> Map.merge(%{worker: worker, start: start, stop: stop})
        |> Cracker.Worker.dictionary_attack
    end)
  end

  def worker_done(_worker, state, 1, _alive) do
    Supervisor.stop(Cracker.DispatcherSupervisor)
    send state.client_pid, {:pass_not_found, nil}
    state
  end
  def worker_done(worker, state, _worker_count, true) do
    Supervisor.terminate_child(Cracker.DispatcherSupervisor, worker)
    workers = Enum.filter(state.workers, fn worker_ -> worker_ != worker end)
    Map.put(state, :workers, workers)
  end
  def worker_done(worker, state, _worker_count, false) do
    workers = Enum.filter(state.workers, fn worker_ -> worker_ != worker end)
    Map.put(state, :workers, workers)
  end

end
