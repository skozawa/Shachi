'use strict';

var gulp = require('gulp');
var less = require('gulp-less');
var minifyCss = require('gulp-minify-css');
var watch = require('gulp-watch');
var logger = require('gulp-logger');
var ts = require('gulp-typescript');
var path = require('path');

gulp.task('default', ['less', 'typescript'], function() {
    gulp.watch('static/ts/*.ts', ['typescript']);
});

gulp.task('less', function () {
    return gulp.src('static/less/**/*.less')
        .pipe(watch('static/less/**/*.less'))
        .pipe(less())
        .pipe(minifyCss())
        .pipe(gulp.dest('static/css'))
        .pipe(logger({ beforeEach: 'less [wrote]: '}));
});

gulp.task('typescript', function () {
    var tsResult = gulp.src('static/ts/**/*.ts')
            .pipe(ts({
                target: 'ES6',
                removeComments: true,
                sortOutput: true,
                out: 'main.js'
            }));
    return tsResult.js.pipe(gulp.dest('static/js'));
});
