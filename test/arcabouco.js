require('coffee-script');
var Arcabouco = require('../lib/arcabouco');
var assert = require('assert');
var sinon = require('sinon');
var util = require('util');

exports['testing constructors'] = function() {
  var app = new Arcabouco();
  assert.ok( app );

  //assert.equal(found, properties.length);
  //assert.equal(uuid.version, 4, 'Unexpected version: ' + uuid.version);
  //assert.ok(isUUID(uuid.hex), 'UUID semantically incorrect');
};

for (var key in exports) {
  exports[key]();
  //console.log(key);
  console.log('.');
}
