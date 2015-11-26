#Gulp LCOV to HTML
A javascript based implementation of lcov's genhtml command.

##Purpose
The LCOV coverage format is simple and easy to create but parsing it to human readable HTML typically requires a command line `genhtml` command to be available on systems. When integrating coverage generation to a CI system the availability of this command is not guaranteed so an implementation free of the command line provides the most consistent cross platform results.

##Features
 - Coverage results for both lines and functions displayed
 - HTML output in original `genhtml` theme

##Future Development
 - Display coverage of branches
 - Multiple and custom output themes

#Usage
Usage is pretty simple, grab all your lcov files and pass them through, the output will be the generated set of HTML detailing the coverage.
```
lcov = require('gulp-lcov-to-html')

gulp.task('lcov', function() {
    # grab the lcov files
    return gulp.src("**/*.lcov")

               # pipe them into the plugin
               .pipe(lcov({
                   name : "Optional Suite Name"
               })

               # output the generated html into the bin
               .pipe(gulp.dest("bin"))
});
```

#Developing
This module leverages Node.js and Gulp to make development nice and simple.
```
# Install gulp globally
npm install -g gulp
# Install the module dependencies
npm install

# Compile the module and watch for changes
gulp
```
