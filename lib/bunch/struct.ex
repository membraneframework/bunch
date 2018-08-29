defmodule Bunch.Struct do
  @moduledoc """
  A set of functions for easier manipulation on structs that do not implement
  `Access` behaviour.

  For more details see `Bunch.Access` module.
  """
  import Kernel, except: [get_in: 2, put_in: 2, update_in: 3, get_and_update_in: 3, pop_in: 2]
  use Bunch

  @compile {:inline, map_keys: 1}

  @spec get_in(struct, Access.key() | [Access.key()]) :: Access.value()
  def get_in(struct, keys), do: struct |> Bunch.Access.get_in(keys |> map_keys())

  @spec put_in(struct, Access.key() | [Access.key()], Access.value()) :: Access.value()
  def put_in(struct, keys, v), do: struct |> Bunch.Access.put_in(keys |> map_keys(), v)

  @spec update_in(struct, Access.key() | [Access.key()], (Access.value() -> Access.value())) ::
          struct
  def update_in(struct, keys, f), do: struct |> Bunch.Access.update_in(keys |> map_keys(), f)

  @spec update_in(struct, Access.key() | [Access.key()], (a -> a)) :: {a, struct}
        when a: Access.value()
  def get_and_update_in(struct, keys, f),
    do: struct |> Bunch.Access.get_and_update_in(keys |> map_keys(), f)

  @spec pop_in(struct, Access.key() | [Access.key()]) :: {Access.value(), struct}
  def pop_in(struct, keys), do: struct |> Bunch.Access.pop_in(keys |> map_keys())

  @spec pop_in(struct, Access.key() | [Access.key()]) :: struct
  def delete_in(struct, keys), do: struct |> Bunch.Access.delete_in(keys |> map_keys())

  @spec map_keys(Access.key() | [Access.key()]) :: [Access.access_fun(struct | map, term)]
  defp map_keys(keys), do: keys |> Bunch.listify() |> Enum.map(&Access.key(&1, nil))
end
