defmodule Cracker.DispatcherImpl do
  alias Cracker.DispatcherSupervisor, as: DispatcherSupervisor
  alias Cracker.Util, as: Util
  alias Cracker.Worker, as: Worker

  @brute_force_upper_bound 64

  def start(state) do
    workers = init_workers(state.num_workers)
    workers = Enum.zip(workers, 1..state.num_workers)
    state = Map.put(state, :workers, workers)
    dispatch(state)
    state
  end

  def update_attempts(attempts, state) do
    state = Map.update(state, :attempts, attempts, &(&1 + attempts))
    send state.client_pid, {:update_attempts, state.attempts}
    state
  end

  def not_found(worker_pid, state) do
    worker_count = Enum.count(state.workers)
    state = worker_done(worker_pid, state, worker_count)
    state
  end

  def found_pass(pass, state) do
    if Process.whereis(DispatcherSupervisor) do
      Supervisor.stop(DispatcherSupervisor)
    end
    send state.client_pid, {:pass_found, pass}
  end

  defp init_workers(num_workers) do
    {:ok, _} = DispatcherSupervisor.start_link(num_workers)
    Supervisor.which_children(DispatcherSupervisor)
    |> Enum.map(fn {_, pid, _, _} -> pid end)
  end

  defp get_worker(state) do
    i = rem(state.worker_num, Enum.count(state.worker_nodes))
    Enum.at(state.worker_nodes, i)
  end

  defp dispatch(state) do
    state
    |> setup_worker_states
    |> assign_worker_nodes
    |> start_workers
  end

  defp worker_done(_worker, state, worker_count) when worker_count < 2 do
    if Process.whereis(DispatcherSupervisor) do
      Supervisor.stop(DispatcherSupervisor)
    end
    send state.client_pid, {:pass_not_found, nil}
    state
  end
  defp worker_done(worker_pid, state, _) do
    workers = Enum.filter(state.workers, fn {pid, _} ->
      worker_pid != pid
    end)
    Map.put(state, :workers, workers)
  end

  defp setup_worker_states(state=%{attack: :brute}) do
    mask = String.duplicate("?a", @brute_force_upper_bound)
    state
    |> Map.merge(%{mask: mask, incremental_start: 1,
                   incremental_stop: @brute_force_upper_bound})
    |> Map.put(:attack, :mask)
    |> setup_worker_states
  end

  defp setup_worker_states(state) do
    chunk_size = get_chunk_size(state)
    starts = Enum.map(0..state.num_workers-1, &(&1*chunk_size))

    state
    |> Map.merge(%{chunk_size: chunk_size})
    |> merge_worker_states(starts, :start)
  end

  defp merge_worker_states(state, xs, key) do
    Enum.zip(state.workers, xs)
    |> Enum.map(merge_with_key(state, key))
  end

  defp merge_with_key(state, key) do
    fn {{worker_pid, worker_num}, x} ->
      Map.merge(state, %{:worker_pid => worker_pid,
                         :worker_num => worker_num,
                         key => x})
    end
  end

  defp assign_worker_nodes(states) do
    Enum.map(states, fn state ->
      worker_node = get_worker(state)
      Map.put(state, :worker_node, worker_node)
    end)
  end

  defp start_workers(worker_states) do
    Enum.map(worker_states, &Worker.start_work/1)
  end

  defp get_chunk_size(state=%{attack: :dictionary}) do
    state.wordlist_path
    |> File.stat!
    |> Map.get(:size)
    |> div(state.num_workers)
  end

  defp get_chunk_size(state=%{attack: :mask}) do
    state.mask
    |> Util.mask_to_enums
    |> Util.product_size
  end

end
