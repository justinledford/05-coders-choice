defmodule CrackerTest do
  use ExUnit.Case
  doctest Cracker

  test "brute force attack" do
    hash_type = :md5
    pass = "foo"
    hash = :crypto.hash(hash_type, pass)
    pass_guess = Cracker.crack(hash, hash_type, :brute, 1)
    assert pass == pass_guess
  end

  test "brute force attack, multiple workers" do
    hash_type = :md5
    pass = "foo"
    hash = :crypto.hash(hash_type, pass)
    pass_guess = Cracker.crack(hash, hash_type, :brute, 4)
    assert pass == pass_guess
  end

  test "mask attack" do
    hash_type = :md5
    pass = "foo"
    hash = :crypto.hash(hash_type, pass)
    pass_guess = Cracker.crack(hash, hash_type, :mask, "?l?l?l", 1)
    assert pass == pass_guess
  end

  test "mask attack 1 char mask" do
    hash_type = :md5
    pass = "f"
    hash = :crypto.hash(hash_type, pass)
    pass_guess = Cracker.crack(hash, hash_type, :mask, "?l", 1)
    assert pass == pass_guess
  end

  test "mask attack, multiple workers" do
    hash_type = :md5
    pass = "foo"
    hash = :crypto.hash(hash_type, pass)
    pass_guess = Cracker.crack(hash, hash_type, :mask, "?l?l?l", 4)
    assert pass == pass_guess
  end

  #test "dictionary attack" do
  #  hash_type = :md5
  #  pass = "foo"
  #  hash = :crypto.hash(hash_type, pass)
  #  pass_guess = Cracker.crack(hash, hash_type, :dictionary, "wordlist.txt", 1)
  #  assert pass == pass_guess
  #end

  #test "dictionary attack, multiple workers" do
  #  hash_type = :md5
  #  pass = "foo"
  #  hash = :crypto.hash(hash_type, pass)
  #  pass_guess = Cracker.crack(hash, hash_type, :dictionary, "wordlist.txt", 4)
  #  assert pass == pass_guess
  #end
end
