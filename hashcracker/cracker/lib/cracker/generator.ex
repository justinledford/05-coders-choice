defmodule Cracker.Generator do
  use GenServer

  #####
  # Externel API

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init_ascii(n) do
    GenServer.cast(__MODULE__, {:ascii, n})
  end

  def init_dictionary(wordlist_path) do
    GenServer.cast(__MODULE__, {:dictionary, wordlist_path})
  end

  def next(n) do
    GenServer.call(__MODULE__, {:next, n})
  end

  def get_stream do
    GenServer.call(__MODULE__, :get_stream)
  end

  ####
  # GenServer implementation
  ####

  def handle_cast({:ascii, n}, _) do
    {:noreply, ascii_strings(n)}
  end

  def handle_cast({:dictionary, wordlist_path}, _) do
    {:noreply, word_list(wordlist_path)}
  end

  def handle_call({:next, n}, _from, stream) do
    {taken, stream} = StreamSplit.take_and_drop(stream, n)
    {:reply, taken, stream}
  end

  def handle_call(:get_stream, _from, stream) do
    {:reply, stream, nil}
  end

  ###
  # Generator functions
  ###

  defp word_list(wordlist_path) do
    File.stream!(wordlist_path)
    |> Stream.map(&String.trim_trailing/1)
  end

  defp ascii_strings(max_length) do
    ?\ ..?~
    |> string_list
    |> generate(max_length)
  end

  defp string_list(range) do
    for n <- range, do: << n :: utf8 >>
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
