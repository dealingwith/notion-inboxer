# Notion Inboxer 📤

I built this simply CLI to process pages in the Notion DB where I chuck everything. With this technique, any page without a "Status" is my "inbox".

This app only works with databases with the built-in Notion column "Status". It does not check if the DB you choose has it (yet), so it will just error if you choose a DB w/o a "Status".

1. Create a new "Internal Integration" for yourself at [notion.so/profile/integrations](https://www.notion.so/profile/integrations)
1. Create a `.env` file in this directory
1. Add your integration's "Internal Integration Secret" as `NOTION_API_KEY=[secret]` in `.env`
1. Run `bundle`
1. Run `ruby run.rb`

Once running:

1. Choose your DB
1. Update statuses on pages (or delete ["archive"] them)

### TODO

- [ ] "Move pages". This is technically impossible via the API, so I plan to "mark" pages for moving for easy bulk moving in the Notion UI.
- [ ] Add configurability to both filter by and edit other page properties.
- [ ] Only give the option to choose DBs that will work with the script.
