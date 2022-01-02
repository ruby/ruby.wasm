import commonjs from '@rollup/plugin-commonjs';
import resolve from "@rollup/plugin-node-resolve";

export default {
  input: "index.js",
  output: {
    dir: "dist",
    format: "umd",
    name: "index.js"
  },
  plugins: [commonjs(), resolve()]
};
