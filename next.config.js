/** @type {import('next').NextConfig} */
const nextConfig = {
  productionBrowserSourceMaps: false,
  webpack: (config, { dev }) => {
    if (dev) {
      config.devtool = 'eval-cheap-module-source-map';
    }
    return config;
  },
}

module.exports = nextConfig
