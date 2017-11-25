defmodule Cracker do
  def crack(options, client \\ self()) do
    options
    |> Map.put(:client_pid, client)
    |> Cracker.Dispatcher.start

    if client == self() do
      wait_for_results()
    end
  end

  def wait_for_results do
    receive do
      {:pass_found, pass} ->
        pass
      {:pass_not_found, nil} ->
        nil
    end
  end
end
