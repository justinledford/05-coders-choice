defmodule Cracker.Dispatcher do
  use GenServer

  ##################################################
  # External API
  ##################################################

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start(state) do
    GenServer.cast(__MODULE__, {:start, state})
  end

  def not_found(pid, client_node) do
    GenServer.cast {__MODULE__, client_node},  {:not_found, pid}
  end

  def found_pass(pass, client_node) do
    GenServer.cast {__MODULE__, client_node}, {:found_pass, pass}
  end

  def update_attempts(attempts, client_node) do
    GenServer.cast {__MODULE__, client_node}, {:update_attempts, attempts}
  end

  ##################################################
  # GenServer implementation
  ##################################################

  def handle_cast({:not_found, worker_pid}, state) do
    worker_count = Enum.count(state.workers)
    state = DispatcherImpl.worker_done(worker_pid, state, worker_count)
    {:noreply, state}
  end

  def handle_cast({:found_pass, pass}, state) do
    Supervisor.stop(Cracker.DispatcherSupervisor)
    send state.client_pid, {:pass_found, pass}
    {:noreply, state}
  end

  def handle_cast({:update_attempts, attempts}, state) do
    state = Map.update(state, :attempts, attempts, &(&1 + attempts))
    send state.client_pid, {:update_attempts, state.attempts}
    {:noreply, state}
  end

  def handle_cast({:start, state}, _) do
    workers = DispatcherImpl.init_workers(state.num_workers)
    workers = Enum.zip(workers, 1..state.num_workers)
    state = Map.put(state, :workers, workers)
    DispatcherImpl.dispatch(state)
    {:noreply, state}
  end

end
