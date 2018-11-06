defmodule Bunch.Access do
  @moduledoc """
  A bunch of functions for easier manipulation on terms of types implementing `Access`
  behaviour.
  """
  import Kernel, except: [get_in: 2, put_in: 2, update_in: 3, get_and_update_in: 3, pop_in: 2]
  use Bunch

  @compile {:inline, map_keys: 1}

  @gen_common_docs fn fun_name ->
    """
    Works like `Kernel.#{fun_name}` with small differences.

    Behaviour differs in the following aspects:
    - empty lists of keys are allowed
    - single key does not have to be wrapped in a list
    """
  end

  @doc """
  Implements `Access` behaviour by delegating callbacks to `Map` module.

  All the callbacks are overridable.
  """
  defmacro __using__(_args) do
    quote do
      @behaviour Access

      @impl true
      defdelegate fetch(term, key), to: Map

      @impl true
      defdelegate get_and_update(data, key, list), to: Map

      @impl true
      defdelegate pop(data, key), to: Map

      defoverridable Access
    end
  end

  @doc """
  #{@gen_common_docs.("get_in/2")}
  """
  @spec get_in(Access.t(), Access.key() | [Access.key()]) :: Access.value()
  def get_in(container, []), do: container
  def get_in(container, keys), do: container |> Kernel.get_in(keys |> map_keys)

  @doc """
  #{@gen_common_docs.("put_in/3")}
  """
  @spec put_in(Access.t(), Access.key() | [Access.key()], Access.value()) :: Access.value()
  def put_in(_map, [], v), do: v
  def put_in(container, keys, v), do: container |> Kernel.put_in(keys |> map_keys, v)

  @doc """
  #{@gen_common_docs.("update_in/3")}
  """
  @spec update_in(Access.t(), Access.key() | [Access.key()], (Access.value() -> Access.value())) ::
          Access.t()
  def update_in(container, [], f), do: f.(container)
  def update_in(container, keys, f), do: container |> Kernel.update_in(keys |> map_keys, f)

  @doc """
  #{@gen_common_docs.("get_and_update_in/3")}
  """
  @spec get_and_update_in(Access.t(), Access.key() | [Access.key()], (a -> {b, a})) ::
          {b, Access.t()}
        when a: Access.value(), b: any
  def get_and_update_in(container, [], f), do: f.(container)

  def get_and_update_in(container, keys, f),
    do: container |> Kernel.get_and_update_in(keys |> map_keys, f)

  @doc """
  #{@gen_common_docs.("pop_in/2")}
  """
  @spec pop_in(Access.t(), Access.key() | [Access.key()]) :: {Access.value(), Access.t()}
  def pop_in(container, []), do: {nil, container}
  def pop_in(container, keys), do: container |> Kernel.pop_in(keys |> map_keys)

  @doc """
  Works like `pop_in/2`, but discards returned value.
  """
  @spec delete_in(Access.t(), Access.key() | [Access.key()]) :: Access.t()
  def delete_in(container, keys), do: pop_in(container, keys) ~> ({_out, container} -> container)

  @spec map_keys(Access.key() | [Access.key()]) :: [Access.key()]
  defp map_keys(keys), do: keys |> Bunch.listify()
end
