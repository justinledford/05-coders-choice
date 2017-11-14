defmodule CrackerTest do
  use ExUnit.Case
  doctest Cracker

  test "brute force attack" do
    pass = "foo"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :brute,
                num_workers: 1}
    pass_guess = Cracker.crack(options)
    assert pass == pass_guess
  end

  test "brute force attack, multiple workers" do
    pass = "foo"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :brute,
                num_workers: 4}
    pass_guess = Cracker.crack(options)
    assert pass == pass_guess
  end

  test "mask attack" do
    pass = "foo"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :mask,
                mask: "?l?l?l",
                num_workers: 1}
    pass_guess = Cracker.crack(options)
    assert pass == pass_guess
  end

  test "mask attack 1 char mask" do
    pass = "f"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :mask,
                mask: "?l",
                num_workers: 1}
    pass_guess = Cracker.crack(options)
    assert pass == pass_guess
  end

  test "mask attack, multiple workers" do
    pass = "foo"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :mask,
                mask: "?l?l?l",
                num_workers: 4}
    pass_guess = Cracker.crack(options)
    assert pass == pass_guess

  end

  test "mask attack pass not found" do
    pass = "foo"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :mask,
                mask: "?l",
                num_workers: 4}
    pass_guess = Cracker.crack(options)
    assert nil == pass_guess
  end

  test "dictionary attack" do
    pass = "foo"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :dictionary,
                wordlist_path: "test/wordlist.txt",
                num_workers: 1}
    pass_guess = Cracker.crack(options)
    assert pass == pass_guess
  end

  test "dictionary attack, multiple workers" do
    pass = "foo"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :dictionary,
                wordlist_path: "test/wordlist.txt",
                num_workers: 4}
    pass_guess = Cracker.crack(options)
    assert pass == pass_guess
  end

  test "dictionary attack pass not found" do
    pass = "foobarbaz"
    options = %{hash: :crypto.hash(:md5, pass),
                hash_type: :md5,
                attack: :dictionary,
                wordlist_path: "test/wordlist.txt",
                num_workers: 4}
    pass_guess = Cracker.crack(options)
    assert nil == pass_guess
  end

end
