request = require('request')
constants = require('./bungie-constants.coffee')

class DataHelper
  'serializeFromApi': (response) ->
    damageColor =
      Kinetic: '#d9d9d9'
      Arc: '#80b3ff'
      Solar: '#e68a00'
      Void: '#400080'
    item = response.data.item
    hash = item.itemHash
    itemDefs = response.definitions.items[hash]

    # some weapons return an empty hash for definitions.damageTypes
    if Object.keys(response.definitions.damageTypes).length isnt 0
      damageTypeName = response.definitions.damageTypes[item.damageTypeHash].damageTypeName
    else
      damageTypeName = 'Kinetic'
      console.log(Object.keys(response.definitions.damageTypes).length)
      console.log("damageType empty for #{itemDefs.itemName}")
    stats = {}
    # for stat in item.stats
    itemStats = item.stats

    if item.damageType isnt 0
      # if it's a weapon, we'll extend base stats with 

      # to expand using all the hidden stats, use the code below
      # itemStatHashes = ( "#{x.statHash}" for x in item.stats )
      # for h, s of response.definitions.items[hash].stats when h not in itemStatHashes
      #   itemStats.push s

      # to expand using a smaller list, match against EXTENDED_WEAPON_STATS
      for extHash in constants.EXTENDED_WEAPON_STATS
        s = response.definitions.items[hash].stats[extHash]
        itemStats.push s
  
    statHashes = constants.STAT_HASHES
    for stat in itemStats when stat.statHash of statHashes
        stats[statHashes[stat.statHash]] = stat.value

    prefix = 'https://www.bungie.net'
    iconSuffix = itemDefs.icon
    itemSuffix = '/en/Armory/Detail?item='+hash

    itemName: itemDefs.itemName
    itemDescription: itemDefs.itemDescription
    itemTypeName: itemDefs.itemTypeName
    color: damageColor[damageTypeName]
    iconLink: prefix + iconSuffix
    itemLink: prefix + itemSuffix
    nodes: response.data.talentNodes
    nodeDefs: response.definitions.talentGrids[item.talentGridHash].nodes
    damageType: damageTypeName
    stats: stats

  'parseItemAttachment': (item) ->
    name = "#{item.itemName}"
    name+= " [#{item.damageType}]" unless item.damageType is "Kinetic"
    filtered = @filterNodes(item.nodes, item.nodeDefs)
    textHash = @buildText(filtered, item.nodeDefs, item)
    footerText = @buildFooter(item)

    fallback: item.itemDescription
    title: name
    title_link: item.itemLink
    color: item.color
    text: (string for column, string of textHash).join('\n')
    mrkdwn_in: ["text"]
    footer: footerText
    thumb_url: item.iconLink

  # removes invalid nodes, orders according to column attribute
  'filterNodes': (nodes, nodeDefs) ->
    validNodes = []
    invalid = (node) ->
      name = nodeDefs[node.nodeIndex].steps[node.stepIndex].nodeStepName
      skip = ["Upgrade Damage", "Void Damage", "Solar Damage", "Arc Damage", "Kinetic Damage", "Ascend", "Reforge Ready", "Deactivate Chroma", "Red Chroma", "Blue Chroma", "Yellow Chroma", "White Chroma"]
      node.stateId is "Invalid" or node.hidden is true or name in skip

    validNodes.push node for node in nodes when not invalid(node)

    orderedNodes = []
    column = 0
    while orderedNodes.length < validNodes.length
      idx = 0
      while idx < validNodes.length
        node = validNodes[idx]
        nodeColumn = nodeDefs[node.nodeIndex].column
        orderedNodes.push(node) if nodeColumn is column
        idx++
      column++
    return orderedNodes

  'buildText': (nodes, nodeDefs, item) ->
    getName = (node) ->
      step = nodeDefs[node.nodeIndex].steps[node.stepIndex]
      return step.nodeStepName

    text = {}
    setText = (node) ->
      step = nodeDefs[node.nodeIndex].steps[node.stepIndex]
      column = nodeDefs[node.nodeIndex].column
      name = step.nodeStepName
      if node.isActivated
        name = "*#{step.nodeStepName}*"
      text[column] = "" unless text[column]
      text[column] += (if text[column] then ' | ' else '') + name

    setText node for node in nodes
    return text 

  # stats go in the footer
  'buildFooter': (item) ->
    stats = []
    for statName, statValue of item.stats
        stats.push "#{statName}: #{statValue}"
    stats.join ', '

module.exports = DataHelper
