defmodule Tabebuia.CLITest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  setup do
    tmp_dir = Temp.mkdir!()

    # Create test files
    File.write!(Path.join(tmp_dir, "test.txt"), "CLI test")
    File.mkdir_p!(Path.join(tmp_dir, "test_dir"))
    File.write!(Path.join(tmp_dir, "test_dir/nested.txt"), "Nested")

    archive_path = Path.join(tmp_dir, "test.tar")

    on_exit(fn ->
      File.rm_rf!(tmp_dir)
    end)

    %{tmp_dir: tmp_dir, archive_path: archive_path}
  end

  test "mix tabebuia create command", %{tmp_dir: tmp_dir, archive_path: archive_path} do
    test_file = Path.join(tmp_dir, "test.txt")

    output =
      capture_io(fn ->
        Mix.Tasks.Tabebuia.run(["create", archive_path, test_file])
      end)

    assert output =~ "Creating archive"
    assert output =~ "Created"
    assert File.exists?(archive_path)
  end

  test "mix tabebuia list command", %{tmp_dir: tmp_dir, archive_path: archive_path} do
    # Create archive first
    test_file = Path.join(tmp_dir, "test.txt")
    Mix.Tasks.Tabebuia.run(["create", archive_path, test_file])

    output =
      capture_io(fn ->
        Mix.Tasks.Tabebuia.run(["list", archive_path])
      end)

    assert output =~ "Listing contents"
    assert output =~ "test.txt"
  end

  test "mix tabebuia extract command", %{tmp_dir: tmp_dir, archive_path: archive_path} do
    # Create archive first
    test_file = Path.join(tmp_dir, "test.txt")
    Mix.Tasks.Tabebuia.run(["create", archive_path, test_file])

    extract_dir = Path.join(tmp_dir, "extracted")

    output =
      capture_io(fn ->
        Mix.Tasks.Tabebuia.run(["extract", archive_path, extract_dir])
      end)

    assert output =~ "Extracting"
    assert output =~ "Extracted"
    assert File.exists?(Path.join(extract_dir, "test.txt"))
  end

  test "mix tabebuia help command" do
    output =
      capture_io(fn ->
        Mix.Tasks.Tabebuia.run([])
      end)

    assert output =~ "Usage:"
    assert output =~ "Tabebuia 💐"
  end

end
