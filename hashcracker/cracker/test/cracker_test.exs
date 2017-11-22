defmodule CrackerTest do
  use ExUnit.Case
  doctest Cracker

  # Tests can be run with distributed nodes
  # by modifying worker_nodes below
  setup do
    {:ok, hostname} = :inet.gethostname
    client_node = :"client@#{hostname}"
    Node.start(client_node, :shortnames)
    worker_nodes = [:"client@#{hostname}"]
    {:ok, client_node: client_node, worker_nodes: worker_nodes}
  end

  test "brute force attack", context do
    client_node = context[:client_node]
    worker_nodes = context[:worker_nodes]
    pass = "foo"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :brute,
                num_workers: 1,
                client_node: client_node,
                worker_nodes: worker_nodes}
    pass_guess = Cracker.crack(options)
    assert pass == pass_guess
  end

  test "brute force attack, multiple workers", context do
    client_node = context[:client_node]
    worker_nodes = context[:worker_nodes]
    pass = "foo"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :brute,
                num_workers: 4,
                client_node: client_node,
                worker_nodes: worker_nodes}
    pass_guess = Cracker.crack(options)
    assert pass == pass_guess
  end

  test "mask attack", context do
    client_node = context[:client_node]
    worker_nodes = context[:worker_nodes]
    pass = "foo"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :mask,
                mask: "?l?l?l",
                num_workers: 1,
                client_node: client_node,
                worker_nodes: worker_nodes}
    pass_guess = Cracker.crack(options)
    assert pass == pass_guess
  end

  test "mask attack 1 char mask", context do
    client_node = context[:client_node]
    worker_nodes = context[:worker_nodes]
    pass = "f"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :mask,
                mask: "?l",
                num_workers: 1,
                client_node: client_node,
                worker_nodes: worker_nodes}
    pass_guess = Cracker.crack(options)
    assert pass == pass_guess
  end

  test "mask attack, multiple workers", context do
    client_node = context[:client_node]
    worker_nodes = context[:worker_nodes]
    pass = "foo"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :mask,
                mask: "?l?l?l",
                num_workers: 4,
                client_node: client_node,
                worker_nodes: worker_nodes}
    pass_guess = Cracker.crack(options)
    assert pass == pass_guess

  end

  test "mask attack pass not found", context do
    client_node = context[:client_node]
    worker_nodes = context[:worker_nodes]
    pass = "foo"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :mask,
                mask: "?l",
                num_workers: 4,
                client_node: client_node,
                worker_nodes: worker_nodes}
    pass_guess = Cracker.crack(options)
    assert nil == pass_guess
  end

  test "dictionary attack", context do
    client_node = context[:client_node]
    worker_nodes = context[:worker_nodes]
    pass = "foo"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :dictionary,
                wordlist_path: "test/wordlist.txt",
                num_workers: 1,
                client_node: client_node,
                worker_nodes: worker_nodes}
    pass_guess = Cracker.crack(options)
    assert pass == pass_guess
  end

  test "dictionary attack, multiple workers", context do
    client_node = context[:client_node]
    worker_nodes = context[:worker_nodes]
    pass = "foo"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :dictionary,
                wordlist_path: "test/wordlist.txt",
                num_workers: 4,
                client_node: client_node,
                worker_nodes: worker_nodes}
    pass_guess = Cracker.crack(options)
    assert pass == pass_guess
  end

  test "dictionary attack pass not found", context do
    client_node = context[:client_node]
    worker_nodes = context[:worker_nodes]
    pass = "foobarbaz"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :dictionary,
                wordlist_path: "test/wordlist.txt",
                num_workers: 4,
                client_node: client_node,
                worker_nodes: worker_nodes}
    pass_guess = Cracker.crack(options)
    assert nil == pass_guess
  end

end
