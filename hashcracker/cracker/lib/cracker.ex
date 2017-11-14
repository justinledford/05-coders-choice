defmodule Cracker do
  def crack(options=%{attack: :brute}) do
    options
    |> Map.put(:client_pid, self())
    |> Cracker.Dispatcher.start_brute_force

    receive do
      {:pass_found, pass} ->
        pass
      {:pass_not_found, nil} ->
        nil
    end
  end

  def crack(options=%{attack: :mask}) do
    options
    |> Map.put(:client_pid, self())
    |> Cracker.Dispatcher.start_mask

    receive do
      {:pass_found, pass} ->
        pass
      {:pass_not_found, nil} ->
        nil
    end
  end

  def crack(options=%{attack: :mask_increment}) do
    options
    |> Map.put(:client_pid, self())
    |> Cracker.Dispatcher.start_mask_increment

    receive do
      {:pass_found, pass} ->
        pass
      {:pass_not_found, nil} ->
        nil
    end
  end

  def crack(options=%{attack: :dictionary}) do
    options
    |> Map.put(:client_pid, self())
    |> Cracker.Dispatcher.start_dictionary

    receive do
      {:pass_found, pass} ->
        pass
      {:pass_not_found, nil} ->
        nil
    end
  end

end
