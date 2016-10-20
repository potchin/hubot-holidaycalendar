# Description:
#   Bot which can load your office holiday/vacation days from an iCal calendar URL. Easily find out who is on vacation today
#
# Configuration:
#   HUBOT_HOLIDAYCALENDAR_POLLING_TIME - how often to refresh calendar info (mins)
#   HUBOT_HOLIDAYCALENDAR_ICAL_URL - url of ical file containing your holidays
#
# Commands:
#   hubot "holiday|off today|vacation" - List people who are off today
#
# Author:
#   Jeff Sault (jeff.sault@smartpipesolutions.com)
#
ical = require 'ical'
request = require 'request'


class HolidayCalendar
  constructor: (@robot) ->
    self = this

    # Set a room info from an URL and ICS data
    @setRoomFromIcs = (url, data) ->
      ics = ical.parseICS(data)
      events = []
      for cal of ics
        for _, event of ics[cal]
          if event.type == 'VEVENT'
            starts = new Date(event.start).getTime()
            ends = new Date(event.end).getTime()
            events.push {
              title: event.summary, starts: starts, ends: ends
            }

      self.calendars[0] = { url: url, events: events }

    @refreshCalendar = ->
      calendar_list = self.get()
      for cal, item of calendar_list
        robot.logger.debug("Refreshing calendar: #{cal}")
        request({uri: item.url}, (err, resp, data) ->
          if !err && resp.statusCode == 200
            self.setRoomFromIcs(item.url, data)
        )

    # Map room_name -> { url, events }
    @calendars = {}

    @options = {
      # pooling time between refreshes (milliseconds)
      calchanges_pooling_time: process.env.HUBOT_HOLIDAYCALENDAR_POLLING_TIME or 60 * 1000 * 60
    }

    # load previously loaded calendars from brain (removes current calendars :p)
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.calendars
        @calendars = @robot.brain.data.calendars
      else
        @robot.brain.data.calendars = @calendars

    # checks for changes for each assigned calendar
    setInterval(@refreshCalendar, @options.calchanges_pooling_time)

  # Sets new iCalendar URL for some room and notifies new events in the room
  set: (url) ->
    cals = @calendars
    self = this
    request({uri:url}, (err, resp, data) ->
      if err
        throw err;
      if resp.statusCode != 200
        throw "Error retrieving url with code #{resp.statusCode}"
      self.setRoomFromIcs(url, data)
    )

  clear: (room) ->
    delete @calendars[room]

  get: ->
    res = []
    for room, room_info of @calendars
      res.push { room: room, url: room_info.url, events: room_info.events }
    return res

module.exports = (robot) ->
  calendar = new HolidayCalendar robot
  try
    calendar.set(process.env.HUBOT_HOLIDAYCALENDAR_ICAL_URL)
  catch error
    robot.logger.error("Error retrieving iCalendar: #{error}")
    return

  robot.respond /.*(?:holiday|off today|vacation).*/i, (msg) ->
    calendar_list = calendar.get()
    if calendar_list.length == 0
      msg.send "No calendars set"
      return
    verbiage = []
    for cal, item of calendar_list
      for ev in item.events
        eventstartdate = new Date(ev.starts)
        eventenddate = new Date(ev.ends)
        now = new Date()
        if eventstartdate < now and eventenddate > now
          verbiage.push "\t\t#{ev.title} from #{new Date(ev.starts).toDateString()}, returning on #{new Date(ev.ends).toDateString()}"
    if verbiage
      msg.send "Holidays today: \n"+verbiage.join("\n")
    else
      msg.send "No holidays found for today"
