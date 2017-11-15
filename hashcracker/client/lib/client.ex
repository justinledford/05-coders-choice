defmodule Client do
  def main(args) do
    options = [
      aliases: [h: :hash, t: :hash_type, a: :attack,
                n: :num_workers, w: :wordlist_path,
                m: :mask, i: :increment],
      strict: [hash: :string, hash_type: :string,
               attack: :string, num_workers: :integer,
               wordlist_path: :string, mask: :string,
               increment: :string]
    ]
    {options, _} = OptionParser.parse!(args, options)
    options
    |> Enum.into(%{})
    |> validate_options
    |> format_options
    |> validate_mode_options
    |> Cracker.crack
    |> IO.puts
  end

  def validate_options(options) do
    required = [:hash, :hash_type, :attack, :num_workers]
    options
    |> has_required?(required)
  end

  def validate_mode_options(options=%{attack: :mask}) do
    has_required?(options, [:mask])
  end
  def validate_mode_options(options=%{attack: :dictionary}) do
    has_required?(options, [:wordlist_path])
  end
  def validate_mode_options(options) do
    options
  end

  def format_options(options) do
    options
    |> Map.update!(:hash_type, &String.to_atom/1)
    |> Map.update!(:attack, &String.to_atom/1)
    |> Map.update!(:hash, fn hash -> Base.decode16!(hash, case: :mixed) end)
  end

  def has_required?(options, required) do
    required
    |> Enum.all?(fn key -> Map.has_key?(options, key) end)
    |> validation_handler(options)
  end

  def valid_args? do

  end

  def validation_handler(false, _options) do
    usage()
  end
  def validation_handler(true, options) do
    options
  end

  def usage do
    IO.puts "usage: ..."
    System.halt(0)
  end
end
