defmodule Bunch.Macro do
  @moduledoc """
  A bunch of helpers for implementing macros.
  """

  @doc """
  Imitates `import` functionality by finding and replacing bare function
  calls (like `foo()`) in AST with fully-qualified call (like `Some.Module.foo()`)

  Receives AST fragment as first parameter and
  list of pairs {Some.Module, :foo} as second
  """
  @spec inject_calls(Macro.t(), [{module(), atom()}]) :: Macro.t()
  def inject_calls(ast, functions)
      when is_list(functions) do
    Macro.prewalk(ast, fn ast_node ->
      functions |> Enum.reduce(ast_node, &replace_call(&2, &1))
    end)
  end

  @doc """
  Imitates `import` functionality by finding and replacing bare function
  calls (like `foo()`) in AST with fully-qualified call (like `Some.Module.foo()`)

  Receives AST fragment as first parameter and
  a pair {Some.Module, :foo} as second
  """
  @spec inject_call(Macro.t(), {module(), atom()}) :: Macro.t()
  def inject_call(ast, {module, fun_name})
      when is_atom(module) and is_atom(fun_name) do
    Macro.prewalk(ast, fn ast_node ->
      replace_call(ast_node, {module, fun_name})
    end)
  end

  defp replace_call(ast_node, {module, fun_name})
       when is_atom(module) and is_atom(fun_name) do
    case ast_node do
      {^fun_name, _, args} ->
        quote do
          apply(unquote(module), unquote(fun_name), unquote(args))
        end

      other_node ->
        other_node
    end
  end
end
