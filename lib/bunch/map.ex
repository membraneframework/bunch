defmodule Bunch.Map do
  @moduledoc """
  A bunch of helper functions for manipulating maps.
  """

  @doc """
  Maps keys of `map` using function `f`.

  ## Example

      iex> #{inspect(__MODULE__)}.map_keys(%{1 => :a, 2 => :b}, & &1+1)
      %{2 => :a, 3 => :b}

  """
  @spec map_keys(%{k1 => v}, (k1 -> k2)) :: %{k2 => v} when k1: any, k2: any, v: any
  def map_keys(map, f) do
    map |> Enum.into(Map.new(), fn {key, value} -> {f.(key), value} end)
  end

  @doc """
  Maps values of `map` using function `f`.

  ## Example

      iex> #{inspect(__MODULE__)}.map_values(%{a: 1, b: 2}, & &1+1)
      %{a: 2, b: 3}

  """
  @spec map_values(%{k => v1}, (v1 -> v2)) :: %{k => v2} when k: any, v1: any, v2: any
  def map_values(map, f) do
    map |> Enum.into(Map.new(), fn {key, value} -> {key, f.(value)} end)
  end

  @doc """
  Moves value stored at `old_key` to `new_key`.

  If `old_key` is not present in `map`, `new_key` is removed. If `new_key`
  is present in `map`, it's value is overwritten.

  ## Examples

      iex> #{inspect(__MODULE__)}.move(%{a: 1, b: 2}, :a, :c)
      %{b: 2, c: 1}
      iex> #{inspect(__MODULE__)}.move(%{a: 1, b: 2}, :a, :b)
      %{b: 1}
      iex> #{inspect(__MODULE__)}.move(%{a: 1, b: 2}, :c, :b)
      %{a: 1}

  """
  @spec move(%{k => v}, old_key :: k, new_key :: k) :: %{k => v} when k: any, v: any
  def move(map, old_key, new_key) do
    if map |> Map.has_key?(old_key) do
      {value, map} = map |> Map.pop(old_key)
      map |> Map.put(new_key, value)
    else
      map |> Map.delete(new_key)
    end
  end
end