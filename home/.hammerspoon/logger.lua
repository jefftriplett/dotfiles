-- logger.lua: Structured logging for Hammerspoon with configurable levels

local logger = {}

-- Log levels
logger.LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

-- Default configuration
logger.config = {
    level = logger.LEVELS.INFO,  -- Default log level
    showLevel = true,            -- Include level in output
    showTimestamp = true,        -- Include timestamps in output
    historySize = 200            -- Number of log entries to keep in history
}

-- Initialize the hs.logger
logger.init = function()
    logger.hsLogger = hs.logger.new('hammerspoon', 'info')
    -- Set history size if supported
    if logger.hsLogger.setHistorySize then
        logger.hsLogger:setHistorySize(logger.config.historySize)
    end
    return logger
end

-- Debug level logging
logger.d = function(...)
    if logger.config.level <= logger.LEVELS.DEBUG then
        local args = {...}
        if logger.config.showLevel then
            table.insert(args, 1, "[DEBUG]")
        end
        logger.hsLogger.d(table.unpack(args))
    end
end

-- Info level logging
logger.i = function(...)
    if logger.config.level <= logger.LEVELS.INFO then
        local args = {...}
        if logger.config.showLevel then
            table.insert(args, 1, "[INFO]")
        end
        logger.hsLogger.i(table.unpack(args))
    end
end

-- Warning level logging
logger.w = function(...)
    if logger.config.level <= logger.LEVELS.WARN then
        local args = {...}
        if logger.config.showLevel then
            table.insert(args, 1, "[WARN]")
        end
        logger.hsLogger.w(table.unpack(args))
    end
end

-- Error level logging
logger.e = function(...)
    if logger.config.level <= logger.LEVELS.ERROR then
        local args = {...}
        if logger.config.showLevel then
            table.insert(args, 1, "[ERROR]")
        end
        logger.hsLogger.e(table.unpack(args))
    end
end

-- Set the logging level
logger.setLevel = function(level)
    logger.config.level = level
    return logger
end

-- Set whether to show log level in output
logger.showLevel = function(show)
    logger.config.showLevel = show
    return logger
end

-- Set whether to show timestamps in output
logger.showTimestamp = function(show)
    logger.config.showTimestamp = show
    return logger
end

-- Set the history size
logger.setHistorySize = function(size)
    logger.config.historySize = size
    if logger.hsLogger.setHistorySize then
        logger.hsLogger:setHistorySize(size)
    end
    return logger
end

return logger.init()