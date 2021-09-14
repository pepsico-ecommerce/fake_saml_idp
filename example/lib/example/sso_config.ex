defmodule Example.SSOConfig do
  @moduledoc "Example of using runtime config."

  def load_config do
    config = Application.get_env(:example, FakeSamlIdp)
    accounts = config |> Keyword.get(:accounts) |> Enum.map(&add_gpid_to_account/1)

    Keyword.put(config, :accounts, accounts)
  end

  defp add_gpid_to_account(account = %{"email" => email}) do
    Map.put(account, "gpid", gpid_from_email(email))
  end

  defp gpid_from_email(email) do
    <<hash::integer-size(160)>> =
      email
      |> String.downcase()
      |> String.trim()
      |> then(&:crypto.hash(:sha, &1))

    String.pad_leading(to_string(rem(hash, 1_000_000)), 6, "0")
  end
end
