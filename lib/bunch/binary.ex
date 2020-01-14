defmodule Bunch.Binary do
  @moduledoc """
  A bunch of helpers for manipulating binaries.
  """

  use Bunch

  @doc """
  Generates a list by processing subsequent chunks of binary. Allows to leave
  an unprocessed leftover.

  Function `f` gets a non-consumed part of the binary and should return either a
  tuple with subsequent output element and the rest of the binary, or the atom `:halt`.

  ## Examples

      iex> f = fn
      iex>   <<size, content::binary-size(size), rest::binary>> -> {content, rest}
      iex>   _binary -> :halt
      iex> end
      iex> #{inspect(__MODULE__)}.unfold_while(<<2, "ab", 3, "cde", 4, "fghi">>, f)
      {~w(ab cde fghi), <<>>}
      iex> #{inspect(__MODULE__)}.unfold_while(<<2, "ab", 3, "cde", 4, "fg">>, f)
      {~w(ab cde), <<4, "fg">>}

  """
  @spec unfold_while(binary, (binary -> {a, binary} | :halt)) :: {[a], binary} when a: any
  def unfold_while(binary, f) do
    do_unfold_while(binary, f, [])
  end

  defp do_unfold_while(binary, f, acc) do
    case f.(binary) do
      {value, rest} -> do_unfold_while(rest, f, [value | acc])
      :halt -> {Enum.reverse(acc), binary}
    end
  end

  @doc """
  The version of `unfold_while/2` that accepts `:ok` and `:error` return tuples.

  Behaves as `unfold_while/2` as long as `:ok` tuples are returned. Upon `:error`
  the processing is stopped and error is returned.

  ## Examples

      iex> f = fn
      iex>   <<a, b, rest::binary>> ->
      iex>     sum = a + b
      iex>     if rem(sum, 2) == 1, do: {:ok, {sum, rest}}, else: {:error, :even_sum}
      iex>   _binary -> {:ok, :halt}
      iex> end
      iex> #{inspect(__MODULE__)}.try_unfold_while(<<1,2,3,4,5>>, f)
      {:ok, {[3, 7], <<5>>}}
      iex> #{inspect(__MODULE__)}.try_unfold_while(<<2,4,6,8>>, f)
      {:error, :even_sum}

  """
  @spec try_unfold_while(binary, (binary -> {:ok, {a, binary} | :halt} | {:error, reason})) ::
          {:ok, {[a], binary}} | {:error, reason}
        when a: any, reason: any
  def try_unfold_while(binary, f) do
    do_try_unfold_while(binary, f, [])
  end

  defp do_try_unfold_while(binary, f, acc) do
    case f.(binary) do
      {:ok, {value, rest}} -> do_try_unfold_while(rest, f, [value | acc])
      {:ok, :halt} -> {:ok, {Enum.reverse(acc), binary}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Chunks given binary into parts of given size.

  Remaining part is cut off.

  ## Examples

      iex> <<1, 2, 3, 4, 5, 6>> |> #{inspect(__MODULE__)}.chunk_every(2)
      [<<1, 2>>, <<3, 4>>, <<5, 6>>]
      iex> <<1, 2, 3, 4, 5, 6, 7>> |> #{inspect(__MODULE__)}.chunk_every(2)
      [<<1, 2>>, <<3, 4>>, <<5, 6>>]

  """
  @spec chunk_every(binary, pos_integer) :: [binary]
  def chunk_every(binary, chunk_size) do
    {result, _} = chunk_every_rem(binary, chunk_size)
    result
  end

  @doc """
  Chunks given binary into parts of given size.

  Returns list of chunks and remainder.

  ## Examples

      iex> <<1, 2, 3, 4, 5, 6>> |> #{inspect(__MODULE__)}.chunk_every_rem(2)
      {[<<1, 2>>, <<3, 4>>, <<5, 6>>], <<>>}
      iex> <<1, 2, 3, 4, 5, 6, 7>> |> #{inspect(__MODULE__)}.chunk_every_rem(2)
      {[<<1, 2>>, <<3, 4>>, <<5, 6>>], <<7>>}

  """
  @spec chunk_every_rem(binary, chunk_size :: pos_integer) :: {[binary], remainder :: binary}
  def chunk_every_rem(binary, chunk_size) do
    do_chunk_every_rem(binary, chunk_size)
  end

  defp do_chunk_every_rem(binary, chunk_size, acc \\ []) do
    case binary do
      <<chunk::binary-size(chunk_size)>> <> rest ->
        do_chunk_every_rem(rest, chunk_size, [chunk | acc])

      rest ->
        {acc |> Enum.reverse(), rest}
    end
  end

  @doc """
  Cuts off the smallest possible chunk from the end of `binary`, so that the
  size of returned binary is an integer multiple of `i`.

  ## Examples

      iex> import #{inspect(__MODULE__)}
      iex> take_int_part(<<1,2,3,4,5,6,7,8>>, 3)
      <<1,2,3,4,5,6>>
      iex> take_int_part(<<1,2,3,4,5,6,7,8>>, 4)
      <<1,2,3,4,5,6,7,8>>

  """
  @spec take_int_part(binary, pos_integer) :: binary
  def take_int_part(binary, i) do
    {b, _} = split_int_part(binary, i)
    b
  end

  @doc """
  Returns a 2-tuple, where the first element is the result of `take_int_part(binary, i)`,
  and the second is the rest of `binary`.

  ## Examples

      iex> import #{inspect(__MODULE__)}
      iex> split_int_part(<<1,2,3,4,5,6,7,8>>, 3)
      {<<1,2,3,4,5,6>>, <<7,8>>}
      iex> split_int_part(<<1,2,3,4,5,6,7,8>>, 4)
      {<<1,2,3,4,5,6,7,8>>, <<>>}

  """
  @spec split_int_part(binary, pos_integer) :: {binary, binary}
  def split_int_part(binary, i) do
    len = Bunch.Math.max_multiple_lte(i, binary |> byte_size())
    <<b::binary-size(len), r::binary>> = binary
    {b, r}
  end
end
