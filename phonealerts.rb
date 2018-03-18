#!/usr/bin/env ruby

require "uri"
require 'json'a
require 'slack-notifier'

oauth=`curl -H "Content-Type: application/x-www-form-urlencoded" -X POST "https://XXX.com/v0/oauth2/token" -d "grant_type=client_credentials&client_id=[CLIENTID]&client_secret=[CLIENTSECRET]M=" | grep access_token | awk -F"," '{print $1}' | tr -d ' ' | sed  's/"//g' | sed 's/{access_token://g'`

uksupport=`curl -X GET "https://XXX.com/v0/[CLIENTID]/agents/?availability=readyForPhoneCall&groups=[GROUPID]]" -H "Authorization: Bearer "#{oauth}"" -H "Accept: application/json"`

# Lookup the number of agents logged into a spesific call group set in ContactWorld

jdocsupport = JSON.parse(uksupport)
notificationMethoduksupport = jdocsupport.fetch("count")
puts notificationMethoduksupport

uksupportavailability = notificationMethoduksupport

# Script to check if there are any available agents logged into phone system, if not it will post to an incomming webhook created in Slack Apps

if uksupportavailability < 1 then
  puts "There are currently no agents available on the UK support phone call group. Please ask agents to login to NVM"
 notifier = Slack::Notifier.new "https://hooks.slack.com/services/XXXX/XXXX/XXXXXX", channel: '#support_notifications',  username: 'phone-availability-alert'
  notifier.ping "[PHONE ALERT]\n\nThere are currently #{uksupportavailability} available agents in the UK support phone group. \n\nPlease get someone from your team to login to NVM"

end

# You then setup a cron job on the server to call this script for the frequency required
