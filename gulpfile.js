'use strict';

var gulp = require('gulp');
var less = require('gulp-less');
var minifyCss = require('gulp-minify-css');
var watch = require('gulp-watch');
var logger = require('gulp-logger');
var path = require('path');

gulp.task('default', ['less'], function() {
  // place code for your default task here
});

gulp.task('less', function () {
    return gulp.src('static/less/**/*.less')
        .pipe(watch('static/less/**/*.less'))
        .pipe(less())
        .pipe(minifyCss())
        .pipe(gulp.dest('static/css'))
        .pipe(logger({ beforeEach: 'less [wrote]: '}));
});
