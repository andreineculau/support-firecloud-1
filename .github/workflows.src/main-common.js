/* eslint-disable no-template-curly-in-string */

let fs = require('fs');
let _ = require('lodash-firecloud');

let artifacts = (function() {
  // convert from https://git-scm.com/docs/gitignore format
  // to https://github.com/actions/toolkit/tree/main/packages/glob format
  let artifacts = fs.readFileSync(`${__dirname}/../../.artifacts`, 'utf8');
  artifacts = _.split(artifacts, '\n');
  artifacts = _.reduce(artifacts, function(artifacts, artifact) {
    if (/^#/.test(artifact)) {
      // ignore comments
      return artifacts;
    }
    if (/^\s*$/.test(artifact)) {
      // ignore empty lines
      return artifacts;
    }
    let maybeNegation = '';
    if (/^!$/.test(artifact)) {
      maybeNegation = '!';
      artifact = _.replace(artifact, /^!/, '');
    }
    if (/^\//.test(artifact)) {
      artifact = _.replace(artifact, /^\//, '');
      artifacts.push(`${maybeNegation}${artifact}`);
      return artifacts;
    }
    artifact = `**/${artifact}`;
    artifact = _.replace(artifact, /^\*\*\/\*\//, '**/');
    artifact = _.replace(artifact, /^\*\*\/\*\*\//, '**/');
    artifacts.push(`${maybeNegation}${artifact}`);
    return artifacts;
  }, []);
  // sync with ci/after-script.sh
  artifacts.push('log.sh-session');
  artifacts = _.join(artifacts, '\n');
  return artifacts;
})();

let githubCheckout = fs.readFileSync(`${__dirname}/../../bin/github-checkout`, 'utf8');

let env = {
  GITHUB_TOKEN: '${{ secrets.GITHUB_TOKEN }}',
  SF_LOG_BOOTSTRAP: true,
  SF_PRINTENV_BOOTSTRAP: '${{ secrets.SF_PRINTENV_BOOTSTRAP }}',
  SF_TRANSCRYPT_PASSWORD: '${{ secrets.SF_TRANSCRYPT_PASSWORD }}',
  V: '${{ secrets.V }}'
};

let checkoutStep = {
  name: 'support-firecloud/bin/github-checkout',
  shell: 'bash',
  run: [
    'set -x',
    githubCheckout
  ].join('\n')
};

let ciShSteps = [];

ciShSteps.push({
  shell: 'bash',
  run: './.ci.sh before_install'
});
ciShSteps.push({
  shell: 'bash',
  run: './.ci.sh install'
});
ciShSteps.push({
  shell: 'bash',
  run: './.ci.sh before_script'
});
ciShSteps.push({
  shell: 'bash',
  run: './.ci.sh script'
});
ciShSteps.push({
  if: 'failure()',
  shell: 'bash',
  run: './.ci.sh after_failure || true'
});
ciShSteps.push({
  shell: 'bash',
  run: './.ci.sh after_success || true'
});
ciShSteps.push({
  if: 'always()',
  shell: 'bash',
  run: './.ci.sh after_script || true'
});
ciShSteps.push({
  if: 'always()',
  shell: 'bash',
  env: {
    SLACK_WEBHOOK: '${{ secrets.SLACK_WEBHOOK }}',
    SLACK_CHANNEL: 'cloud-ci',
    SF_CI_STATUS: '${{ job.status }}'
  },
  run: './.ci.sh notifications || true'
});

let ciShStepsDeploy = [];
ciShStepsDeploy.push({
  shell: 'bash',
  run: './.ci.sh before_deploy'
});
ciShStepsDeploy.push({
  shell: 'bash',
  run: './.ci.sh deploy'
});
ciShStepsDeploy.push({
  shell: 'bash',
  run: './.ci.sh after_deploy || true'
});

let artifactsStep = {
  name: 'Upload Artifacts',
  uses: 'actions/upload-artifact@v2',
  with: {
    name: undefined, // need to overwrite
    path: artifacts,
    'retention-days': 7
  }
};

module.exports = {
  artifactsStep,
  checkoutStep,
  ciShSteps,
  ciShStepsDeploy,
  env
};
