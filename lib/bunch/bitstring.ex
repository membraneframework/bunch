defmodule Bunch.Bitstring do
  @moduledoc """
  A bunch of helpers for manipulating bitstrings.
  """

  @doc """
  Splits given bitstring into parts of given size.

  Remaining part is being cut off.
  """
  @spec split(bitstring, pos_integer) :: [bitstring]
  def split(data, chunk_size) do
    {result, _} = split_rem(data, chunk_size)
    result
  end

  @doc """
  Splits given bitstring into parts of given size.

  Returns list of chunks and remainder.
  """
  @spec split_rem(bitstring, chunk_size :: pos_integer) :: {[bitstring], remainder :: bitstring}
  def split_rem(data, chunk_size) do
    do_split_rem(data, chunk_size)
  end

  defp do_split_rem(data, chunk_size, acc \\ []) do
    case data do
      <<chunk::binary-size(chunk_size)>> <> rest ->
        do_split_rem(rest, chunk_size, [chunk | acc])

      rest ->
        {acc |> Enum.reverse(), rest}
    end
  end
end
