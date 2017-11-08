defmodule Cracker.Worker do
  use GenServer

  #####
  # External API
  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def start_work(hash, hash_type, pid) do
    GenServer.cast(pid, {:work, hash, hash_type})
  end

  #####
  # GenServer implementation
  def handle_cast({:work, hash, hash_type}, _) do
    Cracker.Queue.dequeue()
    |> find_matching_hash(hash, hash_type)
    |> message_dispatcher
    {:noreply, nil}
  end

  #####
  #

  defp message_dispatcher(nil) do
    Cracker.Dispatcher.request_more_work(self())
  end

  defp message_dispatcher({pass, _}) do
    Cracker.Dispatcher.found_pass(pass)
  end

  defp find_matching_hash(enum, hash, hash_type) do
    enum
    |> Stream.map(fn x -> { x, :crypto.hash(hash_type, x) } end)
    |> Enum.find(fn { _, hash_ } -> hash_ == hash end)
  end
end
