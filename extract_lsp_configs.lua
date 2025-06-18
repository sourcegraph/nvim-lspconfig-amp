#!/usr/bin/env lua

-- Extract LSP configurations from nvim-lspconfig
-- This script reads all LSP configuration files and extracts useful data for external tools

local json = require('dkjson')
local lfs = require('lfs')

-- Function to safely execute a lua file and return its result
local function load_config(filepath)
    local status, config = pcall(dofile, filepath)
    if not status then
        print("Error loading " .. filepath .. ": " .. config)
        return nil
    end
    return config
end

-- Function to get all lua files in lsp directory
local function get_lsp_files()
    local files = {}
    local lsp_dir = "./lua/lspconfig/configs"
    
    for file in lfs.dir(lsp_dir) do
        if file:match("%.lua$") then
            local filepath = lsp_dir .. "/" .. file
            local attr = lfs.attributes(filepath)
            if attr and attr.mode == "file" then
                table.insert(files, file)
            end
        end
    end
    
    table.sort(files)
    return files
end

-- Function to safely serialize values (avoiding functions)
local function safe_serialize(value)
    if type(value) == "function" then
        return "[FUNCTION]"
    elseif type(value) == "table" then
        local result = {}
        for k, v in pairs(value) do
            result[k] = safe_serialize(v)
        end
        return result
    else
        return value
    end
end

-- Function to extract useful data from config
local function extract_config_data(name, config)
    if not config then
        return nil
    end
    
    -- Handle new structure with default_config
    local default_config = config.default_config or config
    local docs = config.docs or {}
    
    local extracted = {
        name = name,
        cmd = safe_serialize(default_config.cmd),
        filetypes = safe_serialize(default_config.filetypes),
        root_markers = safe_serialize(default_config.root_markers),
        settings = safe_serialize(default_config.settings),
        init_options = safe_serialize(default_config.init_options),
        capabilities = safe_serialize(default_config.capabilities),
    }
    
    -- Add additional useful fields if they exist
    if default_config.single_file_support ~= nil then
        extracted.single_file_support = default_config.single_file_support
    end
    
    if default_config.handlers then
        extracted.has_custom_handlers = true
    end
    
    if default_config.on_attach then
        extracted.has_on_attach = true
    end
    
    if default_config.before_init then
        extracted.has_before_init = true
    end
    
    if default_config.on_init then
        extracted.has_on_init = true
    end
    
    if default_config.root_dir then
        extracted.has_custom_root_dir = true
    end
    
    -- Add documentation from docs section
    if docs.description then
        extracted.documentation = docs.description
    end
    
    return extracted
end

-- Function to read file content for documentation
local function read_file_docs(filepath)
    local file = io.open(filepath, "r")
    if not file then
        return nil
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Extract documentation from the beginning of the file
    local docs = {}
    for line in content:gmatch("[^\r\n]+") do
        if line:match("^%-%-%-") then
            -- Remove comment markers and add to docs
            local doc_line = line:gsub("^%-%-%-?%s?", "")
            table.insert(docs, doc_line)
        else
            -- Stop when we hit non-comment lines
            if not line:match("^%s*$") then
                break
            end
        end
    end
    
    return table.concat(docs, "\n")
end

-- Main extraction function
local function extract_all_configs()
    local configs = {}
    local files = get_lsp_files()
    
    print("Found " .. #files .. " LSP configuration files")
    
    for _, filename in ipairs(files) do
        local name = filename:gsub("%.lua$", "")
        local filepath = "./lua/lspconfig/configs/" .. filename
        
        print("Processing: " .. name)
        
        local config = load_config(filepath)
        local extracted = extract_config_data(name, config)
        
        if extracted then
            -- Add file-level documentation if no docs section documentation exists
            if not extracted.documentation then
                extracted.documentation = read_file_docs(filepath)
            end
            configs[name] = extracted
        else
            print("Warning: Failed to extract config for " .. name)
        end
    end
    
    return configs
end

-- Function to test a specific config (lua_ls)
local function test_lua_config()
    print("\n=== Testing lua_ls configuration ===")
    local config = load_config("./lua/lspconfig/configs/lua_ls.lua")
    
    if config then
        print("Successfully loaded lua_ls config:")
        print("  Command: " .. (config.cmd and table.concat(config.cmd, " ") or "nil"))
        print("  Filetypes: " .. (config.filetypes and table.concat(config.filetypes, ", ") or "nil"))
        print("  Root markers: " .. (config.root_markers and table.concat(config.root_markers, ", ") or "nil"))
        
        local extracted = extract_config_data("lua_ls", config)
        print("  Extracted data keys: " .. table.concat(vim.tbl_keys(extracted), ", "))
        
        return extracted
    else
        print("Failed to load lua_ls config")
        return nil
    end
end

-- Create lspconfig.util mock
local lspconfig_util = {
    root_pattern = function(...)
        local patterns = {...}
        return function(fname)
            return "/mock/root"
        end
    end,
    find_git_ancestor = function(fname)
        return "/mock/git/root"
    end,
    find_package_json_ancestor = function(fname)
        return "/mock/package/root"
    end,
    find_node_modules_ancestor = function(fname)
        return "/mock/node_modules/root"
    end,
    path = {
        join = function(...)
            local parts = {...}
            return table.concat(parts, "/")
        end,
        exists = function(path)
            return true
        end,
        is_dir = function(path)
            return true
        end,
        dirname = function(path)
            return path:match("(.*)/") or "."
        end
    },
    insert_package_json = function(pattern, pkg_json, section)
        -- Mock function
        return {}
    end
}

-- Mock lspconfig modules
package.preload['lspconfig.util'] = function()
    return lspconfig_util
end

package.preload['lspconfig/util'] = function()
    return lspconfig_util
end

package.preload['lspconfig.async'] = function()
    return {
        run_command = function(cmd, opts, callback)
            callback({stdout = "", stderr = "", code = 0})
        end,
        schedule = function(fn) fn() end
    }
end

package.preload['lspconfig'] = function()
    return {
        util = lspconfig_util
    }
end

-- Mock vim.lsp.handlers
package.preload['vim.lsp.handlers'] = function()
    return {
        ['textDocument/hover'] = function() end,
        ['textDocument/publishDiagnostics'] = function() end,
        ['textDocument/references'] = function() end,
        ['textDocument/definition'] = function() end,
        ['workspace/executeCommand'] = function() end
    }
end

-- Mock vim.lsp.log
package.preload['vim.lsp.log'] = function()
    return {
        trace = function() end,
        debug = function() end,
        info = function() end,
        warn = function() end,
        error = function() end
    }
end

-- Create vim table mock for compatibility
_G.vim = {
    tbl_keys = function(t)
        local keys = {}
        for k, _ in pairs(t) do
            table.insert(keys, k)
        end
        return keys
    end,
    tbl_deep_extend = function(behavior, ...)
        local result = {}
        local tables = {...}
        
        for _, t in ipairs(tables) do
            if type(t) == "table" then
                for k, v in pairs(t) do
                    if type(v) == "table" and type(result[k]) == "table" then
                        result[k] = vim.tbl_deep_extend(behavior, result[k], v)
                    else
                        result[k] = v
                    end
                end
            end
        end
        
        return result
    end,
    tbl_filter = function(func, t)
        local result = {}
        for _, v in ipairs(t) do
            if func(v) then
                table.insert(result, v)
            end
        end
        return result
    end,
    startswith = function(str, prefix)
        return str:sub(1, #prefix) == prefix
    end,
    deprecate = function(feature, alternative, version, plugin, backtrace)
        print("DEPRECATE: " .. feature)
    end,
    version = function()
        return {major = 0, minor = 10, patch = 0}
    end,
    schedule_wrap = function(fn)
        return function(...) fn(...) end
    end,
    empty_dict = function()
        return {}
    end,
    g = {},
    config = {
        get = function() return {} end
    },
    rpc = {
        request = function() return {} end,
        connect = function(host, port)
            return {"mock-gdscript-cmd"}
        end
    },
    fn = {
        has = function(feature) return 1 end,
        stdpath = function(what) return "/mock/stdpath/" .. what end,
        expand = function(expr) return "/mock/expand/" .. expr end,
        executable = function(cmd) return 1 end,
        exepath = function(cmd) return "/usr/bin/" .. cmd end,
        glob = function(pattern) return {"/mock/glob/result"} end,
        isdirectory = function(path) return 1 end,
        getcwd = function() return "/mock/cwd" end,
        getpid = function() return 12345 end
    },
    uv = {
        fs_stat = function(path)
            -- Mock file existence for package.json and common files
            if path:match("package%.json$") then
                return { type = "file", size = 1024 }
            end
            return { type = "file", size = 1024 }
        end,
        os_homedir = function()
            return os.getenv("HOME") or "/home/user"
        end,
        os_tmpdir = function()
            return "/tmp"
        end,
        getpid = function()
            return 12345
        end,
        joinpath = function(...)
            local parts = {...}
            return table.concat(parts, "/")
        end
    },
    fs = {
        normalize = function(path)
            return path
        end,
        root = function(path, markers)
            return "/mock/root"
        end,
        dirname = function(path)
            return path:match("(.*)/") or "."
        end,
        find = function(name, opts)
            return {"/mock/.git"}
        end,
        relpath = function(from, to)
            return nil -- Mock: assume not relative
        end
    },
    env = {
        HOME = os.getenv("HOME") or "/home/user",
        VIMRUNTIME = "/usr/share/nvim/runtime"
    },
    system = function(cmd, opts, callback)
        callback({code = 1, stdout = "", stderr = "mock"})
    end,
    schedule = function(fn) fn() end,
    notify = function(msg) print("NOTIFY: " .. msg) end,
    json = {
        decode = function(str)
            return json.decode(str)
        end
    },
    api = {
        nvim_get_current_buf = function() return 1 end,
        nvim_buf_get_name = function() return "/mock/file.lua" end,
        nvim_buf_create_user_command = function() end
    },
    lsp = {
        get_clients = function() return {} end,
        util = {
            show_document = function() end
        },
        buf = {
            rename = function() end,
            code_action = function() end
        },
        handlers = {},
        protocol = {
            make_client_capabilities = function() return {} end,
            Methods = {
                textDocument_hover = "textDocument/hover",
                textDocument_publishDiagnostics = "textDocument/publishDiagnostics"
            },
            MessageType = {
                Error = 1,
                Warning = 2,
                Info = 3,
                Log = 4
            }
        },
        rpc = {
            connect = function(host, port)
                return {"mock-gdscript-cmd"}
            end,
            request = function() return {} end
        }
    },
    uri_from_bufnr = function() return "file:///mock" end,
    NIL = {}
}

-- Add unpack global for Lua 5.1 compatibility
if not _G.unpack then
    _G.unpack = table.unpack or unpack
end

-- Add os.getenv mock if needed
if not os.getenv then
    os.getenv = function(name)
        local env_vars = {
            HOME = "/home/user",
            CARGO_HOME = "/home/user/.cargo",
            RUSTUP_HOME = "/home/user/.rustup"
        }
        return env_vars[name]
    end
end

-- Mock io.open for configs that read files
local original_io_open = io.open
io.open = function(filename, mode)
    if filename:match("package%.json$") then
        -- Mock package.json content
        local mock_content = '{"dependencies": {"@angular/core": "^15.0.0"}}'
        local mock_file = {
            read = function(self, format)
                if format == "*a" then
                    return mock_content
                end
                return mock_content
            end,
            close = function() end
        }
        return mock_file
    end
    return original_io_open(filename, mode)
end

-- Main execution
local function main()
    print("Extracting LSP configurations from nvim-lspconfig...")
    
    -- Test lua config first
    test_lua_config()
    
    -- Extract all configurations
    local all_configs = extract_all_configs()
    
    -- Sort configs by name for consistent output
    local sorted_names = {}
    for name in pairs(all_configs) do
        table.insert(sorted_names, name)
    end
    table.sort(sorted_names)
    
    local sorted_configs = {}
    for _, name in ipairs(sorted_names) do
        sorted_configs[name] = all_configs[name]
    end
    
    -- Generate JSON output
    local json_output = json.encode(sorted_configs, { indent = true, keyorder = sorted_names })
    
    -- Write to file
    local output_file = "lsp_configs.json"
    local file = io.open(output_file, "w")
    if file then
        file:write(json_output)
        file:close()
        print("\nExtracted " .. #vim.tbl_keys(sorted_configs) .. " configurations to " .. output_file)
        print("File size: " .. lfs.attributes(output_file).size .. " bytes")
    else
        print("Error: Could not write to " .. output_file)
        return 1
    end
    
    return 0
end

-- Execute main function
local success, result = pcall(main)
if not success then
    print("Error: " .. result)
    os.exit(1)
else
    os.exit(result or 0)
end
