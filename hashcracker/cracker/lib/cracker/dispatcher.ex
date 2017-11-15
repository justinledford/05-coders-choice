defmodule Cracker.Dispatcher do
  use GenServer

  @brute_force_upper_bound 64

  ##################################################
  # External API
  ##################################################

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
    state = worker_done(worker, state, Enum.count(state.workers))
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

  ##################################################
  # Implementation
  ##################################################

  defp start_workers(num_workers) do
    {:ok, _} = Cracker.DispatcherSupervisor.start_link(num_workers)
    Supervisor.which_children(Cracker.DispatcherSupervisor)
    |> Enum.map(fn {_, pid, _, _} -> pid end)
  end

  defp split_mask_head_tail(mask) do
    case String.split(mask, "?", trim: true, parts: 2) do
      [ h | [ mask ] ] ->
        {h, mask}
      [ h | [] ] ->
        {h, ""}
    end
  end

  defp dispatch(state=%{attack: :brute}) do
    mask = String.duplicate("?a", @brute_force_upper_bound)
    state
    |> Map.merge(%{mask: mask, start: 1, stop: @brute_force_upper_bound})
    |> Map.put(:attack, :mask)
    |> dispatch
  end

  defp dispatch(state=%{attack: :mask}) do
    {mask_h, mask_t} = split_mask_head_tail(state.mask)
    [ h_enum | _ ] = Cracker.Util.mask_to_enums(mask_h)
    h_enum
    |> Cracker.Util.chunk(state.num_workers)
    |> Enum.zip(state.workers)
    |> Enum.map(
      fn {chunk, worker} ->
        Map.drop(state, [:workers])
        |> Map.merge(%{chunk: chunk, worker: worker, mask_t: mask_t})
        |> Cracker.Worker.start_work
      end)
  end

  defp dispatch(state=%{attack: :dictionary}) do
    chunk_size = state.wordlist_path
    |> File.stat!
    |> Map.get(:size)
    |> div(state.num_workers)

    starts = Enum.map(0..state.num_workers-1, fn i ->
      i*chunk_size
    end)

    Enum.zip(state.workers, starts)
    |> Enum.map(fn {worker, start} ->
        state
        |> Map.drop([:workers])
        |> Map.merge(%{worker: worker, start: start, chunk_size: chunk_size})
        |> Cracker.Worker.start_work
    end)
  end

  defp worker_done(_worker, state, worker_count) when worker_count < 2 do
    Supervisor.stop(Cracker.DispatcherSupervisor)
    send state.client_pid, {:pass_not_found, nil}
    state
  end
  defp worker_done(worker, state, _) do
    workers = Enum.filter(state.workers, fn worker_ -> worker_ != worker end)
    Map.put(state, :workers, workers)
  end

end
