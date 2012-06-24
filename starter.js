//node Jinrou starter with forever
forever=require('forever');

var child=(forever.Monitor)('app.js',{
	max:10,
	env:{SS_ENV:'production'},
});
