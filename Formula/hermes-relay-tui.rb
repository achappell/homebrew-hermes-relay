# typed: strict
# frozen_string_literal: true

# Homebrew formula for the Hermes Relay TUI.
class HermesRelayTui < Formula
  desc "Textual terminal UI for authenticated Hermes voice sessions"
  homepage "https://github.com/achappell/hermes-relay-tui"

  # Install from the checksummed release sdist, not a git clone.
  url "https://github.com/achappell/hermes-relay-tui/releases/download/v0.7.0/hermes_relay_tui-0.7.0.tar.gz"
  sha256 "e8d9a0d6bafdf332ab66f9f47dffa29c5b71558bddfb641d449f12596b5a98f9"
  version "0.7.0"
  head "https://github.com/achappell/hermes-relay-tui.git", branch: "main"

  depends_on "portaudio"
  depends_on "python@3.14"

  def install
    python = formula_opt_bin("python@3.14") / "python3.14"
    venv = libexec / "venv"

    system python, "-m", "venv", venv
    system venv / "bin/pip", "install", "--disable-pip-version-check", "--no-cache-dir", "."

    (bin / "hermes-relay").write_env_script(
      venv / "bin/hermes-relay",
      HERMES_RELAY_TUI_VENV: venv.to_s,
    )

    # The kiosk entry point only exists in releases that ship home_display,
    # so link it when the installed distribution actually provides it.
    if (venv / "bin/hermes-relay-home").exist?
      (bin / "hermes-relay-home").write_env_script(
        venv / "bin/hermes-relay-home",
        HERMES_RELAY_TUI_VENV: venv.to_s,
      )
    end
  end

  # Homebrew rewrites Mach-O install names across the keg after the install
  # block runs. PyAV and its FFmpeg dylibs ship pre-signed, and rewriting
  # their load commands invalidates that signature, after which macOS
  # SIGKILLs any process that loads them - which killed local speech-to-text
  # with no traceback. Re-sign ad-hoc, once relocation has finished.
  def post_install
    return unless OS.mac?

    # FNM_DOTMATCH is required: the affected dylibs live in hidden
    # ".dylibs" directories, which ** skips by default.
    Dir.glob(libexec / "venv/**/*.{dylib,so}", File::FNM_DOTMATCH).each do |macho|
      next if quiet_system("codesign", "--verify", macho)

      system "codesign", "--force", "--sign", "-", macho
    end
  end

  test do
    assert_match "Hermes streaming TUI", shell_output("#{bin}/hermes-relay --help")

    # Guards the signature breakage above: both imports SIGKILL when the
    # bundled dylibs are relinked without being re-signed.
    system libexec / "venv/bin/python", "-c", "import av, faster_whisper"
  end
end
