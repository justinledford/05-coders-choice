defmodule Cracker.Worker do
  use GenServer

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
    state = Map.put(state, :worker_pid, self())
    pid = Node.spawn_link(state.worker_node, fn ->
      Cracker.WorkerImpl.attack(state)
    end)
    {:noreply, Map.put(state, :node_pid, pid)}
  end

end
