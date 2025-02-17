{
  site_name = "NixOS-pcsd";

  repo_url = "https://github.com/matt1432/nixos-pcsd";

  theme = {
    name = "material";

    font.text = "Noto Sans";

    features = [
      "content.code.copy"
      "content.code.select"
    ];

    palette = [
      # Palette toggle for automatic mode
      {
        media = "(prefers-color-scheme)";
        toggle = {
          icon = "material/brightness-auto";
          name = "Switch to light mode";
        };
      }

      # Palette toggle for light mode
      {
        media = "(prefers-color-scheme: light)";
        scheme = "default";
        toggle = {
          icon = "material/brightness-7";
          name = "Switch to dark mode";
        };
      }

      # Palette toggle for dark mode
      {
        media = "(prefers-color-scheme: dark)";
        scheme = "slate";
        primary = "deep purple";
        accent = "blue";
        toggle = {
          icon = "material/brightness-4";
          name = "Switch to light mode";
        };
      }
    ];
  };

  markdown_extensions = [
    {
      "pymdownx.highlight" = {
        anchor_linenums = true;
        line_spans = "__span";
        pygments_lang_class = true;
      };
    }

    {
      "pymdownx.escapeall" = {
        hardbreak = true;
        nbsp = true;
      };
    }

    "pymdownx.inlinehilite"
    "pymdownx.snippets"
    "pymdownx.superfences"
  ];

  extra.consent.cookies = {
    analytics = {
      name = "Google Analytics";
      checked = false;
    };

    github = {
      name = "GitHub";
      checked = false;
    };
  };
}
