defmodule Bunch.Markdown do
  @moduledoc """
  A bunch of helpers for generating Markdown text
  """

  @doc """
  Indents whole block of text by one level (two spaces).

  ## Examples

      iex>#{inspect(__MODULE__)}.indent("text")
      "  text"

      iex>text = \"""
      ...>First line
      ...>Second line
      ...>Third line
      ...>\"""
      iex>#{inspect(__MODULE__)}.indent(text)
      \"""
        First line
        Second line
        Third line
      \"""
      iex>#{inspect(__MODULE__)}.indent(text, 2)
      \"""
          First line
          Second line
          Third line
      \"""
  """

  @spec indent(String.t(), non_neg_integer()) :: String.t()
  def indent(string, level \\ 1) do
    # replace each line with indented one, `\0` is a whole match
    string |> String.replace(~r/^.*$/m, indent_line("\\0", level))
  end

  @doc """
  Indents the whole block of text by one level using hard spaces (`&nbsp;`).

  ## Examples

      iex>#{inspect(__MODULE__)}.hard_indent("text")
      "&nbsp;&nbsp;text"

      iex>text = \"""
      ...>First line
      ...>Second line
      ...>Third line
      ...>\"""
      iex>#{inspect(__MODULE__)}.hard_indent(text)
      \"""
      &nbsp;&nbsp;First line
      &nbsp;&nbsp;Second line
      &nbsp;&nbsp;Third line
      \"""
      iex>#{inspect(__MODULE__)}.hard_indent(text, 2)
      \"""
      &nbsp;&nbsp;&nbsp;&nbsp;First line
      &nbsp;&nbsp;&nbsp;&nbsp;Second line
      &nbsp;&nbsp;&nbsp;&nbsp;Third line
      \"""
  """
  @spec hard_indent(String.t(), non_neg_integer()) :: String.t()
  def hard_indent(string, level \\ 1) do
    # replace each line with indented one, `\0` is a whole match
    string |> String.replace(~r/^.*$/m, indent_line("\\0", level, "&nbsp;"))
  end

  defp indent_line(string, level, character \\ " ") do
    String.duplicate(character, level * 2) <> string
  end
end
