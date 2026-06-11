--[[
  Spring Boot Tools（移植自 VS Code Spring Boot 扩展）

  能力：Web Endpoint / Bean 查找、application.yml 补全、Spring 注解 code action 等。
  jdtls bundles 注入见 platform/cli/java/settings.lua

  高级配置项（bootls.Config）：
    ls_path    — language-server.jar 路径（默认 Mason → VS Code 扩展目录）
    java_cmd   — 启动 Spring Boot LS 的 java（默认 $JAVA_HOME/bin/java）
    jdtls_name — 与 jdtls 通信时的 client 名，默认 "jdtls"
    logLevel   — LS 日志级别：warn / info / debug（默认 warn）
    log_file   — string 或 fun(root_dir): string，默认 /dev/null
    autocmd    — 打开 java/yaml/jproperties 时自动 attach LS，默认 true
    server     — 传给 vim.lsp.start 的 ClientConfig，可覆盖 handlers / on_attach 等
]]
return {
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    dependencies = {
      "mfussenegger/nvim-jdtls",
      "mason-org/mason.nvim",
      "folke/snacks.nvim",
    },
    ---@type bootls.Config
    opts = {
      autocmd = true,
      logLevel = "warn",
      -- 调试 Spring Boot LS 时可改为：
      -- logLevel = "debug",
      -- log_file = function(root_dir)
      --   return vim.fn.stdpath("log") .. "/spring-boot-" .. vim.fn.fnamemodify(root_dir or "global", ":t") .. ".log"
      -- end,
      server = {
        -- init_options.enableJdtClasspath = false, -- 默认 false，classpath 经 jdtls handler 同步
      },
    },
    config = function(_, opts)
      require("spring_boot").setup(opts)
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "vscode-spring-boot-tools" })
      return opts
    end,
  },
}
