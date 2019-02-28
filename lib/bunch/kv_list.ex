defmodule Bunch.KVList do
  @moduledoc """
  A bunch of helper functions for manipulating key-value lists (including keyword
  lists).

  Key-value lists are represented as lists of 2-element tuples, where the first
  element of each tuple is a key, and the second is a value.
  """

  @type t(key, value) :: [{key, value}]

  @doc """
  Maps keys of `list` using function `f`.

  ## Example

      iex> #{inspect(__MODULE__)}.map_keys([{1, :a}, {2, :b}], & &1+1)
      [{2, :a}, {3, :b}]

  """
  @spec map_keys(t(k1, v), (k1 -> k2)) :: t(k2, v) when k1: any, k2: any, v: any
  def map_keys(list, f) do
    list |> Enum.map(fn {key, value} -> {f.(key), value} end)
  end

  @doc """
  Maps values of `list` using function `f`.

  ## Example

      iex> #{inspect(__MODULE__)}.map_values([a: 1, b: 2], & &1+1)
      [a: 2, b: 3]

  """
  @spec map_values(t(k, v1), (v1 -> v2)) :: t(k, v2) when k: any, v1: any, v2: any
  def map_values(list, f) do
    list |> Enum.map(fn {key, value} -> {key, f.(value)} end)
  end
end
