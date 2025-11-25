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
    # Impure: Read files from filesystem
    with {:ok, entries} <- Tabebuia.Collector.gather_files(paths) do
      # Build archive binary
      archive_data = Tabebuia.Builder.build_archive(entries)
      
      # Write to filesystem
      File.write(archive_path, archive_data)
    end
  end

  def create(archive_path, path) when is_binary(path) do
    create(archive_path, [path])
  end

  @doc """
  Extract a TAR archive to the given directory.
  """
  def extract(archive_path, dest_path) do
    # TODO extract
  end

  @doc """
  List the contents of a TAR archive.
  """
  def list(archive_path) do
    # TODO list
  end
end
