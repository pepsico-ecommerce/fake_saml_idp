defmodule IntegrationTest do
  @moduledoc """
  Since `:fake_saml_idp` doesn't do much on its own, the integration tests
  live inside the `example` application. This doesn't exercise 100% of its
  functionality, but it does ensure that the happy path works as expected.
  """

  use ExUnit.Case
  use Hound.Helpers

  hound_session()

  test "works" do
    navigate_to("http://localhost:4321")

    # click login button
    assert login_btn = find_element(:id, "login-button")
    click(login_btn)

    # select account and submit
    assert account_select = find_element(:tag, "select")
    click_select_option(account_select, "user@example.com")
    submit_element(account_select)

    # make sure assertion is displayed correctly
    assert assertion_pre = find_element(:id, "assertion")
    assert visible_text(assertion_pre) =~ "%Samly.Assertion{"
    assert assertion_attrs_pre = find_element(:id, "assertion-attrs")
    assert attrs_json = visible_text(assertion_attrs_pre)

    attrs = Jason.decode!(attrs_json)
    assert attrs["email"] == "user@example.com"
    assert attrs["firstName"] == "Standard"
    assert attrs["lastName"] == "User"
    assert attrs["userId"] == "6543210"
    assert String.match?(attrs["gpid"], ~r/^\d{6}$/)
  end

  defp click_select_option(select, option_value) do
    assert option = find_within_element(select, :css, "option[value='#{option_value}']")
    click(option)
  end
end
