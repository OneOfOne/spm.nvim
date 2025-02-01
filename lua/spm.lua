local pp = require('plenary.path')
local group = vim.api.nvim_create_augroup('SPM', {})

local function starts_with(s, substring)
	return (s:sub(1,#substring) == substring)
end

local function tbl_remove(tbl, val)
	for i = #tbl, 1, -1 do
		if tbl[i] == val then
			table.remove(tbl, i)
		end
	end
	return tbl
end

local SPM = {
	config = {},
	files = {}
}

local function open_file(fn)
	if vim.fn.filereadable(fn) ~= 0 then
		vim.schedule(function()
			vim.cmd('e ' .. fn)
		end)
	end
end

local function is_local_file(fn)
	if not SPM.config.local_only then
		return vim.fn.filereadable(fn) ~= 0
	end
	local dir = SPM.config.dir
	local ldir = dir:gsub('.nvim/$', '')
	return starts_with(fn, ldir) ~= nil
end

local function write_file(fn, text)
	local file = io.open(fn, 'w')
	if not file then
		return
	end
	file:write(text)
	file:close()
end

local default_config = {
	dir = '.nvim',
	set_cwd = true,
	use_views = true,
	local_only = true,
	use_shada = true,
	keys = {
		create = '<leader>pc',
	},

	pre_load_fn = function() end,
	post_load_fn = function() end,

	open_file_fn = open_file
}

local exiting = false

SPM.load = function()
	local dir = SPM.config.dir

	if vim.fn.isdirectory(dir) == 0 then
		return
	end

	if SPM.config.pre_load_fn then
		SPM.config.pre_load_fn()
	end

	if vim.fn.filereadable(dir .. 'init.lua') ~= 0 then
		vim.tbl_deep_extend('force', SPM.config, dofile(dir .. 'init.lua') or {})
	end

	local cfg = SPM.config

	vim.api.nvim_set_current_win(1000) -- focus the main window

	if cfg.use_shada then
		vim.opt.shadafile = dir .. 'shada'
		vim.cmd('silent! rshada')
	end

	if cfg.use_views then
		vim.opt.viewdir = dir .. 'views/'
		vim.opt.viewoptions = 'cursor,folds'
		vim.api.nvim_create_autocmd('BufWinEnter', {
			group = group,
			pattern = '?*',
			callback = function(args)
				if not exiting and is_local_file(args.match) then
					vim.cmd('silent! loadview')
				end
			end

		})

		vim.api.nvim_create_autocmd('BufWinLeave', {
			group = group,
			pattern = '?*',
			callback = function(args)
				if not exiting and is_local_file(args.match) then
					vim.cmd.mkview()
				end
			end
		})

	end

	vim.api.nvim_create_autocmd('BufEnter', {
		group = group,
		pattern = '?*',
		callback = function(args)
			if not exiting and is_local_file(args.match) then
				tbl_remove(SPM.files, args.match)
				table.insert(SPM.files, args.match)
			end
		end
	})

	vim.api.nvim_create_autocmd('BufDelete', {
		group = group,
		pattern = '?*',
		callback = function(args)
			if not exiting and is_local_file(args.match) then
				tbl_remove(SPM.files, args.match)
			end
		end
	})

	if vim.fn.filereadable(dir .. 'session.lua') ~= 0 then
		for _, fn in ipairs(dofile(dir .. 'session.lua')) do
			SPM.config.open_file_fn(fn)
		end
	end

	if SPM.config.post_load_fn then
		SPM.config.post_load_fn()
	end
end

SPM.save = function()
	local dir = SPM.config.dir
	if vim.fn.isdirectory(dir) == 0 then
		return
	end

	local file = io.open(dir .. 'session.lua', 'w')

	if not file then
		return
	end

	file:write('return {\n')

	local ldir = dir:gsub('.nvim/$', '')
	for _, fname in ipairs(SPM.files) do
		local name = '.' .. string.sub(fname, ldir:len())
		if vim.fn.filereadable(name) ~= 0 then
			file:write('\t"' .. name .. '",\n')
		end
	end

	file:write('}\n')
	file:close()
end

SPM.create = function()
	local dir = SPM.config.dir

	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, 'p')
		write_file(dir .. '.gitignore', 'session.lua\nshada\nviews\n')
	end

	if vim.fn.filereadable(dir .. 'init.lua') == 0 then
		write_file(dir .. 'init.lua', 'return {}\n')
	end

	SPM.save()
end

local function init_cwd()
	local dir = ''
	local argv = vim.fn.argv()
	if argv then
		for i = 1, #argv do
			if vim.fn.isdirectory(argv[i]) ~= 0 then
				dir = vim.fs.normalize(argv[i])
				break
			end
		end
	end
	if dir ~= '' then
		dir = pp:new(dir):absolute()
		vim.api.nvim_set_current_dir(dir)
	end

	return dir
end

local function init(cfg)
	vim.api.nvim_create_user_command("SPMCreate", SPM.create, { nargs = 0 })
	vim.api.nvim_create_autocmd('QuitPre', {
		pattern = '*',
		desc = '[SPM] auto save session on exit',
		group = group,
		callback = function()
			exiting = true
			SPM.save()
		end
	})

	if cfg.keys.create ~= '' then
		vim.keymap.set('n', cfg.keys.create, SPM.create, { desc = '[SPM] create / init project' })
	end

	vim.api.nvim_create_autocmd('UIEnter', {
		group = group,
		callback = function()
			vim.defer_fn(SPM.load, 250)
		end
	})

	return cfg
end

SPM.setup = function(config)
	local cfg = vim.tbl_deep_extend('force', default_config, config or {})
	local cwd = vim.fn.getcwd()

	if cfg.set_cwd then
		cwd = init_cwd()
	end

	if string.sub(cfg.dir, 1, 1) ~= '/' then
		cfg.dir = pp:new(cwd):joinpath(cfg.dir):absolute()
	end

	cfg.dir = vim.fs.normalize(cfg.dir) .. "/"

	SPM.config = init(cfg)
end
return SPM
