//node Jinrou starter with forever
forever=require('forever');

var child=forever.start(['socketstream','start']);
