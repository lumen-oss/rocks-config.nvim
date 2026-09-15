<!-- markdownlint-disable -->
<br />
<div align="center">
  <a href="https://github.com/lumen-oss/lux-config.nvim">
    <img src="./rocks-header.svg" alt="lux-config.nvim">
  </a>
  <p align="center">
    <br />
    <a href="./doc/lux-config.txt"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/lumen-oss/lux-config.nvim/issues/new?assignees=&labels=bug">Report Bug</a>
    ·
    <a href="https://github.com/lumen-oss/lux-config.nvim/issues/new?assignees=&labels=enhancement">Request Feature</a>
    ·
    <a href="https://github.com/lumen-oss/lux-config.nvim/discussions/new?category=q-a">Ask Question</a>
  </p>
  <p>
    <strong>
      Allow <a href="https://github.com/lumen-oss/lux.nvim">lux.nvim</a> to help configure your plugins.
    </strong>
  </p>
  <p>🌒</p>
</div>
<!-- markdownlint-restore -->

## Installation

```
:Lux add lux-config.nvim
```

Then add a `[neovim.config]` table to your `lux.toml`:

```toml
[dependencies]
"neorg" = "7.0.0"
"sweetie.nvim" = "1.0.0"

[neovim.config]
plugins_dir = "plugins/"
auto_setup = false
```

See [`:h lux-config`](./doc/lux-config.txt) for the full reference.

## License

`lux-config.nvim` is licensed under [GPLv3](./LICENSE).
