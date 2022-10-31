local addonName, addonTable = ...
--[[                                                                                      ]]-- Max Length of a line is within the brackets.
addonTable.ChangelogText = [[

{h3:c} See the User Guide for more help on how to use Arcanum.{/h3}
{h3:c} [Link - Builder's Haven Discord Guide](https://discord.com/channels/718813797611208788/1031832007031930880/1032773498600439898) - [Link - Epsilon Forums Guide](https://forums.epsilonwow.net/topic/3413-addon-arcanum-spell-forge-user-guide/) {/h3}

{h1:c} Changelog {/h1}
{h2:c} __________________________________________________________ {/h2}
##v1.1.0 (October 31st, 2022)

### - NEW: Add to Gossip Menu Button & UI
      - Phase Vault now has direct integration for adding an ArcSpell to a Gossip Menu!
            With a Gossip Menu open, click on the 'head with a speech bubble' icon!
            Gossip editing requires Officer+.

### - NEW: Private ArcSpells in Phase Vault!
      - ArcSpells uploaded to the Phase Vault can now be marked as private.
        Private spells will only show in the vault for Officers+. Players
        will still be able to use private spells from Integrations (i.e., Gossip).

           - Spell visibility (Private vs Public) is represented by the eye-con on 
             each spell row in the Phase Vault. Spells must be re-uploaded to change
             their visibility.

### - UPDATED: Forge UI
      - The |cff59cdea+|r / |cffED4245—|r buttons to add/remove rows have been moved into the UI!
            - Individual Rows can now be deleted, not just the last row.
            - NOTE: You cannot restore a deleted row once deleted, unless you
              manually re-create it, or reload the spell from your vault.
      - A new "Clear & Reset UI" button has been added! If the animation is too slow,
        you can toggle 'Fast Reset' in the options menu.

### - UPDATED: Transfer to Personal Vault Button added.
      - This should make it easier and more intuitive to transfer spells to
        your personal vault

### - RE-WORKED: Gossip Integration has been re-implemented.
      - The new implementation was needed for supporting...
        - NEW: Add to Gossip button/UI for ArcSpells in the Phase Vault, noted above!
        - NEW: You can now add Gossip tags to Gossip Text to run those actions
              automatically. This replaces '_auto' tags in gossip options.
        - NEW: 
        - CHANGED: Gossip tags can be shortened to <arc_ for text limit purposes. 
              Both "<arc_ ... >" and "<arcanum_ ... >" will work.
        - CHANGED: <arcanum_auto> & <arcanum_toggle> are now just <arcanum_show>.
              Auto vs On Click now depend on if you use it in Text or Option.
        - CHANGED: Auto tag removed as a tag extension. See above 'NEW' also.
            - Old tags will still function for legacy, but you should be
              using <arcanum_cast_(hide):spell> in '.ph fo np go text add' 
              instead now.

### - NEW: ARC.API - A pseudo API to make scripting in ArcSpells easier.
      Functions:
            ARC:COMM("command")    -- Sends a server command.
            ARC:COPY("text / link")      -- Open a Dialog box to Copy the text/link
            ARC:GETNAME()       -- Returns the Target's into chat. Try it on a MogIt NPC.
            ARC:CAST("commID")         -- Casts an ArcSpell from your Personal Vault
            ARC:CASTP("commID")       -- Casts an ArcSpell from the Phase Vault

            ARC:IF("ArcVar", [trueCommand, falseCommand], [var1])
                -- Checks if the ArcVar is true. If true & false command provided, runs the
                    command depending the ArcVar. If no commands provided, returns true if
                    the ArcVar is true, or false if not. If Var1 provided, it will append the
                    var to the true & false command, allowing shorter writen functions.

            ARC:IFS("ArcVar", "value", [trueCommand, falseCommand], [var1])
                -- Works similar to ARC:IF but checks if the ArcVar matches the "value".
                    i.e., ARC:IFS("WhatFruit","Apple") checks if WhatFruit = Apple.

            ARC:TOG("ArcVar")             -- Toggles an ArcVar between True & False.
            ARC:SET("ArcVar", "value")  -- Sets an ArcVar to the specificed "value".
            ARC:GET("ArcVar")           -- Returns the value of an ArcVar. Needs embeded.

            Please see the User Guide for more information on the ARC.API, or use `/arc`.
            Frequent ARC.API functions can also be ran using a more friendly slash command,
            but are limited in that you cannot use spaces in the vars or commands.
                /arc cast $commID -- Cast Personal ArcSpell (accepts spaces)
                /arc castp $commID -- Cast Phase ArcSpell (accepts spaces)
                /arc cmd $serverCommand (i.e, /arc cmd cheat fly) (accepts spaces)
                /arc getname -- Prints your taget's name in your chatbox (Try on a MogIt NPC!)
                /arc copy $text/link -- Open a box to copy the text/link (accepts spaces)
                /arc tog $ArcVar -- (no spaces)
                /arc set $ArcVar $value -- (no spaces)
                /arc if $ArcVar $trueCommand $falseCommand $trueVar $flaseVar -- (no spaces)
                  - ex: /arc if ToggleTorch aura unaura 1234 all
                  - Casts aura 1234 if ToggleTorch is true, or unaura all if false.
                  - You can leave off $falseVar and $trueVar will be used for both true & false.

      NOTE: ArcVars exist in a global table, "ARC.VAR". You can access them directly if you
            understand Lua & know what you're doing. 

            ArcVars are |cffED4245NOT SAVED|r between sessions. Persistent Vars may come in the
            future if  the need is there, but they won't be secure. If you think of a good use
            for them, let me know and I can push it up higher on the to-do list.

### - NEW: Changelogs are now documented in-game in the Settings panel.
           Along with Links to the User Guide on Discord & the forums!

### - BUG FIXES:
        - Slash /Command & Server .Command actions no longer break when a comma is present.
                - That said, Slash & Server actions no longer support comma multi-actions.

{h2:c} __________________________________________________________ {/h2}
##v1.0.0 (October 20th, 2022)

- Released! 

{h2:c} __________________________________________________________ {/h2}
{h1:c} Credits {/h1}
Artwork by T ( |cff5865F2AJT#0715|r )
Code by MindScape ( |cff5865F2MindScape#0332|r )

Thank you to Azarchius & Razmatas for Epsilon Core, Executable, and Server support

### |cff57F287And thank YOU, the players of Epsilon, for being the drive behind this server, community, and the amazing things you have, and will, create.|r 
{h2:c} __________________________________________________________ {/h2}
]]


--[[ Blank Space for Tabbing : Copy this : ' ' ]]