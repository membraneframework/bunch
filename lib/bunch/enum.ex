defmodule Bunch.Enum do
  @moduledoc """
  Module containing helper functions for manipulating enums.
  """

  use Bunch

  @doc """
  Generates a list consisting of `i` values `v`.

  ```
  iex> #{__MODULE__}.repeat(4, :abc)
  [:abc, :abc, :abc, :abc]
  iex> #{__MODULE__}.repeat(0, :abc)
  []
  ```
  """
  @spec repeat(non_neg_integer, v) :: [v] when v: any()
  def repeat(i, v) when i >= 0 do
    do_repeat(i, v, [])
  end

  defp do_repeat(0, _v, acc) do
    acc
  end

  defp do_repeat(i, v, acc) do
    do_repeat(i - 1, v, [v | acc])
  end

  @doc """
  Generates a list by calling `i` times function `f`.

  ```
  iex> #{__MODULE__}.repeatedly(4, fn -> :abc end)
  [:abc, :abc, :abc, :abc]
  iex> #{__MODULE__}.repeatedly(0, fn -> :abc end)
  []
  ```
  """
  @spec repeatedly(non_neg_integer, f :: (() -> a)) :: [a] when a: any()
  def repeatedly(i, fun) when i >= 0 do
    do_repeatedly(i, fun, [])
  end

  defp do_repeatedly(0, _fun, acc) do
    acc |> Enum.reverse()
  end

  defp do_repeatedly(i, fun, acc) do
    do_repeatedly(i - 1, fun, [fun.() | acc])
  end

  @doc """
  Splits enumerable into chunks, and passes each chunk through `collector`.
  New chunk is created each time `chunker` returns `false`. The `chunker` is passed
  current and previous element of enumerable.

  ## Examples:
  ```
  iex> #{__MODULE__}.chunk_by_prev([1,2,5,5], fn x, y -> x - y <= 2 end)
  [[1, 2], [5, 5]]
  iex> #{__MODULE__}.chunk_by_prev([1,2,5,5], fn x, y -> x - y <= 2 end, &Enum.sum/1)
  [3, 10]
  ```
  """
  @spec chunk_by_prev(Enum.t(), chunker :: (a, a -> boolean), collector :: ([a] -> b)) :: [b]
        when a: any(), b: any()
  def chunk_by_prev(enum, chunker, collector \\ & &1) do
    enum
    |> Enum.to_list()
    ~> (
      [h | t] -> do_chunk_by_prev(t, chunker, collector, [[h]])
      [] -> []
    )
  end

  defp do_chunk_by_prev([h | t], chunker, collector, [[lh | lt] | acc]) do
    do_chunk_by_prev(
      t,
      chunker,
      collector,
      if chunker.(h, lh) do
        [[h, lh | lt] | acc]
      else
        [[h], [lh | lt] |> Enum.reverse() |> collector.() | acc]
      end
    )
  end

  defp do_chunk_by_prev([], _chunker, collector, [l | acc]) do
    [l |> Enum.reverse() |> collector.() | acc] |> Enum.reverse()
  end

  @doc """
  Works like `Enum.reduce/3` as long as given `fun` returns `{:ok, new_acc}`.
  If it happens to return `{{:error, reason}, new_acc}`, reduction is stopped and
  error is returned.

  ## Examples:
  ```
  iex> fun = fn
  ...> x, acc when acc >= 0 -> {:ok,  x + acc}
  ...> _, acc -> {{:error, :negative_prefix_sum}, acc}
  ...> end
  iex> #{__MODULE__}.try_reduce([1,5,-2,8], 0, fun)
  {:ok, 12}
  iex> #{__MODULE__}.try_reduce([1,5,-7,8], 0, fun)
  {{:error, :negative_prefix_sum}, -1}
  ```
  """
  @spec try_reduce(Enum.t(), acc, fun :: (a, acc -> result)) :: result
        when a: any(), acc: any(), result: {:ok, acc} | {{:error, any()}, acc}
  def try_reduce(enum, acc, f) do
    Enum.reduce_while(enum, {:ok, acc}, fn e, {:ok, acc} ->
      with {:ok, new_acc} <- f.(e, acc) do
        {:cont, {:ok, new_acc}}
      else
        {{:error, reason}, new_acc} -> {:halt, {{:error, reason}, new_acc}}
      end
    end)
  end

  @doc """
  Works like `Enum.reduce_while/3` as long as given `fun` returns
  `{:ok, {:cont | :halt, new_acc}`. If it happens to return
  `{{:error, reason}, new_acc}`, reduction is stopped and error is returned.

  ## Examples:
  ```
  iex> fun = fn
  ...> 0, acc -> {{:ok, :halt}, acc}
  ...> x, acc when acc >= 0 -> {{:ok, :cont}, x + acc}
  ...> _, acc -> {{:error, :negative_prefix_sum}, acc}
  ...> end
  iex> #{__MODULE__}.try_reduce_while([1,5,-2,8], 0, fun)
  {:ok, 12}
  iex> #{__MODULE__}.try_reduce_while([1,5,0,8], 0, fun)
  {:ok, 6}
  iex> #{__MODULE__}.try_reduce_while([1,5,-7,8], 0, fun)
  {{:error, :negative_prefix_sum}, -1}
  ```
  """
  @spec try_reduce_while(
          Enum.t(),
          acc,
          reducer :: (a, acc -> {{:ok, :cont | :halt} | error, acc})
        ) :: {:ok, acc} | {error, acc}
        when a: any(), acc: any(), error: {:error, any()}
  def try_reduce_while(enum, acc, f) do
    Enum.reduce_while(enum, {:ok, acc}, fn e, {:ok, acc} ->
      with {{:ok, :cont}, new_acc} <- f.(e, acc) do
        {:cont, {:ok, new_acc}}
      else
        {{:ok, :halt}, new_acc} -> {:halt, {:ok, new_acc}}
        {{:error, reason}, new_acc} -> {:halt, {{:error, reason}, new_acc}}
      end
    end)
  end

  @doc """
  Works like `Enum.each/2` as long as given `fun` returns `:ok`.
  If it happens to return `{:error, reason}`, traversal is stopped and
  error is returned.

  ## Examples:
  ```
  iex> fun = fn 0 -> {:error, :zero}; x -> send(self(), 1/x); :ok end
  iex> #{__MODULE__}.try_each([1,2,3], fun)
  :ok
  iex> #{__MODULE__}.try_each([1,0,3], fun)
  {:error, :zero}
  ```
  """
  @spec try_each(Enum.t(), fun :: (a -> result)) :: result
        when a: any(), result: :ok | {:error, any()}
  def try_each(enum, f), do: do_try_each(enum |> Enum.to_list(), f)
  defp do_try_each([], _f), do: :ok

  defp do_try_each([h | t], f) do
    with :ok <- f.(h) do
      do_try_each(t, f)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Works like `Enum.map/2` as long as given `fun` returns `{:ok, value}`.
  If it happens to return `{:error, reason}`, reduction is stopped and
  error is returned.

  ## Examples:
  ```
  iex> fun = fn 0 -> {:error, :zero}; x -> {:ok, 1/x} end
  iex> #{__MODULE__}.try_map([1,5,-2,8], fun)
  {:ok, [1.0, 0.2, -0.5, 0.125]}
  iex> #{__MODULE__}.try_map([1,5,0,8], fun)
  {:error, :zero}
  ```
  """
  @spec try_map(Enum.t(), fun :: (a -> {:ok, b} | error)) :: {:ok, [b]} | error
        when a: any(), b: any(), error: {:error, any()}
  def try_map(enum, f), do: do_try_map(enum |> Enum.to_list(), f, [])
  defp do_try_map([], _f, acc), do: {:ok, acc |> Enum.reverse()}

  defp do_try_map([h | t], f, acc) do
    with {:ok, res} <- f.(h) do
      do_try_map(t, f, [res | acc])
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Works like `Enum.flat_map/2` as long as reducing function returns `{:ok, values}`.
  If it happens to return `{:error, reason}`, reduction is stopped and
  error is returned.

  ## Examples:
  ```
  iex> fun = fn 0 -> {:error, :zero}; x -> {:ok, [1/x, 2/x, 3/x]} end
  iex> #{__MODULE__}.try_flat_map([1,5,-2,8], fun)
  {:ok, [1.0, 2.0, 3.0, 0.2, 0.4, 0.6, -0.5, -1.0, -1.5, 0.125, 0.25, 0.375]}
  iex> #{__MODULE__}.try_flat_map([1,5,0,8], fun)
  {:error, :zero}
  ```
  """
  @spec try_flat_map(Enum.t(), fun :: (a -> result)) :: result
        when a: any(), b: any(), result: {:ok, [b]} | {:error, any()}
  def try_flat_map(enum, f), do: do_try_flat_map(enum |> Enum.to_list(), f, [])
  defp do_try_flat_map([], _f, acc), do: {:ok, acc |> Enum.reverse()}

  defp do_try_flat_map([h | t], f, acc) do
    with {:ok, res} <- f.(h) do
      do_try_flat_map(t, f, res |> Enum.reverse(acc))
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Works like `Enum.map_reduce/3` as long as given `fun` returns `{{:ok, value}, new_acc}`.
  If it happens to return `{{:error, reason}, new_acc}`, reduction is stopped and
  error is returned.

  ## Examples:
  ```
  iex> fun = fn
  ...> x, acc when acc >= 0 -> {{:ok, x+1}, x + acc}
  ...> _, acc -> {{:error, :negative_prefix_sum}, acc}
  ...> end
  iex> #{__MODULE__}.try_map_reduce([1,5,-2,8], 0, fun)
  {{:ok, [2,6,-1,9]}, 12}
  iex> #{__MODULE__}.try_map_reduce([1,5,-7,8], 0, fun)
  {{:error, :negative_prefix_sum}, -1}
  ```
  """
  @spec try_map_reduce(Enum.t(), acc, fun :: (a, acc -> {{:ok, b}, acc} | error)) ::
          {{:ok, [b]}, acc} | error
        when a: any(), b: any(), acc: any(), error: {:error, any()}
  def try_map_reduce(enum, acc, f), do: do_try_map_reduce(enum |> Enum.to_list(), acc, f, [])
  defp do_try_map_reduce([], f_acc, _f, acc), do: {{:ok, acc |> Enum.reverse()}, f_acc}

  defp do_try_map_reduce([h | t], f_acc, f, acc) do
    with {{:ok, res}, f_acc} <- f.(h, f_acc) do
      do_try_map_reduce(t, f_acc, f, [res | acc])
    else
      {{:error, reason}, f_acc} -> {{:error, reason}, f_acc}
    end
  end

  @doc """
  Works like `Enum.flat_map_reduce/3` as long as given `fun` returns `{{:ok, value}, new_acc}`.
  If it happens to return `{{:error, reason}, new_acc}`, reduction is stopped and
  error is returned.

  ## Examples:
  ```
  iex> fun = fn
  ...> x, acc when acc >= 0 -> {{:ok, [x+1, x+2, x+3]}, x + acc}
  ...> _, acc -> {{:error, :negative_prefix_sum}, acc}
  ...> end
  iex> #{__MODULE__}.try_flat_map_reduce([1,5,-2,8], 0, fun)
  {{:ok, [2,3,4,6,7,8,-1,0,1,9,10,11]}, 12}
  iex> #{__MODULE__}.try_flat_map_reduce([1,5,-7,8], 0, fun)
  {{:error, :negative_prefix_sum}, -1}
  ```
  """
  @spec try_flat_map_reduce(Enum.t(), acc, fun :: (a, acc -> result)) :: result
        when a: any(), b: any(), acc: any(), result: {{:ok, [b]} | {:error, any()}, acc}
  def try_flat_map_reduce(enum, acc, f),
    do: try_flat_map_reduce(enum |> Enum.to_list(), acc, f, [])

  defp try_flat_map_reduce([], f_acc, _f, acc), do: {{:ok, acc |> Enum.reverse()}, f_acc}

  defp try_flat_map_reduce([h | t], f_acc, f, acc) do
    with {{:ok, res}, f_acc} <- f.(h, f_acc) do
      try_flat_map_reduce(t, f_acc, f, (res |> Enum.reverse()) ++ acc)
    else
      {{:error, reason}, f_acc} -> {{:error, reason}, f_acc}
      {:error, reason} -> {{:error, reason}, f_acc}
    end
  end

  @doc """
  Works the same way as `Enum.zip/1`, but does not cut off remaining values.

  ## Examples:
  ```
  iex> #{__MODULE__}.zip_longest([[1, 2] ,[3 ,4, 5]])
  [[1, 3], [2, 4], [5]]
  ```
  It also returns list of lists, as opposed to tuples.
  """
  @spec zip_longest(list()) :: list(list())
  def zip_longest(lists) when is_list(lists) do
    zip_longest_recurse(lists, [])
  end

  defp zip_longest_recurse(lists, acc) do
    {lists, zipped} =
      lists
      |> Enum.reject(&Enum.empty?/1)
      |> Enum.map_reduce([], fn [h | t], acc -> {t, [h | acc]} end)

    if zipped |> Enum.empty?() do
      Enum.reverse(acc)
    else
      zipped = zipped |> Enum.reverse()
      zip_longest_recurse(lists, [zipped | acc])
    end
  end

  @doc """
  Implementation of `Enum.unzip/1` for more-than-two-element tuples.

  Size of returned tuple is equal to size of the shortest tuple in `tuples`.

  ## Examples:
  iex> #{__MODULE__}.unzip([{1,2,3}, {4,5,6}, {7,8,9}, {10,11,12}])
  {[1, 4, 7, 10], [2, 5, 8, 11], [3, 6, 9, 12]}
  iex> #{__MODULE__}.unzip([{1,2,3}, {4,5}, {6,7,8,9}, {10,11,12}])
  {[1, 4, 6, 10], [2, 5, 7, 11]}
  """
  @spec unzip(tuples :: [tuple()]) :: tuple()
  def unzip([]), do: {}

  def unzip([h | _] = list) when is_tuple(h) do
    do_unzip(
      list |> Enum.reverse(),
      h |> tuple_size() |> repeat([])
    )
  end

  defp do_unzip([], acc) do
    acc |> List.to_tuple()
  end

  defp do_unzip([h | t], acc) when is_tuple(h) do
    acc = h |> Tuple.to_list() |> Enum.zip(acc) |> Enum.map(fn {t, r} -> [t | r] end)
    do_unzip(t, acc)
  end
end