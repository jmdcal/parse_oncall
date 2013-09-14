#!/usr/bin/env ruby
# Stefanie Forrester 
# Sept 13 2013 
#
# parse_oncall.rb
# A script to parse on-call calendars in iCal format, and generate corresponding Nagios timeperiods.
# Only generates timeperiods for valid Nagios contacts, defined in 'contacts'.
require "rubygems"
require "ri_cal"
require "open-uri"

# cfengine/cfgen stuff... replace with your own configuration management variables, if needed
#@@EVAL
#cfprint "contacts = %w[";
#foreach $contact ( keys %nagios_contacts ) {
#        cfprint $contact;
#        cfprint " ";
#}
#cfprint "]";
#@@NOEVAL

# sample data, since cfengine wont generate this until we apply it to the host
contacts = %w[sedgar acosta abourne]

# Generate the schedule hash using cfengine contacts.
# The hash will look like this:
# schedule = { sedgar => ["2013-09-12  10:00-22:00", "2013-09-13  10:00-22:00"],
#              acosta => ["2013-09-14  10:00-22:00", "2013-09-15  10:00-22:00"]
#            }
schedule = Hash.new
contacts.each{|x| schedule[x] = [] }

#open("https://my.zimbra.server/home/username/calendar?fmt=ics&tz=UTC", "r") do |file|
File.open("mycalendar.ics", "r") do |file|
    calendar = RiCal.parse(file)
    calendar.each do |cal|
        cal.events.each do |event|
          
            # if no end date exists, skip everything  
            who = event.attendee.to_s

            unless who.empty?
                person = who.match(/mailto:(.*)@/)[1]

                # 'person' must match one of our defined nagios contacts
                if contacts.grep(person).any?
                   contact = contacts.grep(person).to_s 

                   # don't bother with never-ending events
                   unless event.dtend.to_s.empty?
                       startdate = event.dtstart.strftime("%Y-%m-%d")
                       enddate = event.dtend.strftime("%Y-%m-%d")
                       starttime = event.dtstart.strftime("%R")
                       endtime = event.dtend.strftime("%R")

                       # nagios timeperiod formatting, to be associated with this contact
                       nagtime = "#{startdate} - #{enddate}  #{starttime}-#{endtime}"

                       # append to the list of on-call dates for a particular contact
                       (schedule[contact] ||= []) << nagtime
                   end
                end
            end
        end
    end
end

#debug
#puts schedule.inspect

# Delete old timeperiods.cfg, and create a new one. 
# Since this file is entirely managed by this script, it's safe to regenerate from scratch.
# Using the template + output generated in this script, 
# we'll create a new nagios config for our on-call timeperiods.

newfile = File.open('timeperiods.cfg', 'w') 

# timeperiods-template.cfg already exists, and contains data such as timeperiod templates (defining workhours in various regions).
# It also contains contact-specific timeperiods, such as 'sedgar_on_call', which define what time zone the contact is in.
# We'll be using those templates to create the actual config that nagios uses.
template = File.open('timeperiods-template.cfg', 'r')
template.readlines.each do |line|
    newfile.puts line

    # insert on-call schedules for each contact
    contacts.each do |contact|
        if line.match(/(\s*)timeperiod_name(\s*)#{contact}_on_call/)
            schedule[contact].each { |entry| newfile.puts "    #{entry}" } 
        end
    end
end
