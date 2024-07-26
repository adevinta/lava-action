// Copyright 2024 Adevinta

// This module generates summaries and comments pull requests based on
// the Lava results.

const fs = require('fs')

function generateSummary(core, fullreport) {
  var body = '### Lava scan results\n\n';

  if (!fullreport.summary || !fullreport.summary.count || Object.keys(fullreport.summary.count).length === 0) {
    return body + `No vulnerabilities found! 🎉\n\n`;
  }

  body += `| Severity | Findings |\n`;
  body += `|---|---:|\n`;

  if (fullreport.summary.count.critical && fullreport.summary.count.critical > 0) {
    body += `| 🟣 Critical | ${fullreport.summary.count.critical} |\n`;
  }
  if (fullreport.summary.count.high && fullreport.summary.count.high > 0) {
    body += `| 🔴 High | ${fullreport.summary.count.high} |\n`;
  }
  if (fullreport.summary.count.medium && fullreport.summary.count.medium > 0) {
    body += `| 🟠 Medium | ${fullreport.summary.count.medium} |\n`;
  }
  if (fullreport.summary.count.low && fullreport.summary.count.low > 0) {
    body += `| 🟡 Low | ${fullreport.summary.count.low} |\n`;
  }
  if (fullreport.summary.count.info && fullreport.summary.count.info > 0) {
    body += `| 🔵 Info | ${fullreport.summary.count.info} |\n`;
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

// writeSummary writes a step job summary based on the full report
// file.
module.exports.writeSummary = async (core) => {
  // eslint-disable-next-line no-undef
  const fullreport = JSON.parse(fs.readFileSync(process.env.FULLREPORT, 'utf8'));
  const summary = generateSummary(core, fullreport);
  core.summary.addRaw(summary).write();
}

// postComment creates or updates a comment in the pull request based
// on the full report file.
module.exports.postComment = async (github, context, core) => {
  // eslint-disable-next-line no-undef
  const fullreport = JSON.parse(fs.readFileSync(process.env.FULLREPORT, 'utf8'));
  const summary = generateSummary(core, fullreport);
  try {
    await comment(github, context, summary);
  } catch (e) {
    console.log(e);
    core.summary
      .addHeading(':warning: Unable to create pull request comment', 4)
      .addRaw('Error:', true).addQuote(e)
      .addRaw('Remember to grant the required permissions to the job (or disable comment-pr option).', true)
      .addCodeBlock('permissions:\n  pull-requests: write', 'yaml')
      .write();
  }
}
