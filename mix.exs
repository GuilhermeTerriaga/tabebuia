defmodule Tabebuia.MixProject do
  use Mix.Project

  def project do
    [
      app: :tabebuia,
      version: "0.1.0",
      elixir: "~> 1.18",
      description: "An elixir implementation of tar 💐",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end
  # Run "mix help deps" to learn about dependencies.
  defp package do
    [
      licenses: ["MIT"],
      description: "An elixir implementation of tar 💐",
      links: %{"Github"=>"https://github.com/GuilhermeTerriaga/tabebuia"},
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

end
