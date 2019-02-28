# Internal node dependencies
path = require('path')

# Helper function for when we map over an array
trim = (v) -> v.trim()

# Givem a section of file data attempt to summarize the section if
# the summarization pieces of the file were not specified. Finally
# compute an overall percentage for the section and store it
summarizeSection = (section) ->
    # if either total or hit does not exist, define it
    unless section.total? and section.hit?
        total = hit = 0
        for _, info of section.found
            total++
            hit++ if info > 0 or info.hits > 0

        section.hit = hit
        section.total = total

    # for non-zero counts compute a percentage from 0 to 100 with 1 decimal of precision, otherwise specify -1
    if section.total isnt 0
        section.percentage = Math.round(section.hit / section.total * 1000) / 10
    else
        section.percentage = -1

module.exports = (data, sourceFiles) ->
    # general state for this data
    testName = null
    sourceFiles = sourceFiles || {}

    # loop temporary holding variable during parsing
    file = null
    for line in data.split('\n')
                    .map(trim)
                    .filter((v) -> v.length > 0)

        [type, value] = line.split(':')

        # if this isnt a test name declaration or source file declaration
        # we better have a file declared
        if not (type in ["TN", "SF"]) and not file?
            return null

        switch type
            # Test name delimiter
            when "TN"
                testName = value

            # Source file start delimiter
            when "SF"
                return null if file?

                [_..., fileName] = value.split(path.sep)

                # new file set
                file = sourceFiles[value] ?= {
                    type  : 'file'
                    path  : value
                    name  : fileName
                    stats : {
                        lines     : {
                            found : {}
                        }
                        branches  : {
                            found : {}
                        }
                        functions : {
                            found : {}
                        }
                    }
                }

            # function position marker
            when "FN"
                [lineNumber, name] = value.split(',').map(trim)
                functionData = file.stats.functions.found[name] ?= {}
                functionData.line = parseInt(lineNumber, 10)

            # function execution count marker
            when "FNDA"
                [executionCount, name] = value.split(',').map(trim)
                functionData = file.stats.functions.found[name] ?= {}
                functionData.hits = parseInt(executionCount, 10)

            # functions found counter
            when "FNF"
                file.stats.functions.total = parseInt(value, 10)

            # functions hit counter
            when "FNH"
                file.stats.functions.hit = parseInt(value, 10)

            # branch coverage information
            when "BRDA"
                [lineNumber, blockNumber, branchNumber, taken] = value.split(',').map(trim)
                branch = file.stats.branches.found[lineNumber] ?= {}
                branch.block = blockNumber
                branch.branch = branchNumber
                branch.hits = taken

            # branches found counter
            when "BRF"
                file.stats.branches.total = parseInt(value, 10)

            # branches hit counter
            when "BRH"
                file.stats.branches.hit = parseInt(value, 10)

            # line coverage marker
            when "DA"
                [lineNumber, hitCount] = value.split(',').map(trim)
                file.stats.lines.found[lineNumber] = parseInt(hitCount, 10)

            # lines hit counter
            when "LH"
                file.stats.lines.hit = parseInt(value, 10)

            # lines covered counter
            when "LF"
                file.stats.lines.total = parseInt(value, 10)

            # end of the source file section found
            when "end_of_record"

                # summarize the found and hit counts for functions, branches, and lines
                # if there were not summarization lines provided in the coverage file
                summarizeSection(file.stats.functions)
                summarizeSection(file.stats.branches)
                summarizeSection(file.stats.lines)

                # clear out file information
                file = null

    # no errors, return the lcov data set
    return {
        name : testName
        files : sourceFiles
    }
