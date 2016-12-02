# Showoff (aka Gunsmith Bot)

Showoff is a slack bot based on the [hubot](https://hubot.github.com/) framework, designed to make it easy for users to show off their Destiny weapons **(and now armor!)** in slack. The goal is to enable users to share weapon information with as few inputs as possible.  
This project was originally based off of [slack-destiny-bot](https://github.com/cprater/slack-destiny-bot).

### Usage

Showoff only requires at most 3 inputs, directed at the bot (order does matter):  
* XBL/PSN gamertag
* console network ("xbox" or "playstation")
* weapon slot ("primary", "special", "heavy")

If armor is enabled, it can be shown with: "head", "chest", "arms", "legs", "class", "ghost".

The standard usage looks like this:  
`@bot-name MyGamertag xbox primary`

with a response looking like (active nodes in bold):  
![image](https://cloud.githubusercontent.com/assets/11082871/20840640/eb0f6e36-b87e-11e6-9646-06f1c7655e99.png)
Showoff automatically looks at **your most recently played character** when grabbing the weapon data.

### Advanced Options
If your slack profile's **first name** (not username) matches your gamertag, you can omit this entirely.  
`@bot-name xbox special`  

If you don't include a console network, showoff will automatically search both.  
`@bot-name MyGamertag heavy`

Note that if the gamertag exists on both networks, this will not work.  

Combining these options, the bot will pull your slack first name, and search both networks for the specified weapon with a single input.  
`@bot-name primary`

### Testing it out
If you want to test out the bot before using it in a public channel, try sending it a direct message. You do not need "@bot-name" when you are messaging the bot directly, just the inputs.

### Caveats
* Xbox users must use an underscore ( _ ) for any spaces in their gamertag when inputting it directly. This is not necessary in the first name field of your slack profile; spaces will work fine.
* As stated above, Showoff automatically looks at your most recently played character. This was ultimately an intentional decision to limit the number of inputs needed and simplify using the bot.

### Setting up the bot in your own slack
First clone the repo locally:  
`git clone git@github.com:phillipspc/showoff.git`

To deploy to heroku, `cd` into the newly created folder then follow these steps:

- Install [heroku toolbelt](https://toolbelt.heroku.com/) if you haven't already.
- Activate the Hubot service on your ["Team Services"](http://my.slack.com/services/new/hubot) page inside Slack.
- `heroku create my-new-slackbot`
- `heroku addons:create rediscloud:30`
- `git push heroku master`

You'll need to add the following [config variables](https://devcenter.heroku.com/articles/config-vars) (easiest way is through the Heroku Dashboard). [Get a Bungie API key](https://www.bungie.net/en/Application)

`HEROKU_URL=https://my-new-slackbot.herokuapp.com`  
`HUBOT_SLACK_TOKEN=your-slack-token-here`  
`BUNGIE_API_KEY=your-bungie-key-here`

By default, the bot can show weapons AND armor. To restrict to just weapons, use the variable:  
`SHOW_ARMOR=false`
