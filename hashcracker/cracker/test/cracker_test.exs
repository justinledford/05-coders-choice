defmodule CrackerTest do
  use ExUnit.Case
  doctest Cracker

  test "test brute force cracking" do
    hash_type = :md5
    pass = "foo"
    hash = :crypto.hash(hash_type, pass)
    {pass_guess, hash_guess} = Cracker.crack(hash, hash_type, :brute)
    assert pass == pass_guess
    assert hash == hash_guess
  end
end
