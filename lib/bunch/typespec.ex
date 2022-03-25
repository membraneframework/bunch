defmodule Bunch.Typespec do
  @moduledoc """
  A bunch of typespec-related helpers.
  """

  defmacro __using__(_args) do
    quote do
      import Kernel, except: [@: 1]
      import unquote(__MODULE__), only: [@: 1]
    end
  end

  @doc """
  Allows to define a type in form of `t :: x | y | z | ...` and a module parameter
  in form of `@t [x, y, z, ...]` at once.

  ## Example

      iex> defmodule Abc do
      ...> use #{inspect(__MODULE__)}
      ...> @list_type t :: [:a, :b, :c]
      ...> @spec get_at(0..2) :: t
      ...> def get_at(x), do: @t |> Enum.at(x)
      ...> end
      iex> Abc.get_at(1)
      :b

  """
  # credo:disable-for-next-line Credo.Check.Consistency.UnusedVariableNames
  defmacro @{:list_type, _, [{:"::", _, [{name, _, _env} = name_var, list]}]} do
    type = list |> Enum.reduce(fn a, b -> {:|, [], [a, b]} end)

    quote do
      @type unquote(name_var) :: unquote(type)
      Module.put_attribute(__MODULE__, unquote(name), unquote(list))
    end
  end

  defmacro @expr do
    quote do
      Kernel.@(unquote(expr))
    end
  end
end
