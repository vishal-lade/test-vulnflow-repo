const assert = require('node:assert/strict');
const { test } = require('node:test');
const lockfile = require('../package-lock.json');

test('the installed lodash matches the lockfile and supports the demo operation', () => {
  const lodash = require('lodash');
  assert.equal(lodash.VERSION, lockfile.packages['node_modules/lodash'].version);
  assert.deepEqual(lodash.map([{ id: 'alpha' }, { id: 'beta' }], 'id'), ['alpha', 'beta']);
});
