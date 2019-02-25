defmodule Bunch do
  @moduledoc """
  A bunch of general-purpose helper and convenience functions.
  """

  alias __MODULE__.Type

  @doc """
  Brings some useful functions to the scope.
  """
  defmacro __using__(_args) do
    quote do
      import unquote(__MODULE__),
        only: [
          withl: 1,
          withl: 2,
          ~>: 2,
          ~>>: 2,
          quote_expr: 1,
          quote_expr: 2
        ]
    end
  end

  @compile {:inline, listify: 1, error_if_nil: 2}

  @doc """
  Works like `quote/2`, but doesn't require a do/end block and options are passed
  as the last argument.

  Useful when quoting a single expression.

  ## Examples

      iex> use Bunch
      iex> quote_expr(String.t())
      quote do String.t() end
      iex> quote_expr(unquote(x) + 2, unquote: false)
      quote unquote: false do unquote(x) + 2 end

  ## Nesting
  Nesting calls to `quote` disables unquoting in the inner call, while placing
  `quote_expr` in `quote` or another `quote_expr` does not:

      iex> use Bunch
      iex> quote do quote do unquote(:code) end end == quote do quote do :code end end
      false
      iex> quote do quote_expr(unquote(:code)) end == quote do quote_expr(:code) end
      true

  """
  defmacro quote_expr(code, opts \\ []) do
    {:quote, [], [opts, [do: code]]}
  end

  @doc """
  A labeled version of the `with` macro.

  Helps to determine in `else` block which `with clause` did not match.
  Therefore `else` block is always required. Due to the Elixir syntax requirements,
  all clauses have to be labeled.

  Labels also make it possible to access results of already succeeded matches
  from else clauses. That is why labels have to be known at the compile time.

  There should be at least one clause in the else block for each label that
  corresponds to a `<-` clause.

  Duplicate labels are allowed.

  ## Examples

      iex> use Bunch
      iex> list = [-1, 3, 2]
      iex> binary = <<1,2>>
      iex> withl max: i when i > 0 <- list |> Enum.max(),
      ...>       bin: <<b::binary-size(i), _::binary>> <- binary do
      ...>   {list, b}
      ...> else
      ...>   max: i -> {:error, :invalid_maximum, i}
      ...>   bin: b -> {:error, :binary_too_short, b, i}
      ...> end
      {:error, :binary_too_short, <<1,2>>, 3}

  """
  @spec withl(keyword(with_clause :: term), do: code_block :: term(), else: match_clauses :: term) ::
          term
  defmacro withl(with_clauses, do: block, else: else_clauses) do
    do_withl(with_clauses, block, else_clauses, __CALLER__)
  end

  @doc """
  Works like `withl/2`, but allows shorter syntax.

  ## Examples

      iex> use Bunch
      iex> x = 1
      iex> y = 2
      iex> withl a: true <- x > 0,
      ...>       b: false <- y |> rem(2) == 0,
      ...>       do: {x, y},
      ...>       else: (a: false -> {:error, :x}; b: true -> {:error, :y})
      {:error, :y}


  For more details and more verbose and readable syntax, check docs for `withl/2`.
  """
  @spec withl(
          keyword :: [
            {key :: atom(), with_clause :: term}
            | {:do, code_block :: term}
            | {:else, match_clauses :: term}
          ]
        ) :: term
  defmacro withl(keyword) do
    {{:else, else_clauses}, keyword} = keyword |> List.pop_at(-1)
    {{:do, block}, keyword} = keyword |> List.pop_at(-1)
    with_clauses = keyword
    do_withl(with_clauses, block, else_clauses, __CALLER__)
  end

  defp do_withl(with_clauses, block, else_clauses, caller) do
    else_clauses =
      else_clauses
      |> Enum.map(fn {:->, meta, [[[{label, left}]], right]} ->
        {label, {:->, meta, [[left], right]}}
      end)
      |> Enum.group_by(fn {k, _v} -> k end, fn {_k, v} -> v end)

    with_clauses
    |> Enum.reverse()
    |> Enum.reduce(block, fn
      {label, {:<-, meta, _args} = clause}, acc ->
        label_else_clauses =
          else_clauses[label] ||
            "Label `#{inspect(label)}` not present in withl else clauses"
            |> raise_compile_error(caller, meta)

        args = [clause, [do: acc] ++ [else: label_else_clauses]]

        quote do
          with unquote_splicing(args)
        end

      {_label, clause}, acc ->
        quote do
          unquote(clause)
          unquote(acc)
        end
    end)
  end

  @doc """
  Embeds the argument in a one-element list if it is not a list itself. Otherwise
  works as identity.

  Works similarly to `List.wrap/1`, but treats `nil` as any non-list value,
  instead of returning empty list in this case.

  ## Examples

      iex> #{inspect(__MODULE__)}.listify(:a)
      [:a]
      iex> #{inspect(__MODULE__)}.listify([:a, :b, :c])
      [:a, :b, :c]
      iex> #{inspect(__MODULE__)}.listify(nil)
      [nil]

  """
  @spec listify(list) :: list when list: list
  @spec listify(a) :: [a] when a: any
  def listify(list) when is_list(list) do
    list
  end

  def listify(non_list) do
    [non_list]
  end

  @doc """
  Returns error tuple if given value is nil and ok tuple otherwise.
  """
  @spec error_if_nil(value, reason) :: Type.try_t(value)
        when value: any(), reason: any()
  def error_if_nil(nil, reason), do: {:error, reason}
  def error_if_nil(v, _), do: {:ok, v}

  @doc """
  Returns given stateful try value along with its status.
  """
  @spec stateful_try_with_status(result) :: {status, result}
        when status: Type.try_t(),
             result:
               Type.stateful_try_t(state :: any) | Type.stateful_try_t(value :: any, state :: any)
  def stateful_try_with_status({:ok, _state} = res), do: {:ok, res}
  def stateful_try_with_status({{:ok, _res}, _state} = res), do: {:ok, res}
  def stateful_try_with_status({{:error, reason}, _state} = res), do: {{:error, reason}, res}

  @doc """
  Helper for writing pipeline-like syntax. Maps given value using match clauses
  or lambda-like syntax.

  ## Examples

      iex> use #{inspect(__MODULE__)}
      iex> {:ok, 10} ~> ({:ok, x} -> x)
      10
      iex> 5 ~> &1 + 2
      7

  Lambda-like expressions are not converted to lambdas under the hood, but
  result of `expr` is injected to `&1` at the compile time.

  Useful especially when dealing with a pipeline of operations (made up e.g.
  with pipe (`|>`) operator) some of which are hard to express in such form:

      iex> use #{inspect(__MODULE__)}
      iex> ["Joe", "truck", "jacket"]
      ...> |> Enum.map(&String.downcase/1)
      ...> |> Enum.filter(& &1 |> String.starts_with?("j"))
      ...> ~> ["Words:" | &1]
      ...> |> Enum.join("\\n")
      "Words:
      joe
      jacket"

  """
  # Case when the mapper is a list of match clauses
  defmacro expr ~> ([{:->, _, _} | _] = mapper) do
    quote do
      case unquote(expr) do
        unquote(mapper)
      end
    end
  end

  # Case when the mapper is a piece of lambda-like code
  defmacro expr ~> mapper do
    mapped =
      mapper
      |> Macro.prewalk(fn
        {:&, _meta, [1]} ->
          quote do: expr_result

        {:&, _meta, [i]} = node when is_integer(i) ->
          node

        {:&, meta, _} ->
          """
          The `&` (capture) operator is not allowed in lambda-like version of \
          `#{inspect(__MODULE__)}.~>/2`. Use `&1` alone instead.
          """
          |> raise_compile_error(__CALLER__, meta)

        other ->
          other
      end)

    quote do
      expr_result = unquote(expr)
      unquote(mapped)
    end
  end

  @doc """
  Works similar to `~>/2`, but accepts only `->` clauses and appends default
  identity clause at the end.

  ## Examples

      iex> use #{inspect(__MODULE__)}
      iex> {:ok, 10} ~>> ({:ok, x} -> {:ok, x+1})
      {:ok, 11}
      iex> :error ~>> ({:ok, x} -> {:ok, x+1})
      :error

  """
  defmacro expr ~>> mapper_clauses do
    default =
      quote do
        default_result -> default_result
      end

    quote do
      case unquote(expr) do
        unquote(mapper_clauses ++ default)
      end
    end
  end

  defp raise_compile_error(reason, caller, meta) do
    raise CompileError,
      file: caller.file,
      line: meta |> Keyword.get(:line, caller.line),
      description: reason
  end
end
