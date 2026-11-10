# Lead Intake Automation

An n8n workflow that takes a lead from a web form, cleans the data, checks for duplicates, logs it to Google Sheets and Notion, replies to the lead, and alerts the owner when the budget is high.

Estimated time saved: about 5 minutes per lead.

## Flow

```
Lead Intake Form
  -> Clean Lead Data
  -> Find Existing Email (Google Sheets lookup)
  -> Duplicate?
       true  -> Log Duplicate (Sheets row, Duplicate? = Yes)
       false -> Log New Lead (Sheets row, Duplicate? = No)
                -> Create Notion Lead
                -> Send Auto-Reply (Gmail)
                -> Is High Priority?
                     true -> Alert Owner (Gmail)
```

## What each step does

| Node | Purpose |
|---|---|
| Lead Intake Form | n8n Form Trigger: name, email, phone, company, service, budget, message |
| Clean Lead Data | Trims spaces, proper-cases the name, lowercases the email, strips phone formatting, adds a Lead ID, timestamp, Status = New, and Priority (High for budgets of $1000 and above) |
| Find Existing Email | Looks up the cleaned email in the Google Sheets lead log (Always Output Data on, so new leads continue) |
| Duplicate? | Routes repeat submissions away from Notion and email |
| Log Duplicate / Log New Lead | Appends the lead to the sheet with a Duplicate? flag |
| Create Notion Lead | Creates a page in the Notion Leads database |
| Send Auto-Reply | Sends the lead a thank-you email |
| Is High Priority? / Alert Owner | Emails the owner a summary and a Notion link for high-budget leads |

Errors are routed to a separate Error Alert workflow (Error Trigger to Gmail).

## Tested cases

1. New lead, low budget: sheet row (No), Notion page, auto-reply, no alert
2. New lead, high budget: sheet row (No), Notion page, auto-reply, owner alert
3. Repeat email: sheet row (Yes) only, no Notion page or emails

## Setup

1. Import `lead-intake-automation.json` into n8n.
2. Create credentials for Google Sheets (OAuth2), Gmail (OAuth2), and Notion (internal integration).
3. Create a Google Sheet with this header row:
   `Time Stamp | Lead ID | Name | Email | Phone | Company | Service | Budget | Message | Priority | Status | Duplicate?`
4. Create a Notion database with Name (title), Lead ID, Email, Phone, Company, Message (text), Service, Budget, Priority, Status (select), and Submitted (date). Connect the integration to it.
5. Point the Sheets, Notion, and Gmail nodes at your own sheet, database, and email address.
6. Set the workflow timezone and publish it.

Built by Dennis Dionisio.
