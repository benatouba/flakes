local log = require("structlog")

log.configure({
  name = {
    sinks = {
      log.sinks.NvimNotify(
        log.level.WARN,
        {
          processors = {
            log.processors.Namer(),
          },
          formatter = log.formatters.Format( --
            "%s",
            { "msg" },
            { blacklist = { "level", "logger_name" } }
          ),
          params_map = { title = "logger_name" },
        }),
    },
  },
  -- other_logger = {...}
})
