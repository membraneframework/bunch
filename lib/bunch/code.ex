defmodule Bunch.Code do
  @moduledoc """
  A bunch of helper functions for code compilation, code evaluation, and code loading.
  """

  @doc """
  Takes a code block, expands macros inside and pretty prints it.
  """
  defmacro peek_code(do: block) do
    block
    |> Bunch.Macro.expand_deep(__CALLER__)
    |> Macro.to_string()
    |> IO.puts()

    block
  end
end
