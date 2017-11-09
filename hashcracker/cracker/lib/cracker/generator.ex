defmodule Cracker.Generator do
  use GenServer

  @num_strings 65536

  #####
  # Externel API

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init_ascii(n) do
    GenServer.cast(__MODULE__, {:ascii, n})
  end

  #def init_dictionary(wordlist_path) do
  #  GenServer.cast(__MODULE__, {:dictionary, wordlist_path})
  #end

  ####
  # GenServer implementation
  ####

  def handle_cast({:ascii, n}, _) do
    task = Task.async(&generate_task/0)
    {:noreply, task}
  end

  #def handle_cast({:dictionary, wordlist_path}, _) do
  #  {:noreply, word_list(wordlist_path)}
  #end

  ###
  # Generator functions
  ###

  def generate_task do
    ascii_strings(50)
    |> StreamSplit.take_and_drop(@num_strings)
    |> generate_task
  end

  def generate_task({:halted, {_, taken}}) do
    Cracker.Dispatcher.work_ready(taken)
  end

  def generate_task({taken, stream}) do
    Cracker.Dispatcher.work_ready(taken)
    stream
    |> StreamSplit.take_and_drop(@num_strings)
    |> generate_task
  end

  defp word_list(wordlist_path) do
    File.stream!(wordlist_path)
    |> Stream.map(&String.trim_trailing/1)
  end

  defp ascii_strings(max_length) do
    ?\ ..?~
    |> Cracker.Util.string_list
    |> generate(max_length)
  end

  defp _generate(source, target) do
    Stream.flat_map(source, fn x ->
      Stream.map(target,
                 &(Enum.join([x, &1])))
    end)
  end

  defp generate(source, n) do
    Enum.reduce(1..n, [source], fn _, [last | acc] ->
      generated = _generate(source, last)
      [generated | [last | acc]]
    end)
    |> Enum.reverse
    |> Stream.concat
  end


end
