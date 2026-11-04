export default {
  "*.{ts,tsx}": ["eslint --fix"],
  "*.{ts,tsx,js,jsx,json,css,md}": ["prettier --write"], // remove if the repo does not use Prettier
};
// Husky .husky/pre-commit:  npx tsc --noEmit && npx lint-staged
