# Internal node dependencies
fs    = require("fs")
path  = require("path")

# Node module dependencies
_     = require("lodash")
gutil = require("gulp-util")

# Internal dependencies
tree  = require('./tree.js')

templateBasePath = path.join("..", "templates", "html")
templates = {
    directory : _.template(fs.readFileSync(path.resolve(__dirname, path.join(templateBasePath, "directory.underscore"))))
    file      : _.template(fs.readFileSync(path.resolve(__dirname, path.join(templateBasePath, "file.underscore"))))
}

success = (percentage) ->
    if percentage is -1 or percentage >= 90
        return "pass"
    else if percentage >= 70
        return "warn"
    else
        return "fail"

generateTree = (suiteData, tree, curPath = []) ->
    if tree.type is 'file'
        curPath.push(tree.name)
        generated = generateFile(suiteData, tree, curPath)
        curPath.pop()
    else
        generated = [generateDirectory(suiteData, tree, curPath)]

        for name, child of tree.children
            if tree.name isnt ''
                curPath.push(tree.name)
            generated = generated.concat(generateTree(suiteData, child, curPath))
            if tree.name isnt ''
                curPath.pop()

    return generated

generateFile = (suiteData, info, curPath = []) ->
    source = null
    if fs.statSync(info.path).isFile()
        source = fs.readFileSync(info.path, {
            encoding : 'utf8'
        }).split('\n')

    date = new Date()
    html = templates.file({
        # functions
        success : success

        # data
        path : curPath
        suite : suiteData.name
        date : suiteData.date
        info : info
        source : source
    })

    return new gutil.File({
        path     : curPath.join(path.sep) + ".html"
        contents : new Buffer(html)
    })

generateDirectory = (suiteData, info, curPath = []) ->
    directoryPath = curPath
    if info.name isnt ''
        directoryPath = curPath.concat(info.name)

    subdirectories = []
    files = []
    for name, child of info.children
        if child.type is 'file'
            files.push(child)
        else
            subdirectories.push(child)

    date = new Date()
    html = templates.directory({
        # functions
        success : success

        # data
        path : directoryPath
        suite : suiteData.name
        date : suiteData.date
        info : info

        # sections
        subdirectories : subdirectories
        files : files
    })

    return new gutil.File({
        path     : directoryPath.concat('index.html').join(path.sep)
        contents : new Buffer(html)
    })

module.exports = (suiteData) ->
    return generateTree(suiteData, tree(suiteData.files))
