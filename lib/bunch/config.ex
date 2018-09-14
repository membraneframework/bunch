defmodule Bunch.Config do
  @moduledoc """
  A bunch of helpers for parsing and validating configurations.
  """

  alias Bunch.Type
  use Bunch

  @doc """
  Parses `config` according to `fields_specs`.

  `fields_specs` consist of constraints on each field. Supported constraints are:
    * validate - function determining if field's value is correct
    * in - enumerable containing all valid values
    * default - value returned if a field is not found in `config`
    * require_if - function determining if a field is required basing on previous
      fields' values

  ## Examples

      iex> #{inspect(__MODULE__)}.parse([a: 1, b: 2], a: [validate: & &1 > 0], b: [in: -2..2])
      {:ok, %{a: 1, b: 2}}
      iex> #{inspect(__MODULE__)}.parse([a: 1, b: 4], a: [validate: & &1 > 0], b: [in: -2..2])
      {:error, {:config_field, {:invalid_value, [key: :b, value: 4, reason: {:not_in, -2..2}]}}}
      iex> #{inspect(__MODULE__)}.parse(
      ...> [a: 1, b: 2],
      ...> a: [validate: & &1 > 0],
      ...> b: [in: -2..2],
      ...> c: [default: 5]
      ...> )
      {:ok, %{a: 1, b: 2, c: 5}}
      iex> #{inspect(__MODULE__)}.parse(
      ...> [a: 1, b: 2],
      ...> a: [validate: & &1 > 0],
      ...> b: [in: -2..2],
      ...> c: [require_if: & &1.a == &1.b]
      ...> )
      {:ok, %{a: 1, b: 2}}
      iex> #{inspect(__MODULE__)}.parse(
      ...> [a: 1, b: 1],
      ...> a: [validate: & &1 > 0],
      ...> b: [in: -2..2],
      ...> c: [require_if: & &1.a == &1.b]
      ...> )
      {:error, {:config_field, {:key_not_found, :c}}}

  """
  @spec parse(
          config :: Keyword.t(v),
          fields_specs ::
            Keyword.t(
              validate:
                (v | any -> Type.try_t() | boolean)
                | (v | any, config_map -> Type.try_t() | boolean),
              in: list(v),
              default: v,
              require_if: (config_map -> boolean)
            )
        ) :: Type.try_t(config_map)
        when config_map: %{atom => v}, v: any
  def parse(config, fields_specs) do
    fields_specs = fields_specs |> Bunch.TupleList.map_values(&Map.new/1)

    withl kw: true <- config |> Keyword.keyword?(),
          dup: [] <- config |> Keyword.keys() |> Bunch.Enum.duplicates(),
          do: config = config |> Map.new(),
          fields:
            {:ok, {config, remaining}} when remaining == %{} <- parse_fields(config, fields_specs) do
      {:ok, config}
    else
      kw: false ->
        {:error, {:config_not_keyword, config}}

      dup: duplicates ->
        {:error, {:config_duplicates, duplicates}}

      fields: {{:error, reason}, _config} ->
        {:error, {:config_field, reason}}

      fields: {:ok, {_config, remainig}} ->
        {:error, {:config_invalid_keys, remainig |> Map.keys()}}
    end
  end

  defp parse_fields(config, fields_specs) do
    fields_specs
    |> Bunch.Enum.try_reduce({%{}, config}, fn {key, spec}, {acc, remaining} ->
      case parse_field(key, spec, remaining |> Map.fetch(key), acc) do
        {:ok, {key, value}} -> {:ok, {acc |> Map.put(key, value), remaining |> Map.delete(key)}}
        :ok -> {:ok, {acc, remaining}}
        {:error, reason} -> {{:error, reason}, config}
      end
    end)
  end

  defp parse_field(key, %{require_if: require_if} = spec, value, config) do
    spec = spec |> Map.delete(:require_if)

    cond do
      require_if.(config) ->
        parse_field(key, spec |> Map.delete(:default), value, config)

      Map.has_key?(spec, :default) ->
        parse_field(key, spec, value, config)

      true ->
        :ok
    end
  end

  defp parse_field(key, %{default: default}, :error, _config) do
    {:ok, {key, default}}
  end

  defp parse_field(key, _spec, :error, _config) do
    {:error, {:key_not_found, key}}
  end

  defp parse_field(key, spec, {:ok, value}, config) do
    validate = spec |> Map.get(:validate, fn _ -> :ok end)
    in_enum = spec |> Map.get(:in, [value])

    withl fun:
            res when res in [:ok, true] <-
              (case Function.info(validate)[:arity] do
                 1 -> validate.(value)
                 2 -> validate.(value, config)
               end),
          enum: true <- value in in_enum do
      {:ok, {key, value}}
    else
      fun: false ->
        {:error, {:invalid_value, key: key, value: value}}

      fun: {:error, reason} ->
        {:error, {:invalid_value, key: key, value: value, reason: reason}}

      enum: false ->
        {:error, {:invalid_value, key: key, value: value, reason: {:not_in, in_enum}}}
    end
  end
end
