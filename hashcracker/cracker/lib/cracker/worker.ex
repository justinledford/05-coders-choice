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

  def mask_attack_increment(enums, start, stop, hash, hash_type, pid) do
    GenServer.cast(pid, {:mask_attack_increment, enums, start, stop,
                         hash, hash_type})
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
    |> Stream.map(&Enum.join/1)
    |> Cracker.Cracker.find_matching_hash(hash, hash_type)
    |> message_dispatcher
    {:noreply, nil}
  end

  # TODO: make this not ugly
  def handle_cast(
    {:mask_attack_increment, enums, start, stop, hash, hash_type}, _) do

    enums_partial = Enum.take(enums, start)
    enums = Enum.drop(enums, start)
    Enum.reduce(start..stop, {enums_partial, [[]]},
                fn i, {enums_partial, results} ->

      results = Cracker.Util.product(enums_partial, results)
      results
      |> Stream.map(&Enum.join/1)
      |> Cracker.Cracker.find_matching_hash(hash, hash_type)
      |> mask_increment_update

      enums_partial = Enum.take(enums, 1)
      enums = Enum.drop(enums, 1)

      {enums_partial, results}
    end)

    message_dispatcher(nil)
    {:noreply, nil}
  end

  #####
  #

  defp mask_increment_update(nil) do
  end
  defp mask_increment_update({pass, _}) do
    Cracker.Dispatcher.found_pass(pass)
  end

  defp message_dispatcher(nil) do
    Cracker.Dispatcher.not_found(self())
  end

  defp message_dispatcher({pass, _}) do
    Cracker.Dispatcher.found_pass(pass)
  end

end
