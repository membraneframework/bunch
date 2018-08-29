defmodule Bunch.Access do
  @moduledoc """
  A set of functions for easier manipulation on terms of types implementing `Access`
  behaviour.

  Behaviour differs from Kernel implementations in some aspects:
  - empty lists of keys are allowed
  - single key does not have to be wrapped in a list
  - `delete_in/2` function is provided
  """
  import Kernel, except: [get_in: 2, put_in: 2, update_in: 3, get_and_update_in: 3, pop_in: 2]
  use Bunch

  @compile {:inline, map_keys: 1}

  @spec get_in(Access.t(), Access.key() | [Access.key()]) :: Access.value()
  def get_in(container, []), do: container
  def get_in(container, keys), do: container |> Kernel.get_in(keys |> map_keys)

  @spec put_in(Access.t(), Access.key() | [Access.key()], Access.value()) :: Access.value()
  def put_in(_map, [], v), do: v
  def put_in(container, keys, v), do: container |> Kernel.put_in(keys |> map_keys, v)

  @spec update_in(Access.t(), Access.key() | [Access.key()], (Access.value() -> Access.value())) ::
          Access.t()
  def update_in(container, [], f), do: f.(container)
  def update_in(container, keys, f), do: container |> Kernel.update_in(keys |> map_keys, f)

  @spec update_in(Access.t(), Access.key() | [Access.key()], (a -> a)) :: {a, Access.t()}
        when a: Access.value()
  def get_and_update_in(container, [], f), do: f.(container)

  def get_and_update_in(container, keys, f),
    do: container |> Kernel.get_and_update_in(keys |> map_keys, f)

  @spec pop_in(Access.t(), Access.key() | [Access.key()]) :: {Access.value(), Access.t()}
  def pop_in(container, []), do: {nil, container}
  def pop_in(container, keys), do: container |> Kernel.pop_in(keys |> map_keys)

  @spec pop_in(Access.t(), Access.key() | [Access.key()]) :: Access.t()
  def delete_in(container, keys), do: pop_in(container, keys) ~> ({_out, container} -> container)

  @spec map_keys(Access.key() | [Access.key()]) :: [Access.key()]
  defp map_keys(keys), do: keys |> Bunch.listify()
end
