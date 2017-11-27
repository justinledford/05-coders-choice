defmodule Client do
  @options_aliases [h: :hash, t: :hash_type, a: :attack,
                    n: :num_workers, w: :wordlist_path,
                    m: :mask, i: :increment, c: :client_node]
  @options_strict [hash: :string, hash_type: :string,
                   attack: :string, num_workers: :integer,
                   wordlist_path: :string, mask: :string,
                   increment: :string, help: :boolean,
                   client: :string, worker_nodes: :string,
                   cookie: :string]
  @options [aliases: @options_aliases, strict: @options_strict]

  @name :crackercli

  def main(args) do
    {options, _, _} = OptionParser.parse(args, @options)
    options = options
    |> Enum.into(%{})
    |> check_for_help
    |> validate_required_options
    |> format_required_options
    |> validate_required_option_args
    |> validate_mode_options
    |> set_defaults
    |> format_additional_options
    |> setup_node

    Cracker.crack(options, {@name, options.client_node})

    output()
  end

  def check_for_help(options) do
    Map.has_key?(options, :help)
    |> help_handler(options)
  end
  def help_handler(false, options) do
    options
  end
  def help_handler(true, _options) do
    help()
  end

  def validate_required_options(options) do
    required = [:hash, :hash_type, :attack, :num_workers]
    options
    |> has_required?(required)
  end

  def format_required_options(options) do
    options
    |> Map.update!(:hash_type, &String.to_atom/1)
    |> Map.update!(:attack, &String.to_atom/1)
    |> Map.update!(:hash, fn hash -> Base.decode16!(hash, case: :mixed) end)
  end

  def validate_required_option_args(options) do
    [:dictionary, :mask, :brute]
    |> Enum.any?(fn x -> x == options.attack end)
    |> validation_handler(options)
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

  def set_defaults(options) do
    options
    |> set_client_node
    |> set_worker_nodes
  end

  def set_client_node(options) do
    case Map.has_key?(options, :client_node) do
      true ->
        options
      false ->
        {:ok, hostname} = :inet.gethostname
        Map.put(options, :client_node, "client@#{hostname}")
    end
  end

  def set_worker_nodes(options) do
    case Map.has_key?(options, :worker_nodes) do
      true ->
        options
      false ->
        Map.put(options, :worker_nodes, options.client_node)
    end
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
    |> Map.update!(:client_node, &String.to_atom/1)
    |> Map.update!(:worker_nodes, fn nodes ->
      String.split(nodes, ",") |> Enum.map(&String.to_atom/1)
    end)
  end

  def setup_node(options) do
    {:ok, _} = Node.start(options.client_node, :shortnames)
    if Map.has_key?(options, :cookie) do
      options = Map.update!(options, :cookie, &String.to_atom/1)
      Node.set_cookie(options.cookie)
    end
    Process.register(self(), @name)
    options
  end

  def has_required?(options, required) do
    required
    |> Enum.all?(fn key -> Map.has_key?(options, key) end)
    |> validation_handler(options)
  end

  def validation_handler(false, _options) do
    usage()
  end
  def validation_handler(true, options) do
    options
  end

  def output(attempts_last \\ 0, time_last \\ :os.system_time(:seconds),
             last_hash_rate \\ 0, num_updates \\ 0) do
    receive do
      {:pass_found, pass} ->
        IO.puts "\nPassword found: #{pass}"
      {:pass_not_found, nil} ->
        IO.puts "\nPassword not found"
      {:update_attempts, attempts} ->
        time_now = :os.system_time
        hash_rate = calc_hash_rate(time_last, time_now, attempts_last, attempts)
        hash_rate = ((last_hash_rate*num_updates)+hash_rate)/(num_updates+1)
        IO.ANSI.clear_line()
        IO.write "\r"
        IO.write "~#{attempts} attempts (~#{format_decimal(hash_rate)} hashes/sec)"
        output(attempts, time_now, hash_rate, num_updates+1)
    end
  end

  def calc_hash_rate(time_last, time_now, attempts_last, attempts_now) do
    time_delta = (time_now - time_last) / 1_000_000
    attempts_delta = attempts_now - attempts_last
    attempts_delta / time_delta
  end

  def format_decimal(x, n \\ 3) do
    :io_lib.format("~.#{n}f", [x]) |> IO.iodata_to_binary
  end

  def usage do
    IO.puts \
    """
    Usage:
    ./hashcracker -h HASH -t HASH_TYPE -a ATTACK_MODE -n WORKERS [options]
    ./hashcracker --help
    """
    System.halt(0)
  end

  def help do
    IO.puts \
    """
    Usage: ./hashcracker -h HASH -t HASH_TYPE -a ATTACK_MODE -n WORKERS [options]
    -h, --hash           HASH         base16 encoded hash (lower or upper case)
    -t, --hash-type      HASH_TYPE    md5 | ripemd160 | sha | sha224 | sha256 |
                                      sha384 | sha512
    -a, --attack         ATTACK_MODE  brute | mask | dictionary
    -n, --num-workers    WORKERS      number of parallel workers
    -w, --wordlist-path  PATH         path to wordlist for dictionary attack
    -m, --mask           MASK         mask for mask attack (see section below)
    -i, --increment      START:STOP   increment for mask
    -c, --client         NODE_NAME    shortname for this client (defaults to client@hostname)
    --worker-nodes       NODE_NAMES   comma separated list of worker shortnames
    --cookie             COOKIE       node cookie

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
