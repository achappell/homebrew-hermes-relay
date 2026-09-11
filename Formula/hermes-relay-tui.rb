# typed: strict
# frozen_string_literal: true

# Homebrew formula for the Hermes Relay TUI.
class HermesRelayTui < Formula
  desc "Textual terminal UI for authenticated Hermes voice sessions"
  homepage "https://github.com/achappell/hermes-relay-tui"

  # Install from the checksummed release sdist, not a git clone.
  url "https://github.com/achappell/hermes-relay-tui/releases/download/v0.10.0/hermes_relay_tui-0.10.0.tar.gz"
  version "0.10.0"
  sha256 "85540ece55ee151691f112371b40e7c56a400348f36d963f5f6febd595437a03"
  head "https://github.com/achappell/hermes-relay-tui.git", branch: "main"

  depends_on "portaudio"
  depends_on "python@3.14"

  def install
    python = formula_opt_bin("python@3.14") / "python3.14"
    venv = libexec / "venv"

    system python, "-m", "venv", venv
    # Keep the base install small and observable. Optional voice and appliance
    # dependencies are installed later by `hermes-relay install`, where pip's
    # progress is visible to the user.
    system venv / "bin/pip", "install", "--disable-pip-version-check", "."

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

  test do
    assert_match "Hermes streaming TUI", shell_output("#{bin}/hermes-relay --help")
  end
end
