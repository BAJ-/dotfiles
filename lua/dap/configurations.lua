return {
  setup = function(dap)
    dap.configurations.typescriptreact = { -- change to typescript if neede
        {
            type = "chrome",
            request = "attach",
            program = "${file}",
            cwd = vim.fn.getcwd(),
            sourceMaps = true,
            protocol = "inspector",
            port = 9222,
            webRoot = "${workspaceFolder}",
        },
    }
    --dap.configurations.typescriptreact = {
    --  {
    --    type = "pwa-chrome",
    --    request = "launch",
    --    name = "Chrome",
    --    port = 9222,
    --    webRoot = "${workspaceFolder}",
    --  }
    --}

    dap.configurations.go = {
      {
        type = "go",
        name = "Debug",
        request = "launch",
        program = "${file}",
      },
      {
        type = "go",
        name = "Debug test (go.mod)",
        request = "launch",
        mode = "test",
        program = "./${relativeFileDirname}",
      },
      {
        type = "go",
        name = "Attach (Pick Process)",
        mode = "local",
        request = "attach",
        processId = require('dap.utils').pick_process,
      },
    }

    local jsOrTs = {
      {
        type = 'node2';
        name = 'Launch',
        request = 'launch';
        program = '${file}';
        cwd = vim.fn.getcwd();
        sourceMaps = true;
        protocol = 'inspector';
        console = 'integratedTerminal';
      },
      {
        type = 'node2';
        name = 'Attach',
        request = 'attach';
        program = '${file}';
        cwd = vim.fn.getcwd();
        sourceMaps = true;
        protocol = 'inspector';
        console = 'integratedTerminal';
      },
      {
        name = "Vitest Debug",
        type = "pwa-node",
        request = "launch",
        cwd = vim.fn.getcwd(),
        program = "${workspaceFolder}/node_modules/vitest/vitest.mjs",
        args = { "--threads", "false", "run", "${file}" },
        autoAttachChildProcesses = true,
        smartStep = true,
        console = "integratedTerminal",
        skipFiles = { "<node_internals>/**", "node_modules/**" },
      },
    }
  
    dap.configurations.typescript = jsOrTs
    dap.configurations.javascript = jsOrTs
  end
}
