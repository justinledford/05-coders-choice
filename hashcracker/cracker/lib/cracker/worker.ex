defmodule Cracker.Worker do
  use GenServer

  ##################################################
  # External API
  ##################################################

  def start_link(num) do
    GenServer.start_link(__MODULE__, [], name: String.to_atom("Worker-#{num}"))
  end

  def start_work(state) do
    GenServer.cast(state.worker, {:start_work, state})
  end

  ##################################################
  # GenServer implementation
  ##################################################

  def handle_cast({:start_work, state}, _) do
    Cracker.WorkerImpl.attack(state)
    {:noreply, nil}
  end

end
