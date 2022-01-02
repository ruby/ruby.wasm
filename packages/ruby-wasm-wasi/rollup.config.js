import typescript from '@rollup/plugin-typescript';

export default {
  input: "src/index.ts",
  output: {
    dir: "dist",
    name: "rubyVM",
    format: "umd"
  },
  plugins: [typescript()],
};
