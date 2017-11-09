defmodule Cracker.Charsets do
  import Cracker.Util

  def l do
    string_list(?a..?z)
  end

  def u do
    string_list(?A..?Z)
  end

  def d do
    string_list(?0..?9)
  end

  def s do
    string_list(?\ ..?/) ++ string_list(?[..?`) ++ string_list(?{..?~)
  end

  def a do
    l() ++ u() ++ d() ++ s()
  end

end
