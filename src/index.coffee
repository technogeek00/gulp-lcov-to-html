# Internal node dependencies
fs      = require("fs")
path    = require("path")

# Node module dependencies
format  = require("dateformat")
through = require("through2")
gutil   = require("gulp-util")
sass    = require("node-sass")

# Internal dependencies
parser   = require('./parser.js')
generate = require('./generate.js')

PLUGIN_NAME = "gulp-lcov-genhtml"

module.exports = (options = {}) ->
    # track whether or not we actually did output some coverage files
    didOutputFiles = false

    # For every coverage file that comes down the pipe parse it and output the appropriate html files
    gatherFiles = (file, enc, cb) ->
        if file.isNull()
            return cb(null, file)

        if file.isStream()
            return cb(new gutil.PluginError(PLUGIN_NAME, "Streams are not supported"))

        parsedData = parser(file.contents.toString(enc))
        unless parsedData?
            return cb(new gutil.PluginError(PLUGIN_NAME, "Incorrectly formatted lcov file: #{file.path}"))

        parsedData.name ?= options.name
        parsedData.date = format(file.stat.ctime, "yyyy-mm-dd")

        for file in generate(parsedData)
            didOutputFiles = true
            @push(file)

        # don't pass the actual coverage file forward
        cb()

    # When all files have come down the pipe and it is closing
    # we want to process
    generateHTML = (cb) ->
        # if we havent done any work skip this
        return cb() unless didOutputFiles

        # if we did output files render the appropriate scss and send it down the pipe
        sass.render({
            file : path.resolve(__dirname, path.join("..", "templates", "css", "classic.scss"))
        }, (err, data) =>
            cb(err) if err?

            @push(new gutil.File({
                path     : "classic.css"
                contents : data.css
            }))

            cb()
        )

    return through.obj(gatherFiles, generateHTML)