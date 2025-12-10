defmodule Tabebuia.IntegrationTest do
  # Not async because of file system operations
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  alias Tabebuia

  setup do
    # Create a temporary directory for each test
    tmp_dir = Temp.mkdir!()

    # Create some test files
    File.write!(Path.join(tmp_dir, "file1.txt"), "Content 1")
    File.write!(Path.join(tmp_dir, "file2.txt"), "Content 2")
    File.mkdir_p!(Path.join(tmp_dir, "subdir"))
    File.write!(Path.join(tmp_dir, "subdir/file3.txt"), "Content 3")

    archive_path = Path.join(tmp_dir, "test.tar")

    on_exit(fn ->
      # Clean up
      File.rm_rf!(tmp_dir)
    end)

    %{tmp_dir: tmp_dir, archive_path: archive_path}
  end

  describe "create/2" do
    test "creates a valid tar archive", %{tmp_dir: tmp_dir, archive_path: archive_path} do
      files = [
        Path.join(tmp_dir, "file1.txt"),
        Path.join(tmp_dir, "file2.txt"),
        Path.join(tmp_dir, "subdir")
      ]

      assert :ok = Tabebuia.create(archive_path, files)
      assert File.exists?(archive_path)

      # Archive should not be empty
      assert File.stat!(archive_path).size > 1024
    end

    test "returns error for non-existent file", %{archive_path: archive_path} do
      assert {:error, _reason} = Tabebuia.create(archive_path, ["nonexistent.txt"])
    end
  end

  describe "list/1" do
    test "lists files in archive", %{tmp_dir: tmp_dir, archive_path: archive_path} do
      # Create archive first
      files = [Path.join(tmp_dir, "file1.txt")]
      :ok = Tabebuia.create(archive_path, files)

      assert {:ok, file_list} = Tabebuia.list(archive_path)
      assert length(file_list) >= 1
      assert "file1.txt" in file_list
    end

    test "returns error for non-existent archive" do
      assert {:error, _reason} = Tabebuia.list("nonexistent.tar")
    end
  end

  describe "extract/2" do
    test "extracts archive to directory", %{tmp_dir: tmp_dir, archive_path: archive_path} do
      # Create archive with multiple files
      files = [
        Path.join(tmp_dir, "file1.txt"),
        Path.join(tmp_dir, "subdir")
      ]

      :ok = Tabebuia.create(archive_path, files)

      # Extract to new directory
      extract_dir = Path.join(tmp_dir, "extracted")
      assert {:ok, extracted_files} = Tabebuia.extract(archive_path, extract_dir)

      # Verify extracted files exist
      assert File.exists?(Path.join(extract_dir, "file1.txt"))
      assert File.exists?(Path.join(extract_dir, "subdir/"))

      # Verify content
      assert File.read!(Path.join(extract_dir, "file1.txt")) == "Content 1"
    end

    test "creates destination directory if it doesn't exist", %{
      tmp_dir: tmp_dir,
      archive_path: archive_path
    } do
      # Create simple archive
      file_path = Path.join(tmp_dir, "file1.txt")
      :ok = Tabebuia.create(archive_path, [file_path])

      # Extract to non-existent directory
      extract_dir = Path.join(tmp_dir, "new_dir")
      assert {:ok, _} = Tabebuia.extract(archive_path, extract_dir)
      assert File.exists?(Path.join(extract_dir, "file1.txt"))
    end
  end

  describe "round-trip: create extract" do
    test "preserves file content", %{tmp_dir: tmp_dir, archive_path: archive_path} do
      original_content = "Hello, Tabebuia! " <> String.duplicate("🎉", 10)
      file_path = Path.join(tmp_dir, "test.txt")
      File.write!(file_path, original_content)

      # Create archive
      :ok = Tabebuia.create(archive_path, [file_path])

      # Extract
      extract_dir = Path.join(tmp_dir, "extracted")
      {:ok, _} = Tabebuia.extract(archive_path, extract_dir)

      # Compare content
      extracted_content = File.read!(Path.join(extract_dir, "test.txt"))
      assert extracted_content == original_content
    end
  end
end
