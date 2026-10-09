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
      # Hosted on GitLab; a bare name makes brew clone from GitHub, where it 404s.
      {
        name = "shodan-public/shodan";
        clone_target = "https://gitlab.com/shodan-public/homebrew-shodan";
      }
      "stripe/stripe-cli"
    ];

    brews = [
      "air"
      "awscli"
      "bash"
      "bat"
      "binaryen"
      "btop"
      "bun"
      "cargo-hack"
      "cargo-public-api"
      "cargo-watch"
      "cmake"
      "colima"
      "raine/consult-llm/consult-llm"
      "container"
      "coreutils"
      "curl"
      "delve"
      "dive"
      "docker"
      "docker-buildx"
      "docker-compose"
      "docker-credential-helper"
      "eza"
      "fd"
      "ffmpeg-full"
      "fzf"
      "gh"
      "git"
      "git-filter-repo"
      "gitleaks"
      "glow"
      "go"
      "golangci-lint"
      "gopls"
      "hugo"
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
      "pnpm"
      "poetry"
      "poppler"
      "pre-commit"
      "python@3.12"
      "ripgrep"
      "shellcheck"
      "shodan"
      "starship"
      "staticcheck"
      "stripe/stripe-cli/stripe"
      "tectonic"
      "tldr"
      "tmux"
      "tree"
      "tree-sitter"
      "tree-sitter-cli"
      "trivy"
      "trunk"
      "tygo"
      "typos-cli"
      "uv"
      "wasm-bindgen"
      "wasm-pack"
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
      "codex"
      "dbeaver-community"
      "font-fira-code-nerd-font" # ghostty font-family
      "ghostty"
      "keycastr"
      "notion"
      "raycast"
      "rectangle"
      "secretive"
      "shodan-public/shodan/shodan-terminal"
      "visual-studio-code"
      "zen"
    ];
  };
}
