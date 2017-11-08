defmodule Cracker.Queue do
  def start_link do
    Agent.start_link(fn -> :queue.new() end, name: __MODULE__)
  end

  def enqueue(item) do
    Agent.get_and_update(__MODULE__, fn queue ->
      queue = :queue.in(item, queue)
      {queue, queue}
    end)
  end

  def dequeue do
    Agent.get_and_update(__MODULE__, fn queue ->
      case :queue.is_empty(queue) do
        false ->
          {{:value, value}, queue} = :queue.out(queue)
        true ->
          {:empty, queue} = :queue.out(queue)
          value = []
      end

      {value, queue}
    end)
  end
end
