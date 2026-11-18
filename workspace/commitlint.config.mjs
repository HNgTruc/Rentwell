// Conventional Commits (docs/08-guides/git-workflow.md). Ví dụ: "feat(api): add health check".
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'header-max-length': [2, 'always', 100],
  },
};
