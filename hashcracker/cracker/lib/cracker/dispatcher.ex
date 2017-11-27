defmodule Cracker.Dispatcher do
  use GenServer

  alias Cracker.DispatcherImpl, as: Impl

  ##################################################
  # External API
  ##################################################

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start(state) do
    GenServer.cast(__MODULE__, {:start, state})
  end

  def update_attempts(attempts, client_node) do
    GenServer.cast {__MODULE__, client_node}, {:update_attempts, attempts}
  end

  def not_found(pid, client_node) do
    GenServer.cast {__MODULE__, client_node},  {:not_found, pid}
  end

  def found_pass(pass, client_node) do
    GenServer.cast {__MODULE__, client_node}, {:found_pass, pass}
  end

  ##################################################
  # GenServer implementation
  ##################################################

  def handle_cast({:start, state}, _) do
    state = Impl.start(state)
    {:noreply, state}
  end

  def handle_cast({:update_attempts, attempts}, state) do
    state = Impl.update_attempts(attempts, state)
    {:noreply, state}
  end

  def handle_cast({:not_found, worker_pid}, state) do
    state = Impl.not_found(worker_pid, state)
    {:noreply, state}
  end

  def handle_cast({:found_pass, pass}, state) do
    Impl.found_pass(pass, state)
    {:noreply, state}
  end

end
