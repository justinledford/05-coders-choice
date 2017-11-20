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
    worker_node = Cracker.Dispatcher.table(:"worker#{state.worker_num}")
    pid = Node.spawn_link(worker_node, fn ->
      Cracker.WorkerImpl.attack(state)
    end)
    {:noreply, %{node_pid: pid}}
  end

end
