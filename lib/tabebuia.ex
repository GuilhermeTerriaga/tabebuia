# In lib/tabebuia.ex
defmodule Tabebuia do
  @moduledoc """
  Main API for creating, extracting, and reading tar archives.
  """

  @doc """
  Create a TAR archive from a list of files and directories.
  """
  @spec create(String.t(), [String.t()]) :: :ok | {:error, any()}
  def create(archive_path, paths) when is_list(paths) do
    with {:ok, entries} <- Tabebuia.Collector.gather_files(paths) do
      archive_data = Tabebuia.Builder.build_archive(entries)

      File.write(archive_path, archive_data)
    end
  end

  def create(archive_path, path) when is_binary(path) do
    create(archive_path, [path])
  end

  @doc """
  Extract a TAR archive to the given directory.
  """
  @spec extract(String.t(), String.t()) :: {:ok, [String.t()]} | {:error, any()}
  def extract(archive_path, dest_path) do
    case File.read(archive_path) do
      {:ok, archive_data} ->
        with {:ok, entries} <- Tabebuia.Parser.parse_archive(archive_data) do
          Tabebuia.Extractor.extract_entries(entries, dest_path)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  List the contents of a TAR archive.
  """
  @spec list(String.t()) :: {:ok, [String.t()]} | {:error, any()}
  def list(archive_path) do
    case File.read(archive_path) do
      {:ok, archive_data} ->
        with {:ok, entries} <- Tabebuia.Parser.parse_archive(archive_data) do
          file_names =
            entries
            |> Enum.map(fn {header, _} ->
              Tabebuia.Header.full_name(header)
            end)

          {:ok, file_names}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
