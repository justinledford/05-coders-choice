defmodule Cracker.Util do

  def product(enums) do
    Enum.reduce(enums, [[]], fn enum, acc ->
      for x <- enum, y <- acc, do: [x | y]
    end)
    |> Enum.map(&Enum.reverse/1)
  end

end
