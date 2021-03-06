require 'open-uri'

namespace :fifa do
  desc "scrape events from FIFA site"
  task get_all_events: :environment do
    FIFA_SITE = "https://www.fifa.com/"
    MATCH_URL = FIFA_SITE + "worldcup/matches/index.html"
    matches = Nokogiri::HTML(open(MATCH_URL))
    matches.css(".fixture").each do |match|
      fifa_id = match.first[1] #get unique fifa_id
      #get game events
      url = match.children[0]['href']
      puts url
      next if url == nil
      datetime = match.css(".mu-i-datetime").text
      next unless datetime.to_time.beginning_of_day == Time.now.beginning_of_day
      match_info_page = Nokogiri::HTML(open(FIFA_SITE+url))
      home_events =  []
      away_events = []
      match_info_page.css("td.home").css(".event").each do |event|
        event_type = event.attributes["class"].value.gsub("event ","")
        player = event.parent.parent.parent.css('.p-n').text.mb_chars.downcase.to_s.titlecase
        time = event.attributes["title"].value.gsub(/[^0-9]/, '')
        event_hash = event.attributes["data-guid"].value
        if event_type.downcase.include?("substitution-out")
          event_hash += "out"
        end
        home_events << [event_hash, player, event_type, time]
      end
      match_info_page.css("td.away").css(".event").each do |event|
        event_type = event.attributes["class"].value.gsub("event ","")
        player = event.parent.parent.parent.css('.p-n').text.titlecase
        time = event.attributes["title"].value.gsub(/[^\d^+]/, '')
        event_hash = event.attributes["data-guid"].value
        if event_type.downcase.include?("substitution-out")
          event_hash += "out"
        end
        away_events << [event_hash, player, event_type, time]
      end
      match = Match.find_by_fifa_id(fifa_id)
      next unless match
      home_events.each do |event_array|
        event = Event.find_or_create_by_fifa_id(event_array[0])
        event.player = event_array[1]
        event.type_of_event = event_array[2]
        event.time = event_array[3]
        event.match_id = match.id
        event.team_id = match.home_team.id
        event.save
      end

      away_events.each do |event_array|
        event = Event.find_or_create_by_fifa_id(event_array[0])
        event.player = event_array[1]
        event.type_of_event = event_array[2]
        event.time = event_array[3]
        event.match_id = match.id
        event.team_id = match.away_team.id
        event.save
      end
    end
  end
end
