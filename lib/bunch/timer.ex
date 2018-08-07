defmodule Bunch.Timer do
  @moduledoc """
  Useful helpers for sending messages at the specified time
  """

  def send_at(time, pid \\ self(), msg),
    do: Process.send_after(pid, msg, time - System.system_time(:milliseconds))
end
