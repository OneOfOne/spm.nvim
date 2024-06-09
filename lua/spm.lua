local pp = require('plenary.path')
local group = vim.api.nvim_create_augroup('SPM', {})

local SPM = {
	config = {},
}

local function openFile(fn)
	if vim.fn.filereadable(fn) ~= 0 then
		if SPM.config.use_neotree then
			require('neo-tree.utils').open_file({}, fn)
		else
			vim.cmd('e ' .. fn)
		end
	end
end

local function writefile(fn, text)
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
	use_neotree = true,
	use_views = true,
	use_shada = true,
	keys = {
		create = '<leader>pc',
		-- delete = '<leader>pd',
	},

	open_file_fn = openFile
}

local function echo(msg)
	-- Construct message chunks
	msg = type(msg) == 'string' and { { msg } } or msg
	table.insert(msg, 1, { '(SPM) ', 'WarningMsg' })

	-- Echo. Force redraw to ensure that it is effective (`:h echo-redraw`)
	vim.cmd([[echo '' | redraw]])
	vim.api.nvim_echo(msg, true, {})
end

SPM.load = function()
	local dir = SPM.config.dir
	if vim.fn.isdirectory(dir) == 0 then
		return
	end

	local cfg = {}
	if vim.fn.filereadable(dir .. 'init.lua') ~= 0 then
		local lcfg = dofile(dir .. 'init.lua')
		cfg = vim.tbl_extend('force', SPM.config, lcfg or {})
		-- TBD
	end

	if cfg.use_shada then
		vim.opt.shadafile = dir .. 'shada'
		vim.cmd('silent! rshada')
	end

	if cfg.use_views then
		vim.opt.viewdir = dir .. 'views/'
		vim.api.nvim_create_autocmd('BufWritePre', { group = group, command = 'mkview' })
		vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost' },
			{ group = group, command = 'silent! loadview' })
	end


	if vim.fn.filereadable(dir .. 'session.lua') ~= 0 then
		for _, fn in ipairs(dofile(dir .. 'session.lua')) do
			SPM.config.open_file_fn(fn)
		end
	end

	echo("Loaded")
end

SPM.save = function()
	local dir = SPM.config.dir

	if vim.fn.isdirectory(dir) == 0 then
		return
	end

	vim.cmd('wshada!')
	local file = io.open(dir .. 'session.lua', 'w')

	if not file then
		return
	end

	file:write('return {\n')

	local ldir = dir:gsub('.nvim/$', '')
	for _, h in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(h) then
			local bname = vim.api.nvim_buf_get_name(h)
			local name = '.' .. string.sub(bname, ldir:len())
			if vim.fn.filereadable(name) ~= 0 then
				file:write('\t"' .. name .. '",\n')
			end
		end
	end

	file:write('}\n')
	file:close()
end

SPM.create = function()
	local dir = SPM.config.dir

	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, 'p')
		writefile(dir .. '.gitignore', 'session.lua\nshada\n')
	end

	if vim.fn.filereadable(dir .. 'init.lua') == 0 then
		writefile(dir .. 'init.lua', 'return {}\n')
	end

	SPM.save()
end

SPM.delete = function()
	-- not impl
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
		vim.cmd('cd ' .. dir)
	end

	return dir
end

local function init(cfg)
	vim.api.nvim_create_autocmd('VimLeave',
		{ pattern = '*', callback = SPM.save, desc = '[SPM] auto save session on exit', group = group })

	if cfg.keys.create ~= '' then
		vim.keymap.set('n', cfg.keys.create, SPM.create, { desc = '[SPM] create / init project' })
	end

	-- if cfg.keys.delete ~= '' then
	-- 	vim.keymap.set('n', cfg.keys.delete, SPM.delete, { desc = '[SPM] delete project' })
	-- end
	return cfg
end

SPM.setup = function(config)
	_G.CreateProject = SPM.create

	local cfg = vim.tbl_deep_extend('force', default_config, config or {})
	local cwd = vim.loop.cwd()

	if cfg.set_cwd then
		cwd = init_cwd()
	end

	if string.sub(cfg.dir, 1, 1) ~= '/' then
		cfg.dir = pp:new(cwd):joinpath(cfg.dir):absolute()
	end
	cfg.dir = vim.fs.normalize(cfg.dir) .. "/"

	SPM.config = init(cfg)
	vim.defer_fn(SPM.load, 100)
	_G.SPM = SPM
end
return SPM
