import commonjs from "@rollup/plugin-commonjs";

const nodeBuiltins = ["path", "fs", "child_process"]

export default {
  input: "index.js",
  output: {
    dir: "dist",
    name: "loadRuby",
    format: "umd"
  },
  plugins: [commonjs()],
  external: ["path", "fs", "child_process"],
  onwarn: (warning, defaultHandler) => {
    // suppress warnings introduced by conditional "require" by Emscripten
    if(warning.code == "MISSING_GLOBAL_NAME" && nodeBuiltins.filter(pkg => pkg == warning.source).length) {
      return;
    }
    if(warning.code == "MISSING_NODE_BUILTINS") {
      return;
    }
    console.log(warning)
    defaultHandler(warning)
  }
};
