# Generated from `brew tap`, `brew leaves` and `brew list --cask` on G1459.
# Prune freely; once the list is trimmed, set cleanup = "zap" so anything not
# listed here gets uninstalled on switch.
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };

    taps = [
      "guilospanck/tap"
      "raine/consult-llm"
      "raine/workmux"
      "shodan-public/shodan"
      "stripe/stripe-cli"
    ];

    brews = [
      "bash"
      "bat"
      "btop"
      "cmake"
      "colima"
      "raine/consult-llm/consult-llm"
      "coreutils"
      "curl"
      "dive"
      "docker"
      "docker-buildx"
      "docker-compose"
      "eza"
      "fd"
      "ffmpeg-full"
      "fzf"
      "gh"
      "git"
      "gitleaks"
      "glow"
      "go"
      "jq"
      "just"
      "lima"
      "maven"
      "guilospanck/tap/modelgen"
      "neovim"
      "nmap"
      "node"
      "nvm"
      "odin"
      "opencode"
      "opentofu"
      "pkgconf"
      "pngpaste"
      "pngquant"
      "poppler"
      "pre-commit"
      "python@3.12"
      "ripgrep"
      "shellcheck"
      "starship"
      "tectonic"
      "tldr"
      "tmux"
      "tree"
      "tree-sitter"
      "trivy"
      "wget"
      "raine/workmux/workmux"
      "xcodegen"
      "yarn"
      "z"
      "zig"
      "zsh"
      "zsh-vi-mode"
    ];

    casks = [
      "guilospanck/tap/ai-usage-bar"
      "background-music"
      "clipy"
      "dbeaver-community"
      "gcloud-cli"
      "ghostty"
      "keycastr"
      "ngrok"
      "notion"
      "obs"
      "postman"
      "secretive"
      "shodan-public/shodan/shodan-terminal"
    ];
  };
}
