defmodule MomoapiElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :momoapi_elixir,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      source_url: "https://github.com/oryono/momoapi-elixir",
      homepage_url: "https://github.com/oryono/momoapi-elixir",
      description: "MTN MoMo API client for Elixir"
    ]
  end

  defp package do
    [
      maintainers: ["Patrick Oryono"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/oryono/momoapi-elixir"},
      files: ~w(lib .formatter.exs mix.exs),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:uuid, "~> 1.1"},
      {:httpoison, "~> 1.8"},
      {:poison, "~> 3.1"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end
end
