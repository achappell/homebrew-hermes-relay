# typed: strict
# frozen_string_literal: true

# Homebrew formula for the Hermes Relay TUI.
class HermesRelayTui < Formula
  desc "Textual terminal UI for authenticated Hermes voice sessions"
  homepage "https://github.com/achappell/hermes-relay-tui"

  # Install from the checksummed release sdist, not a git clone.
  url "https://github.com/achappell/hermes-relay-tui/releases/download/v0.8.0/hermes_relay_tui-0.8.0.tar.gz"
  version "0.8.0"
  sha256 "3a2f141a2a6bafbc28d63f5f8693a7e5c9840da14d0b2704133f67c2ec8b0eba"
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
