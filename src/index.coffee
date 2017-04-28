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
    # capture all the parsed source files
    lcovData = null

    # For every coverage file that comes down the pipe parse it and output the appropriate html files
    gatherFiles = (file, enc, cb) ->
        if file.isNull()
            return cb(null, file)

        if file.isStream()
            return cb(new gutil.PluginError(PLUGIN_NAME, "Streams are not supported"))

        # independently parse this file
        parseResults = parser(file.contents.toString(enc), lcovData?.files)
        unless parseResults?
            return cb(new gutil.PluginError(PLUGIN_NAME, "Incorrectly formatted lcov file: #{file.path}"))

        # store the lcov object only back once since subsequent parses have
        # access to the same files object already contained in the lcov data
        lcovData ?= parseResults

        # set the date of the file to the first available file
        lcovData.date ?= format(file.stat.ctime, "yyyy-mm-dd")

        # don't pass the actual coverage file forward
        cb()

    # When all files have come down the pipe and it is closing
    # we want to process
    generateHTML = (cb) ->
        # if we havent done any work skip this
        return cb() unless lcovData

        # use the provided name if given
        lcovData.name = options.name ? lcovData.name

        # generate all the html files
        for file in generate(lcovData)
            @push(file)

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
