defmodule Ollo.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ollo,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
      description: """
      A lightweight Oauth2 Provider implementation
      """
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: ["lib", "priv", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Joshua Balloch"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/joshuaballoch/ollo"}
    ]
  end
end
