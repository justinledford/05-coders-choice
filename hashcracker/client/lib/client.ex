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
    |> format_required_options
    |> validate_mode_options
    |> format_additional_options
    |> Cracker.crack
    |> print_result
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
  def validate_mode_options(options=%{attack: :mask_increment}) do
    has_required?(options, [:mask, :increment])
  end
  def validate_mode_options(options) do
    options
  end

  def format_required_options(options) do
    options
    |> Map.update!(:hash_type, &String.to_atom/1)
    |> Map.update!(:attack, &String.to_atom/1)
    |> Map.update!(:hash, fn hash -> Base.decode16!(hash, case: :mixed) end)
  end

  def format_additional_options(options=%{increment: increment}) do
    [start, stop] = String.split(increment, ":")
                    |> Enum.map(&String.to_integer/1)
    options
    |> Map.drop([:increment])
    |> Map.merge(%{start: start, stop: stop})
  end
  def format_additional_options(options) do
    options
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

  def print_result(nil) do
    IO.puts "Password not found..."
  end

  def print_result(pass) do
    IO.puts "Password found: #{pass}"
  end

  def usage do
    IO.puts \
    """
    Usage: ./hashcracker -h HASH -t HASH_TYPE -a ATTACK_MODE -n WORKERS [options]
    -h, --hash           HASH         base16 encoded hash (lower or upper case)
    -t, --hash_type      HASH_TYPE    md5 | ripemd160 | sha | sha224 | sha256 |
                                      sha384 | sha512
    -a, --attack         ATTACK_MODE  brute | mask | mask_increment | dictionary
    -n, --num_workers    WORKERS      number of parallel workers
    -w, --wordlist_path  PATH         path to wordlist for dictionary attack
    -m, --mask           MASK         mask for mask attack (see section below)
    -i, --increment      START:STOP   increment for mask

    Mask attack:
    A mask is useful to exploit certain patterns found in passwords,
    such an uppercase letter for the first character, a certain
    number of lowercase letters after, followed by a number.

    This pattern would be represented as the following mask:
    ?u?l?l?l?d

    Each position of a string is replaced with the following character sets:
    ?l | abcdefghijklmnopqrstuvwxyz
    ?u | ABCDEFGHIJKLMNOPQRSTUVWXYZ
    ?d | 0123456789
    ?s | !"#$%&'()*+,-./:;<=>?@[\]^_`{|}~
    ?a | ?l?u?d?s
    """
    System.halt(0)
  end
end
