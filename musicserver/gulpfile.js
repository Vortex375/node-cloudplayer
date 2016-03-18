var gulp        = require('gulp'),
    watch       = require('gulp-watch'),
    coffee      = require('gulp-coffee'),
    sourcemaps  = require('gulp-sourcemaps'),
    changed     = require('gulp-changed'),
    plumber     = require('gulp-plumber'),
    notify      = require('gulp-notify'),
    rename      = require('gulp-rename'),
    fs          = require('fs'),
    stream      = require('stream');

var paths = {
    source: 'src/**/*.coffee',
    output: 'build'
}

gulp.task('coffee', function () {
    gulp.src(paths.source)
    .pipe(plumber({errorHandler: notify.onError('Error: <%= error %>')}))
    .pipe(changed(paths.output, {extension: '.js'}))
    .pipe(sourcemaps.init({loadMaps: true}))
    .pipe(coffee({ bare: true, map: true}))
    .pipe(sourcemaps.write({includeContent: true}))
    .pipe(rename(function (file) {
        // abusing gulp-rename here
        console.log("compile coffee script", file.dirname + '/' + file.basename + file.extname)
    }))
    .pipe(gulp.dest(paths.output));
});

// outputs changes to files to the console
function reportChange(event) {
  console.log(event.path + ' was ' + event.type + ', running tasks...');
}

gulp.task('build', ['coffee'])
gulp.task('watch', ['build'], function() {
    gulp.watch(paths.source, ['coffee']).on('change', reportChange);
});
