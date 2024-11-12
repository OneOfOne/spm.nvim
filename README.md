# SPM (Session Persistence Manager)

**SPM** is a simple lua plugin for simple project management.

## ⚡️ Requirements

- Neovim >= 0.10
- `plenary`
- `neo-tree` unless use_neotree is set to false in opts.

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- Lua
	{
		'OneOfOne/spm.nvim',
		config = true,
		lazy = false,
		-- default settings
		opts = {
			dir = '.nvim',
			set_cwd = true,
			use_neotree = true,
			use_views = true,
			use_shada = true,
			keys = {
				create = '<leader>pc',
				delete = '<leader>pd',
			},

			pre_load_fn = function() end,
			post_load_fn = function() end,
		}
	},
}
```
- It assumes the project path is the first directory passed to nvim, assumes 1 project per nvim instance.
- It sets the cwd to the project path.
- By default it saves sessions and custom config in the `$PROJECT/.nvim` directory.
- To create a project, use the `<leader>pc` keybinding.
- To delete a project, use the `<leader>pd` keybinding.
