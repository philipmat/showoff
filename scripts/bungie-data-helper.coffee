request = require('request')

class DataHelper
  statHashes = 
    "2391494160": "Light" 
    "2523465841": "Velocity" 
    "2715839340": "Recoil direction" 
    "2762071195": "Efficiency" 
    "2837207746": "Speed" 
    "2961396640": "Charge Rate" 
    "2996146975": "Agility" 
    "3017642079": "Boost" 
    "3555269338": "Optics" 
    "3597844532": "Precision Damage" 
    "3614673599": "Blast Radius" 
    "3871231066": "Magazine" 
    "3897883278": "Defense" 
    "3907551967": "Move speed" 
    "3988418950": "ADS Speed" 
    "4043523819": "Impact" 
    "4188031367": "Reload" 
    "4244567218": "Strength" 
    "4284893193": "Rate of Fire" 
    "144602215": "Intellect" 
    "155624089": "Stability" 
    "209426660": "Defense" 
    "360359141": "Durability" 
    "368428387": "Attack" 
    "392767087": "Armor" 
    "925767036": "Energy" 
    "943549884": "Equip Speed" 
    "1240592695": "Range" 
    "1345609583": "Aim assistance" 
    "1501155019": "Speed" 
    "1735777505": "Discipline" 
    "1931675084": "Inventory Size" 
    "1943323491": "Recovery" 

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
    itemStats = if item.damageType == 0 then item.stats else response.definitions.items[hash].stats
    for statHash, stat of itemStats
      if stat.statHash of statHashes
        stats[statHashes[stat.statHash]] = stat.value

    prefix = 'http://www.bungie.net'
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
