import commonjs from '@rollup/plugin-commonjs';

export default {
  input: "index.js",
  output: {
    dir: "dist",
    format: "umd",
    name: "index.js"
  },
  plugins: [commonjs()]
};
