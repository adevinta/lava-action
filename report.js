// Copyright 2024 Adevinta

// This module generates summaries and comments pull requests based on the Lava results.

const fs = require('fs')

function generateSummary(core, metrics) {
  var body = '### Lava scan results\n\n';

  if (!metrics.vulnerability_count || Object.keys(metrics.vulnerability_count).length === 0) {
    return body + `No vulnerabilities found! 🎉\n\n`;
  }

  body += `| Severity | Findings |\n`;
  body += `|---|---:|\n`;

  if (metrics.vulnerability_count["critical"] > 0) {
    body += `| 🟣 Critical | ${metrics.vulnerability_count["critical"]} |\n`;
  }
  if (metrics.vulnerability_count["high"] > 0) {
    body += `| 🔴 High | ${metrics.vulnerability_count["high"]} |\n`;
  }
  if (metrics.vulnerability_count["medium"] > 0) {
    body += `| 🟠 Medium | ${metrics.vulnerability_count["medium"]} |\n`;
  }
  if (metrics.vulnerability_count["low"] > 0) {
    body += `| 🟡 Low | ${metrics.vulnerability_count["low"]} |\n`;
  }
  if (metrics.vulnerability_count["info"] > 0) {
    body += `| 🔵 Info | ${metrics.vulnerability_count["info"]} |\n`;
  }
  return body;
}

async function comment(github, context, summary) {
  const mark = `<!-- action:lava-action job:${context.job} -->`;
  const body = summary + mark + `\n\n[Logs ${context.job}](${context.serverUrl}/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId})`;

  // Get the existing comments.
  const { data: comments } = await github.rest.issues.listComments({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.payload.number
  })

  // Delete the comments created by the bot and containing the mark.
  await comments
    .filter(comment => comment.body.includes(mark))
    .forEach(async (comment) => {
      try {
        await github.rest.issues.deleteComment({
          owner: context.repo.owner,
          repo: context.repo.repo,
          comment_id: comment.id
        })
      } catch (e) {
        console.log(e);
      }
    });

  await github.rest.issues.createComment({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.payload.number,
    body: body
  })
}

// writeSummary writes a step job summary based on the metrics file.
module.exports.writeSummary = async (core) => {
  // eslint-disable-next-line no-undef
  const metrics = JSON.parse(fs.readFileSync(process.env.METRICS, 'utf8'));
  const summary = generateSummary(core, metrics);
  core.summary.addRaw(summary).write();
}

// postComment creates or updates a comment in the pull request based on the metrics file.
module.exports.postComment = async (github, context, core) => {
  // eslint-disable-next-line no-undef
  const metrics = JSON.parse(fs.readFileSync(process.env.METRICS, 'utf8'));
  const summary = generateSummary(core, metrics);
  try {
    await comment(github, context, summary);
  } catch (e) {
    console.log(e);
    core.summary
      .addHeading(':warning: Unable to create pull request comment', 4)
      .addRaw('Error:', true).addQuote(e)
      .addRaw('Remember to grant the required permissions to the job (or disable comment-pr option).', true)
      .addCodeBlock('permissions:\n  pull_request: write', 'yaml')
      .write();
  }
}
