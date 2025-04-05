require "dotenv/load"
require "tty-prompt"
require "notion-ruby-client"
require "awesome_print"

notion = Notion::Client.new(token: ENV["NOTION_API_KEY"])
prompt = TTY::Prompt.new

# Global variable to store databases
$databases = []
# Global variable to store status options
$status_options = []

# Fetch pages from a Notion database
def fetch_pages(notion, database_id, filter = nil)
  filter ||= {
    property: "Status",
    status: {
      is_empty: true,
    },
  }

  notion.database_query(database_id: database_id, filter: filter).results
end

# Fetch the status options for the "status" property
def fetch_status_options(notion, database_id)
  database = $databases.find { |db| db[:id] == database_id }
  properties = database["properties"]
  prop_options_array = []
  # print the last value of properties
  properties.each do |prop|
    filter_prop_options = {
      :name => nil,
      :type => nil,
      :options => nil,
    }
    type = prop[1][:type]
    if (type == "status")
      filter_prop_options[:name] = prop[0]
      filter_prop_options[:options] = prop[1][type.to_sym][:options]
      # puts "++++++++"
      # puts "PROPERTY"
      # ap filter_prop_options
      # puts "++++++++"
      prop_options_array << filter_prop_options
      $status_options = filter_prop_options[:options].map { |option| option[:name] }

      # puts "++++++++"
      # puts "Status options:"
      # ap $status_options
      # puts "++++++++"
    end
  end
  prop_options_array
end

# Fetch all accessible databases using the search method
def fetch_databases(notion)
  results = notion.search(filter: { property: "object", value: "database" }).results

  # Filter databases with the title "Tasks"
  filtered_databases = results.select do |database|
    !!database["title"]&.dig(0, "text", "content")
  end

  $databases = filtered_databases

  # Map the filtered results to a list of hashes with name and id
  filtered_databases.map do |database|
    {
      name: database["title"]&.dig(0, "text", "content") || "Untitled Database",
      id: database["id"],
    }
  end
end

# Display a single page and allow editing
def process_page(notion, page, prompt)
  # ap page.dig("properties")
  title = page.dig("properties", "Name", "title", 0, "plain_text")
  title&.strip!
  title = "Page has no title" if title.nil?
  prompt.say("Title: #{title}", color: :green)
  url = page.dig("properties", "URL", "url")
  url&.strip!
  prompt.say("URL: #{url}", color: :green) unless url.nil?

  choice = prompt.select("Options:", %w[Edit Delete Skip Quit])
  case choice
  when "Edit"
    edit_metadata(notion, page, prompt)
  when "Delete"
    # Delete the page
    notion.update_page(
      page_id: page["id"],
      archived: true,
    )
    prompt.say("Page '#{title}' deleted!", color: :red)
  when "Quit"
    exit
  end
end

# Edit metadata for a page
def edit_metadata(notion, page, prompt)
  # Prompt the user to select a new status
  new_status = prompt.select("Select a new status:", $status_options)

  # Update the "status" property of the page
  notion.update_page(
    page_id: page["id"],
    properties: {
      "Status" => {
        "status" => { "name" => new_status },
      },
    },
  )
  prompt.say("Status updated to '#{new_status}'!", color: :green)
end

# Main program
puts "Fetching accessible databases..."
databases = fetch_databases(notion)

if databases.empty?
  puts "No accessible databases found. Please check your integration permissions."
  exit
end

# Prompt the user to select a database
database_selection = prompt.select("Select a database:", databases.map { |db| db[:name] })
database_id = databases.find { |db| db[:name] == database_selection }[:id]

# Fetch and store the status options globally
fetch_status_options(notion, database_id)

puts "Fetching pages..."
pages = fetch_pages(notion, database_id)
prompt.say("--- Let's start processing pages ---", color: :blue)
pages.each do |page|
  process_page(notion, page, prompt)
  prompt.say(" ")
  prompt.say("-- Next page --", color: :blue)
end
