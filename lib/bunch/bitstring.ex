defmodule Bunch.Bitstring do
  @moduledoc """
  A bunch of helpers for manipulating bitstrings.
  """

  @doc """
  Splits given bitstring into parts of given size.
  """
  @spec split(bitstring, chunk_size :: pos_integer) :: {[bitstring], remainder :: bitstring}
  def split(data, chunk_size) do
    split_recurse(data, chunk_size)
  end

  @doc """
  Same as `split/2`, but returns only list of chunks, remaining part is being
  cut off.
  """
  @spec split!(bitstring, pos_integer) :: [bitstring]
  def split!(data, chunk_size) do
    {result, _} = split(data, chunk_size)
    result
  end

  defp split_recurse(data, chunk_size, acc \\ []) do
    case data do
      <<chunk::binary-size(chunk_size)>> <> rest ->
        split_recurse(rest, chunk_size, [chunk | acc])

      rest ->
        {acc |> Enum.reverse(), rest}
    end
  end
end
