# SPM (Session Persistence Manager)

**SPM** is a simple lua plugin for simple project management.

## ⚡️ Requirements

- Neovim >= 0.10
- `plenary`

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
		use_views = true,
		local_only = true, -- don't save views / files unless they're in the project
		use_shada = true,
		keys = {
			create = '<leader>pc',
		},

		pre_load_fn = function() end,
		post_load_fn = function() end,
	}
},
```

- It assumes the project path is the first directory passed to nvim, assumes 1 project per nvim instance.
- It sets the cwd to the project path.
- By default it saves sessions and custom config in the `$PROJECT/.nvim` directory.
- To create a project, use the `<leader>pc` keybinding.
- Saves views per file.
- Saves shada per project.
- Reopens files based on their order.
