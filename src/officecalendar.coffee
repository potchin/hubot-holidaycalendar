# Description:
#   Bot which can load your office holiday/vacation days from an iCal calendar URL. 
#   Easily find out who is on vacation. Accepts human-readable relative days (like tomorrow, next monday etc)
#
# Configuration:
#   HUBOT_HOLIDAYCALENDAR_ICAL_URL - url of ical file containing your holidays
#
# Commands:
#   hubot "holidays|off work|vacation" - List people who are off today
#   hubot "holidays tomorrow" - List people who are off tomorrow
#   hubot "holidays friday" - List people who are off friday this week
#   hubot "holidays next friday" - List people who are friday next week
#   hubot "holidays next week" - List people who are off tomorrow
#
# Author:
#   Jeff Sault (jeff.sault@smartpipesolutions.com)
#
module.exports = (robot) ->
  robot.respond /(?:holidays|off work|vacation)(.*)/i, (msg) ->
    fuzzywhentolook = "today"
    whentolook = new Date()
    if msg.match[1]
      fuzzywhentolook = msg.match[1].trim()
      daysofweek = ["sunday","monday","tuesday","wednesday","thursday","friday","saturday"]
      #this function takes a day of week and optional number of weeks
      #it returns a date object for the result. defaults to next week
      Date::getNextWeekDay = (d, w=1) ->
        if d
          next = this
          next.setDate @getDate() - @getDay() + (w*7) + d
          return next
        return

      if fuzzywhentolook == 'today'
        #not really needed
        whentolook = new Date()
      else if fuzzywhentolook == 'tomorrow'
        whentolook = whentolook.setDate(whentolook.getDate() + 1);
      else if fuzzywhentolook == 'yesterday'
        whentolook = whentolook.setDate(whentolook.getDate() - 1);
      else if fuzzywhentolook == 'next week'
        now = new Date()
        whentolook = now.getNextWeekDay(1)
        now = new Date()
        whentolookend = now.getNextWeekDay(5)
      else if fuzzywhentolook.substring(0, 5) == "next "
        wantedday = fuzzywhentolook.replace /next /, ""
        wanteddaynum = daysofweek.indexOf(wantedday.toLowerCase());
        now = new Date()
        whentolook = now.getNextWeekDay(wanteddaynum)
      else if fuzzywhentolook.toLowerCase() in daysofweek
        wanteddaynum = daysofweek.indexOf(fuzzywhentolook.toLowerCase());
        now = new Date()
        whentolook = now.getNextWeekDay(wanteddaynum,0)
      else
        msg.send "No idea when #{fuzzywhentolook} is. Sorry!"
        return

    if not whentolookend?
      console.log "Setting end date same as start date"
      whentolookend = whentolook
    console.log "Looking for events from #{new Date(whentolook).toDateString()} to #{new Date(whentolookend).toDateString()}" 

    ical = require('ical')
    verbiage = []
    ical.fromURL process.env.HUBOT_HOLIDAYCALENDAR_ICAL_URL, {}, (err, data) ->
      for k, v of data
        if data.hasOwnProperty(k)
          eventlist = data[k]
          for cal of data
            for _, event of data[cal]
              if event.type == 'VEVENT'
                eventstartdate = new Date(event.start)
                eventenddate = new Date(event.end)

                if (eventstartdate < whentolook and eventenddate > whentolookend) \
                or (eventstartdate > whentolook and eventstartdate < whentolookend) \
                or (eventenddate > whentolook and eventenddate < whentolookend)
                  verbiage.push "\t\t#{event.summary} from #{new Date(event.start).toDateString()}, returning on #{new Date(event.end).toDateString()}"

      if verbiage.length > 0
        msg.send "Holidays #{fuzzywhentolook} (#{new Date(whentolook).toDateString()} to #{new Date(whentolookend).toDateString()})\n"+verbiage.join("\n")
      else
        msg.send "No holidays found for #{fuzzywhentolook} (#{new Date(whentolook).toDateString()} to #{new Date(whentolookend).toDateString()})"


# This is what an event looks like... 
# 'c6381ae2-42b1-42ac-aeb1-0271f8197665': 
#  { type: 'VEVENT',
#    params: [],
#    description: 'Created By : someone',
#    end: { 2017-06-09T23:00:00.000Z tz: undefined },
#    dtstamp: '20170724T141449Z',
#    start: { 2017-06-08T23:00:00.000Z tz: undefined },
#    sequence: '0',
#    summary: 'bah - Holiday',
#    uid: 'c6381ae2-42b1-42ac-aeb1-0271f8197665' },