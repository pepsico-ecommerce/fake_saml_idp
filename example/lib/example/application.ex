defmodule Example.Application do
  @moduledoc false

  use Application

  require Logger

  @telemetry_events [
    # [:cowboy, :request, :start],
    # [:cowboy, :request, :stop],
    [:cowboy, :request, :exception]
    # [:cowboy, :request, :early_error]
  ]

  @impl true
  def start(_type, _args) do
    for event <- @telemetry_events do
      :ok =
        :telemetry.attach("example-app-#{inspect(event)}", event, &__MODULE__.handle_event/4, nil)
    end

    children = [
      {Plug.Cowboy, scheme: :http, plug: Example.Router, port: 4321},
      {Samly.Provider, []}
    ]

    opts = [strategy: :one_for_one, name: __MODULE__.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def handle_event(
        _event,
        _params,
        _meta = %{reason: {{reason, _trace}, _ctx}, req: req},
        _config
      ) do
    Logger.error("#{req.method} #{req.path}\n#{format_reason(reason)}")
  end

  defp format_reason(%{message: message}), do: message
  defp format_reason(reason), do: inspect(reason)
end
