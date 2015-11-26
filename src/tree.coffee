# Internal node dependencies
path = require('path')

# Helper for adding the coverage counts in a subtree to the coverage counts in a parent tree
totalSection = (sectionName, tree, subtree) ->
    treeSection = tree.stats[sectionName]
    subSection = subtree.stats[sectionName]

    treeSection.hit += subSection.hit
    treeSection.total += subSection.total

    # recompute the percentage of the parent tree since it may have changed now
    if treeSection.total isnt 0
        treeSection.percentage = Math.round(treeSection.hit / treeSection.total * 1000) / 10
    else
        treeSection.percentage = -1

# takes a tree of directories and files summarizing the overall
# coverage of each directory and file in the tree
summarizeCoverage = (tree) ->
    if tree.type is 'directory'
        for own item, subtree of tree.children
            # summarize child coverage first
            summarizeCoverage(subtree)

            totalSection('lines', tree, subtree)
            totalSection('branches', tree, subtree)
            totalSection('functions', tree, subtree)

    # explicitly void the return
    return

# Construct a new object describing a directory in the tree
newDirectory = (name) ->
    return {
        name : name
        type : 'directory'
        children : {}
        stats : {
            lines : {
                hit        : 0
                total      : 0
                percentage : 0
            }
            branches : {
                hit        : 0
                total      : 0
                percentage : 0
            }
            functions : {
                hit        : 0
                total      : 0
                percentage : 0
            }
        }
    }

module.exports = (linearMap) ->
    tree = newDirectory('')

    # for each piece of data build out the appropriate branches
    for file, info of linearMap
        [filePath..., fileName] = file.split(path.sep)
                                      .map((v) -> v.trim())
                                      .filter((v) -> v.length > 0)

        directory = tree
        for piece in filePath
            directory = directory.children[piece] ?= newDirectory(piece)

        directory.children[fileName] = info

    # summarize stats within the generated tree
    summarizeCoverage(tree)

    # prune the top directories of the tree that have only one child
    while tree? and tree.type is 'directory' and (keys = Object.keys(tree.children)).length is 1
        tree = tree.children[keys[0]]

    # tree is ready to go
    return tree
