defmodule Bunch.Sref do
  @moduledoc """
  A bunch of stuff for shortly-inspectable references.
  """
  @enforce_keys [:ref, :hash]
  defstruct @enforce_keys

  @type t :: %__MODULE__{ref: reference, hash: String.t()}

  @doc """
  Creates a shortly-inspectable reference.

      iex> IEx.Helpers.ref(0, 1, 2, 3) |> #{inspect(__MODULE__)}.new() |> inspect()
      "#6f1ef15f"
      iex> <<"#", hash::binary-size(8)>> = #{inspect(__MODULE__)}.new() |> inspect()
      iex> Base.decode16(hash, case: :lower) |> elem(0)
      :ok

  """
  @spec new(reference) :: t
  def new(ref \\ make_ref()) do
    '#Ref' ++ ref_list = :erlang.ref_to_list(ref)
    <<bin_hash_part::binary-size(4), _::binary>> = :crypto.hash(:sha, ref_list)
    hash = "#" <> Base.encode16(bin_hash_part, case: :lower, padding: false)
    %__MODULE__{ref: ref, hash: hash}
  end
end

defimpl Inspect, for: Bunch.Sref do
  @impl true
  def inspect(%Bunch.Sref{hash: hash}, _opts), do: hash
end
