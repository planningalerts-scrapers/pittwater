require 'scraperwiki'
require 'rubygems'
require 'mechanize'

starting_url = 'http://portal.pittwater.nsw.gov.au/Pages/XC.Track/SearchApplication.aspx?d=thismonth&k=LodgementDate&t=DevelopApp,S96Mod'
comment_url = 'mailto:pittwater_council@pittwater.nsw.gov.au?subject='

def clean_whitespace(a)
  a.gsub("\r", ' ').gsub("\n", ' ').squeeze(" ").strip
end

def scrape_table(doc, comment_url)

  doc.search('.result')[1..-1].each do |tr|
    bits = tr.to_s.split("<br>")

    m = bits[4].match(/(\d\d)\/(\d\d)\/(\d\d\d\d)/)
    date_received = Date.new(m[3].to_i, m[2].to_i, m[1].to_i).to_s
    record = {
      'info_url' => (doc.uri + tr.at('a')['href']).to_s,
      'council_reference' => clean_whitespace(tr.at('a').inner_text),
      'date_received' => date_received,
      'address' => clean_whitespace(bits[2].match(/<strong>(.*)<\/strong>/)[1]),
      'description' => clean_whitespace(bits[1]),
      'date_scraped' => Date.today.to_s
    }
    record["comment_url"] = comment_url + CGI::escape("Development Application Enquiry: " + record["council_reference"])

    #p record
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
