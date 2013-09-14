parse_oncall.rb
===============

This script parses on-call calendars in iCal format, and generates corresponding Nagios timeperiods. Timeperiods are only generated for valid Nagios contacts, defined in 'contacts'. This works with static ics, as well as remote calendars like Zimbra or Google Calendar.

The script assumes you have a template file containing other timeperiod information, and appends the on-call dates/times to individual's on_call timeperiod. Sample template is included.

**NOTE:**
You must configure your calendar entry to have an 'attendee' matching the nagios contact name. So, if you want to modify the on-call schedule for a contact named 'sedgar', you must add 'sedgar@yourdomain.com' as an 'attendee' for that particular calendar event.

Example of file created...

timeperiods.cfg:
```
define timeperiod{
    timeperiod_name         sedgar_on_call
    2013-07-13 - 2013-07-21  10:00-22:00  # grabbed from the calendar
    2013-06-09 - 2013-06-18  10:00-22:00  # grabbed from the calendar
    use                     na_workhours
}
define timeperiod{
    timeperiod_name         acosta_on_call # nothing in the calendar for this contact
    use                     na_workhours
}
define timeperiod{
    timeperiod_name         abourne_on_call
    2013-05-13 - 2013-05-14  00:00-24:00   # grabbed from the calendar
    use                     na_workhours
}
```

Using the resulting file as a nagios timeperiod config, we can set each contact to only receive notifications during their workhours + on-call hours.

contacts.cfg:
```
define contact{
        name                            sedgar
        alias                           Stefanie Forrester
        use                             default-contact
        host_notification_period        sedgar_on_call
        service_notification_period     sedgar_on_call
        pager                           
        email                           
        contactgroups                   admins
        }

define contact{
        contact_name                    sedgar
        use                             sedgar
        }

# escalations allow the contact to receive notifications 24x7 when needed
define contact{
        contact_name                    sedgar_esc
        use                             sedgar
        contactgroups                   admins_esc
        host_notification_period        24x7
        service_notification_period     24x7
        }
```
