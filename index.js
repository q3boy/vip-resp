if (require.extensions['.coffee']) {
  module.exports = require('./lib/vip-resp.coffee');
} else {
  module.exports = require('./out/release/lib/vip-resp.js');
}
