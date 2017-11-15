defmodule Cracker do
  def crack(options) do
    options
    |> Map.put(:client_pid, self())
    |> Cracker.Dispatcher.start
    wait_for_results()
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
