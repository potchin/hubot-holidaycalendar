hubot-holidaycalendar
=================

# Description:
   Bot which can load your office holiday/vacation days from an iCal calendar URL. 
   Easily find out who is on vacation. Accepts human-readable relative days (like tomorrow, next monday etc)

# Configuration:
   HUBOT_HOLIDAYCALENDAR_ICAL_URL - url of ical file containing your holidays

# Commands:
   hubot "holidays|off work|vacation" - List people who are off today
   hubot "holidays tomorrow" - List people who are off tomorrow
   hubot "holidays friday" - List people who are off friday this week
   hubot "holidays next friday" - List people who are friday next week
   hubot "holidays next week" - List people who are off tomorrow




# Credits
forked and hacked from  coderofsalvation/hubot-script-ical

credits go to igui since I extracted this functionality from [his repo](https://github.com/igui/cubot-hipchat) and turned it into a module.
