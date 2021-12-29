import commonjs from "@rollup/plugin-commonjs";
import resolve from "@rollup/plugin-node-resolve";

export default {
  input: "index.web.js",
  output: {
    dir: "dist",
    format: "umd",
    name: "index.web.js",
  },
  plugins: [commonjs(), resolve()],
};
