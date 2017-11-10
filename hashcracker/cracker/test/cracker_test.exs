defmodule CrackerTest do
  use ExUnit.Case
  doctest Cracker

  test "test brute force cracking" do
    hash_type = :md5
    pass = "foo"
    hash = :crypto.hash(hash_type, pass)
    pass_guess = Cracker.crack(hash, hash_type, :brute, 1)
    assert pass == pass_guess
  end

  test "test brute force cracking, multiple workers" do
    hash_type = :md5
    pass = "foo"
    hash = :crypto.hash(hash_type, pass)
    pass_guess = Cracker.crack(hash, hash_type, :brute, 4)
    assert pass == pass_guess
  end

  #test "test wordlist cracking" do
  #  hash_type = :md5
  #  pass = "password"
  #  hash = :crypto.hash(hash_type, pass)
  #  {pass_guess, hash_guess} = Cracker.crack(hash, hash_type,
  #                                           :dictionary, "wordlist.txt")
  #  assert pass == pass_guess
  #  assert hash == hash_guess
  #end

end
