defmodule Cracker.Worker do
  use GenServer

  alias Cracker.WorkerImpl, as: Impl

  ##################################################
  # External API
  ##################################################

  def start_link(num) do
    GenServer.start_link(__MODULE__, [num], name: :"worker#{num}")
  end

  def start_work(state) do
    GenServer.cast(state.worker_pid, {:start_work, state})
  end

  ##################################################
  # GenServer implementation
  ##################################################

  def handle_cast({:start_work, state}, _) do
    state = Impl.start_work(state)
    {:noreply, state}
  end

end
