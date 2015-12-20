module.exports = (grunt) ->
	params =
		jshint:
			options:
				jshintrc: '.jshintrc'
			all: ['assets/*.js']
		imagemin:
			dist:
				options:
					optimizationLevel: 7
					progressive: true
				files: [{
					expand: true,
					cwd: 'images/',
					src: '{,*/}*.{png,jpg,jpeg}',
					dest: 'images/'
				}]
		clean:
			site: ['_site']
		exec:
			build:
				cmd: 'jekyll b'
			deploy:
				cmd: 's3_website push'

	grunt.initConfig params

	grunt.loadNpmTasks 'grunt-contrib-clean'
	grunt.loadNpmTasks 'grunt-contrib-jshint'
	grunt.loadNpmTasks 'grunt-contrib-imagemin'
	grunt.loadNpmTasks 'grunt-exec'

	grunt.registerTask('build', [
		'clean:site',
		'imagemin',
		'exec:build'
	])

	grunt.registerTask('default', [
		'build'
	])

	grunt.registerTask('deploy', [
		'build'
		'exec:deploy'
	])