require('dotenv').load()
Deferred = require('promise.coffee').Deferred
Q = require('q')
DataHelper = require('./bungie-data-helper.coffee')

dataHelper = new DataHelper

module.exports = (robot) ->
  # executes when any text is directed at the bot
  robot.respond /(.*)/i, (res) ->
    array = res.match[1].split ' '

    # trims spaces and removes empty elements in array
    input = []
    input.push el.trim() for el in array when (el.trim() isnt "")

    if input.length > 3
      message = "Something didn't look right... Read more about using the bot here:\nhttps://github.com/phillipspc/showoff/blob/master/README.md"
      sendError(robot, res, message)
      return

    data = {}

    # weapon slot should always be last input
    el = input[input.length-1].toLowerCase()
    weaponSlot = checkWeaponSlot(el)
    if weaponSlot is null
      message = "Please use 'primary', 'special', or 'heavy' for the weapon slot. Read more about using the bot here:\nhttps://github.com/phillipspc/showoff/blob/master/README.md"
      sendError(robot, res, message)
      return
    else
      data['weaponSlot'] = weaponSlot

    # interprets input based on length
    # if 3 elements, assume: gamertag, network, weaponSlot
    if input.length is 3
      el = input[1].toLowerCase()
      data['membershipType'] = checkNetwork(el)
      data['displayName'] = input[0]
    else if input.length is 2
      el = input[0].toLowerCase()
      data['membershipType'] = checkNetwork(el)
      if data['membershipType'] is null
        # assume first input was gamertag
        data['displayName'] = input[0]
      else
        # assume gamertag not provided, use slack first name
        data['displayName'] = res.message.user.slack.profile.first_name
    else if input.length is 1
      # assume only weaponSlot was provided
      data['membershipType'] = null
      data['displayName'] = res.message.user.slack.profile.first_name
    else
      # catch all, but should never happen...
      message = "Something didn't look right... Read more about using the bot here:\nhttps://github.com/phillipspc/showoff/blob/master/README.md"
      sendError(robot, res, message)
      return

    tryPlayerId(res, data.membershipType, data.displayName, robot).then (player) ->
      getCharacterId(res, player.platform, player.membershipId, robot).then (characterId) ->
        getItemIdFromSummary(res, player.platform, player.membershipId, characterId, data.weaponSlot).then (itemInstanceId) ->
          getItemDetails(res, player.platform, player.membershipId, characterId, itemInstanceId).then (item) ->
            parsedItem = dataHelper.parseItemAttachment(item)

            payload =
              message: res.message
              attachments: parsedItem

            robot.emit 'slack-attachment', payload



checkNetwork = (network) ->
  xbox = ['xbox', 'xb1', 'xbox1', 'xboxone', 'xbox360', 'xb360', 'xbone']
  playstation = ['playstation', 'ps', 'ps3', 'ps4', 'playstation3', 'playstation4']
  if network in xbox
    return '1'
  else if network in playstation
    return '2'
  else
    return null

# returns bucketHash associated with each weapon slot
checkWeaponSlot = (slot) ->
  if slot is 'primary'
    return '1498876634'
  else if slot in ['special', 'secondary']
    return '2465295065'
  else if slot is 'heay'
    return '953998645'
  else
    return null

# Sends error message as DM in slack
sendError = (robot, res, message) ->
  robot.send {room: res.message.user.name, "unfurl_media": false}, message

tryPlayerId = (res, membershipType, displayName, robot) ->
  deferred = new Deferred()
  # replaces underscores with spaces (for xbox)
  # safe to call on PSN IDs because underscores are not allowed
  displayName = displayName.split('_').join(' ')

  if membershipType
    networkName = if membershipType is '1' then 'xbox' else 'playstation'
    return getPlayerId(res, membershipType, displayName, robot)
    .then (results) ->
      if !results
        robot.send {room: res.message.user.name}, "Could not find guardian with name: #{displayName} on #{networkName}"
        deferred.reject()
        return
      deferred.resolve({platform: membershipType, membershipId: results})
      deferred.promise
  else
    return Q.all([
      getPlayerId(res, '1', displayName, robot),
      getPlayerId(res, '2', displayName, robot)
    ]).then (results) ->
      if results[0] && results[1]
        robot.send {room: res.message.user.name}, "Mutiple platforms found for: #{displayName}. use \"xbox\" or \"playstation\""
        deferred.reject()
        return
      else if results[0]
        deferred.resolve({platform: '1', membershipId: results[0]})
      else if results[1]
        deferred.resolve({platform: '2', membershipId: results[1]})
      else
        robot.send {room: res.message.user.name}, "Could not find guardian with name: #{displayName} on either platform"
        deferred.reject()
        return
      deferred.promise

# Gets general player information from a players gamertag
getPlayerId = (res, membershipType, displayName, robot) ->
  deferred = new Deferred()
  endpoint = "SearchDestinyPlayer/#{membershipType}/#{displayName}"

  makeRequest res, endpoint, (response) ->
    playerId = null
    foundData = response[0]

    if foundData
      playerId = foundData.membershipId

    deferred.resolve(playerId)
  deferred.promise

# Gets characterId for last played character
getCharacterId = (bot, membershipType, playerId, robot) ->
  deferred = new Deferred()
  endpoint = "#{membershipType}/Account/#{playerId}"

  makeRequest bot, endpoint, (response) ->
    if !response
      robot.send {room: bot.message.user.name}, "Something went wrong, no characters found for this user"
      deferred.reject()
      return

    data = response.data
    character = data.characters[0]

    characterId = character.characterBase.characterId
    deferred.resolve(characterId)

  deferred.promise

# Gets itemInstanceId from Inventory Summary based on weaponSlot
getItemIdFromSummary = (bot, membershipType, playerId, characterId, weaponSlot) ->
  deferred = new Deferred()
  endpoint = "#{membershipType}/Account/#{playerId}/Character/#{characterId}/Inventory/Summary"

  makeRequest bot, endpoint, (response) ->
    data = response.data
    items = data.items

    matchesBucketHash = (object) ->
      "#{object.bucketHash}" is weaponSlot

    item = items.filter(matchesBucketHash)
    if item.length is 0
      robot.send {room: bot.message.user.name}, "Something went wrong, couldn't find the requested item for this character."
      deferred.reject()
      return

    itemInstanceId = item[0].itemId
    deferred.resolve(itemInstanceId)

  deferred.promise

# returns item details
getItemDetails = (bot, membershipType, playerId, characterId, itemInstanceId) ->
  deferred = new Deferred()
  endpoint = "#{membershipType}/Account/#{playerId}/Character/#{characterId}/Inventory/#{itemInstanceId}"
  params = 'definitions=true'

  callback = (response) ->
    item = dataHelper.serializeFromApi(response)

    deferred.resolve(item)

  makeRequest(bot, endpoint, callback, params)
  deferred.promise

# Sends GET request from an endpoint, needs a success callback
makeRequest = (bot, endpoint, callback, params) ->
  BUNGIE_API_KEY = process.env.BUNGIE_API_KEY
  baseUrl = 'https://www.bungie.net/Platform/Destiny/'
  trailing = '/'
  queryParams = if params then '?'+params else ''
  url = baseUrl+endpoint+trailing+queryParams

  bot.http(url)
    .header('X-API-Key', BUNGIE_API_KEY)
    .get() (err, response, body) ->
      object = JSON.parse(body)
      callback(object.Response)
