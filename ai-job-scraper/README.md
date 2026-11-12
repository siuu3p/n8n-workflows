# AI Job Scraper

Mention the Slack bot with a job search (for example `@JobBot remote n8n developer`). The workflow checks that it really is a job search, finds jobs posted in the last 3 days through JSearch, and for each job:

- writes an ATS-optimized copy of your resume in Google Docs
- creates a Gmail draft application if the post lists an email address
- writes an Upwork proposal if it's an Upwork job
- posts the links back to Slack

Nothing is sent automatically. Applications are saved as Gmail **drafts**.

## Flow

```
Slack Trigger (@mention in #jobs)
  -> Get Query (strip the @mention)
  -> For checking query (Gemini: is this a job search? YES/NO)
  -> Query Valid?
       no  -> Invalid Query (Slack)
       yes -> Send Job Search (Slack: "Searching ...")
              -> Get All Jobs (JSearch on RapidAPI: remote, last 3 days)
              -> Flatten Jobs (max 10, de-duplicated)
              -> Check Results
                   none -> Invalid Query (Slack)
                   some -> Split Out -> Loop Over Items (one job at a time)
                           -> Get Resume Content (Google Docs template)
                           -> Resume and Proposal Creator (OpenRouter LLM + JSON parser)
                                error -> skip to next job
                           -> Search files and folders (already made today?)
                           -> No Resume Yet?
                                exists -> skip to next job
                           -> Wait 5s -> Resume Copy (Drive) -> Wait 5s -> Update a document (fill placeholders)
                           -> Has Email Address?
                                yes -> Create an email draft (Gmail)
                           -> Send a message to Jobs Channel (Slack) -> next job
                        all done -> Search Complete (Slack)
```

## Setup

### 1. Credentials

| Credential | Used by | Notes |
|---|---|---|
| Slack API (bot token) | Slack Trigger and all Slack nodes | Bot scopes: `app_mentions:read`, `chat:write` |
| Google Gemini (PaLM) API | For checking query | Free key from aistudio.google.com |
| **Header Auth**, name `x-rapidapi-key`, value = your RapidAPI key | Get All Jobs | Subscribe to JSearch on rapidapi.com first |
| OpenRouter API | OpenRouter Chat Model | |
| Google Docs OAuth2 | Get Resume Content, Update a document | |
| Google Drive OAuth2 | Search files and folders, Resume Copy | |
| Gmail OAuth2 | Create an email draft | |

The RapidAPI key is a credential now, not a header typed into the node, so it isn't saved in the workflow JSON or in this repo.

### 2. Resume template (Google Docs)

Your template doc keeps your fixed details (name, contact, education) and has these four placeholders where the tailored text goes:

```
{{ProfessionalSummary}}
{{CoreSkills}}
{{listOfProjects}}
{{ProfessionalExperience}}
```

**Get Resume Content** and **Resume Copy** both point at that doc. If you use a different template, change both nodes.

### 3. Slack app

1. At api.slack.com/apps, open your app and go to **Event Subscriptions**. Turn it on and paste the **Production URL** from the Slack Trigger node.
2. Under **Subscribe to bot events**, add `app_mention`.
3. Reinstall the app, then invite the bot to `#jobs`: `/invite @YourBot`.

Slack can only reach the trigger if your n8n instance is public (n8n Cloud, or self-hosted with `WEBHOOK_URL` set). The trigger only listens once the workflow is **published**. While you test, use the node's **Test URL** in Slack instead.

### 4. Test it

1. In `#jobs`, post `@YourBot what's the weather` and expect "Invalid Query / No Results Found".
2. Post `@YourBot remote n8n developer`. Expect "Searching...", then one message per job with a resume link, then "Done. Processed N job(s)".
3. Open a resume link and check that all four placeholders were replaced.
4. Post the same search again the same day. Jobs that already have a resume are skipped.

## Tuning

- **Number of jobs:** change `MAX_JOBS` in **Flatten Jobs** (default 10). Each job uses one LLM call and creates one Google Doc.
- **Search filters:** change these in **Get All Jobs**: `date_posted` (`today`, `3days`, `week`, `month`), `work_from_home`, `employment_types`, or add `country`.
- **Gmail draft link:** the Slack message uses `mail.google.com/mail/u/0/`. If the Gmail account isn't the first one signed in to your browser, change the `0`.
