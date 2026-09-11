# ./lib/home/nixvim.nix
{ config
, pkgs
, ...
}: {

  programs.nixvim = {
    enable = true;
    colorschemes.nord = {
      enable = true;
      settings = {
        disable_background = true;
      };
    };
    defaultEditor = true;
    globals.mapleader = " ";

    keymaps = [
      {
        action = "<cmd>w<cr>";
        key = "<leader>w";
        options.noremap = true;
      }
    ];

    nixpkgs.pkgs = pkgs;

    opts = {
      #+----- folding ----------------------------
      foldenable = true;
      foldlevel = 99;
      foldmethod = "indent";

      #+----- general ----------------------------
      clipboard = "unnamedplus";
      completeopt = "menuone,noselect";
      conceallevel = 1;
      mouse = "a";
      splitbelow = true;
      splitright = true;
      termguicolors = true;
      timeoutlen = 500;
      updatetime = 300;

      #+----- linenumbers ------------------------
      cursorline = true;
      number = true;
      relativenumber = true;
      scrolloff = 8;
      sidescrolloff = 5;
      signcolumn = "yes";
      wrap = false;

      #+----- search -----------------------------
      hlsearch = true;
      ignorecase = true;
      incsearch = true;
      smartcase = true;

      #+----- swap -------------------------------
      backup = false;
      swapfile = false;
      undofile = true;
      writebackup = false;

      #+----- tab settings -----------------------
      autoindent = true;
      expandtab = true;
      tabstop = 2;
      shiftround = true;
      shiftwidth = 2;
      smartindent = true;
      softtabstop = 2;

      #+----- text -------------------------------
      list = true;
      listchars = {
        extends = "›";
        precedes = "‹";
        tab = "→ ";
        trail = "°";
      };
    };

    plugins = {

      blink-cmp = {
        enable = true;
        setupLspCapabilities = true;
        settings = {
          keymap = {
            preset = "none";
            "<C-j>" = [
              "select_next"
              "fallback"
            ];
            "<C-k>" = [
              "select_prev"
              "fallback"
            ];
            "<Up>" = [
              "scroll_documentation_up"
              "fallback"
            ];
            "<Down>" = [
              "scroll_documentation_down"
              "fallback"
            ];
            "<CR>" = [
              "accept"
              "fallback"
            ];
            "<C-y>" = [
              "select_and_accept"
              "fallback"
            ];
          };
        };
      };

      gitsigns = {
        enable = true;
        settings = {
          attach_to_untracked = true;
          current_line_blame = true;
          current_line_blame_opts = {
            delay = 0;
            virt_text_pos = "eol";
          };
        };
      };

      "indent-blankline" = {
        enable = true;
        settings = {
          indent = { char = "▏"; tab_char = "▏"; };
          scope = {
            enabled = true;
            show_start = true;
            show_end = false;
          };
        };
      };

      lazygit = {
        enable = true;
        settings = {
          floating_window_winblend = 0;
          floating_window_scaling_factor = 0.9;
        };
      };

      lualine = {
        enable = true;
        settings = {
          options = {
            theme = "nord";
            icons_enabled = true;
            section_separators = { left = ""; right = ""; };
            component_separators = { left = ""; right = ""; };
          };
        };
      };

      lsp = {
        enable = true;
        servers = {
          bashls = {
            enable = true;
            filetypes = [
              "sh"
              "bash"
              "zsh"
            ];
          };
          clangd = {
            enable = true;
            cmd = [
              "clangd"
              "--background-index"
            ];
            filetypes = [
              "c"
              "cpp"
            ];
            rootMarkers = [
              "compile_commands.json"
              "compile_flags.txt"
            ];
          };
          cssls.enable = true;
          docker_compose_language_service.enable = true; # Docker Compose language server
          html.enable = true;
          jsonls.enable = true;
          lua_ls.enable = true;
          nixd.enable = true;
          rust_analyzer = {
            enable = true;
            installCargo = true;
            installRustc = true;
          };
          taplo.enable = true; # TOML language server
          yamlls = {
            # YAML language server
            enable = true;
            settings.yaml.schemas = {
              # GitHub Actions workflow schema
              "https://json.schemastore.org/github-workflow.json" = ".github/workflows/*.{yml,yaml}";
            };
          };
        };
      };

      obsidian = {
        enable = true;
        settings = {
          legacy_commands = false;
          workspaces = [
            {
              name = "Obsidian";
              path = "~/Documents/Obsidian";
            }
          ];
        };
      };

      telescope = {
        enable = true;
        extensions."fzf-native" = {
          enable = true;
          settings = {
            fuzzy = true;
            override_file_sorter = true;
            override_generic_sorter = true;
            case_mode = "smart_case";
          };
        };
      };

      treesitter = {
        enable = true;
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          bash
          c
          comment
          css
          dockerfile
          html
          json
          lua
          make
          markdown
          regex
          rust
          toml
          vim
          vimdoc
          xml
          yaml
        ];
        nixGrammars = true;
        nixvimInjections = true;
        settings = {
          defaults = {
            layout_config = { prompt_position = "top"; };
            sorting_strategy = "ascending";
          };
          highlight.enable = true;
          indent.enable = true;
          pickers.find_files.hidden = true;
        };
      };

      web-devicons.enable = true;

    };

    viAlias = true;
    vimAlias = true;

  };

}
