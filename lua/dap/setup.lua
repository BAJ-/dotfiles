return {
  setup = function()
    require("mason-nvim-dap").setup({
      ensure_installed = {
        -- delve is for debugging Go applications
        "delve",
        -- node2 is for debugging Node applications
        "node2",
        -- chrome is for debugging in the browser
        "chrome",
        "js"
      }
    })

    -- Make sure we have Dap installed
    local dap_ok, dap = pcall(require, "dap")
    if not (dap_ok) then
      print("nvim-dap not installed!")
      return
    end

    -- Make sure we have Dap UI installed
    local dap_ui_ok, ui = pcall(require, "dapui")
    if not (dap_ok and dap_ui_ok) then
      require("notify")("dap-ui not installed!", "warning")
      return
    end

    require('dap').set_log_level('INFO')

    -- Debug adapters
    require('dap.adapters').setup(dap)
    -- Debug configurations
    require('dap.configurations').setup(dap)
    -- Dap UI setup
    require('dap.dapui').setup(ui)
  end
}
