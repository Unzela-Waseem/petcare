const eslint = require("@eslint/js");
const globals = require("globals");

module.exports = [
  eslint.configs.recommended,
  {
    ignores: ["node_modules/**"],
  },
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "commonjs",
      globals: {
        ...globals.node,
      },
    },
    rules: {
      "max-len": ["error", {"code": 100}],
    },
  },
];
