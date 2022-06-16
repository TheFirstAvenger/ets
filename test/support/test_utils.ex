defmodule ETS.TestUtils do
  @moduledoc """
  Helper functions for testing.
  """

  @doc """
  Returns the pid of a local process which is guaranteed to be dead.
  """
  def dead_pid do
    pid = spawn(fn -> :ok end)
    wait_until_dead(pid)
  end

  def otp25? do
    {version, ""} = :erlang.system_info(:otp_release) |> to_string() |> Integer.parse()
    version >= 25
  end

  defp wait_until_dead(pid) do
    if Process.alive?(pid) do
      wait_until_dead(pid)
    else
      pid
    end
  end
end
