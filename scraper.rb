require 'scraperwiki'
require 'rubygems'
require 'mechanize'

starting_url = 'http://portal.pittwater.nsw.gov.au/Pages/XC.Track/SearchApplication.aspx?d=thismonth&k=LodgementDate&t=DevelopApp,S96Mod'
comment_url = 'mailto:pittwater_council@pittwater.nsw.gov.au?subject='
require 'pry'
def clean_whitespace(a)
  a.gsub("\r", ' ').gsub("\n", ' ').squeeze(" ").strip
end

def extract_addresses!(bits)
  addresses = []
  bits.each_with_index do |line, index|
    if /\r\n\t\t\t\t\t\t\t\tAddress:\r\n\t\t\t\t\t\t\t\t <strong>(.*)<\/strong>/.match(line) 
      addresses << clean_whitespace(line.match(/<strong>(.*)<\/strong>/)[1])
      bits.delete_at(index)
    end
  end
  addresses
end

def extract_date!(bits)
  date  = nil
  bits.each_with_index do |line, index|
    if /(\d\d)\/(\d\d)\/(\d\d\d\d)/.match(line)
      m = line.match(/(\d\d)\/(\d\d)\/(\d\d\d\d)/)
      date = Date.new(m[3].to_i, m[2].to_i, m[1].to_i).to_s

      bits.delete_at(index)
    end
  end
  date
end

def scrape_table(doc, comment_url)

  doc.search('.result')[1..-1].each do |tr|
    bits = tr.to_s.split("<br>")
    addresses = extract_addresses!(bits) # modifies bits to remove address lines from array 
    date_received = extract_date!(bits)

    record = {
      'info_url' => (doc.uri + tr.at('a')['href']).to_s,
      'council_reference' => clean_whitespace(tr.at('a').inner_text),
      'date_received' => date_received,
      'address' => addresses.first,
      'description' => clean_whitespace(bits[1]),
      'date_scraped' => Date.today.to_s
    }
    record["comment_url"] = comment_url + CGI::escape("Development Application Enquiry: " + record["council_reference"])

    # p record
    if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
      ScraperWiki.save_sqlite(['council_reference'], record)
    else
      puts "Skipping already saved record " + record['council_reference']
    end
  end
end

agent = Mechanize.new

# Yay, no bollocks agree screen - well done Pittwater!
doc = agent.get(starting_url)

scrape_table(doc, comment_url)
