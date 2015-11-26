coffee = require("gulp-coffee")
del    = require("del")
gulp   = require("gulp")

gulp.task("clean", ->
    return del("lib")
)

gulp.task("compile", ["clean"], ->
    return gulp.src("src/**/*.coffee")
               .pipe(coffee({
                    bare : true
                }))
               .pipe(gulp.dest("lib"))
)

gulp.task("watch", ["compile"], ->
    gulp.watch("src/**/*.coffee", ["compile"])
)

gulp.task("default", ["watch"])