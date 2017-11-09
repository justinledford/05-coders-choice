defmodule Cracker.Worker do
  use GenServer

  #####
  # External API
  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  # Take enum and start hasing
  def start_work(enum, hash, hash_type, pid) do
    GenServer.cast(pid, {:work, enum, hash, hash_type})
  end

  # Given enums, get product to generate candidates
  def mask_attack(enums, hash, hash_type, pid) do
    GenServer.cast(pid, {:mask_attack, enums, hash, hash_type})
  end

  #####
  # GenServer implementation
  def handle_cast({:work, enum, hash, hash_type}, _) do
    enum
    |> Cracker.Cracker.find_matching_hash(hash, hash_type)
    |> message_dispatcher
    {:noreply, nil}
  end

  def handle_cast({:mask_attack, enums, hash, hash_type}, _) do
    Cracker.Util.product(enums)
    |> Enum.map(&Enum.join/1)
    |> Cracker.Cracker.find_matching_hash(hash, hash_type)
    |> message_dispatcher
    {:noreply, nil}
  end

  #####
  #

  defp message_dispatcher(nil) do
    Cracker.Dispatcher.not_found(self())
  end

  defp message_dispatcher({pass, _}) do
    Cracker.Dispatcher.found_pass(pass)
  end

end
