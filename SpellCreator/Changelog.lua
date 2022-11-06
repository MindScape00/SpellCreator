local addonName, addonTable = ...
--[[                                                                                      ]]-- Max Length of a line is within the brackets.
addonTable.ChangelogText = [[

{h3:c} See the User Guide for more help on how to use Arcanum.{/h3}
{h3:c} [Link - Builder's Haven Discord Guide](https://discord.com/channels/718813797611208788/1031832007031930880/1032773498600439898) - [Link - Epsilon Forums Guide](https://forums.epsilonwow.net/topic/3413-addon-arcanum-spell-forge-user-guide/) {/h3}

{h1:c} Changelog {/h1}
{h2:c} __________________________________________________________ {/h2}
##v1.1.0 (November 7th, 2022)

### - Spell Forge UI Updates
    - The |cff59cdea+|r / |cffED4245—|r buttons to add/remove rows have been moved into the UI!
          - You can now delete any row directly, and add a row above any other row, by
              mousing over the row and using it's contextual |cff59cdea+|r / |cffED4245—|r buttons.

    - A new "Clear & Reset UI" button has been added! If the animation is too slow for
        you, you can toggle 'Fast Reset' in the Arcanum options menu.

    - The Revert Checkbox was killed. Now it's just Revert Delay - Simpler to use, and
        allows more room for the input box, which is also now bigger! If there is no
        revert delay, then it will not revert. Why need a checkbox?
           (BONUS: Toggle the input box EVEN BIGGER in the Arcanum Options Menu!)

### - Vault Overhaul!
    - All Vaults:
        - You can now right-click an ArcSpell in the vault to get a context menu
            to access some frequent actions, and some of the new features!

    - Personal Vault:
        - You can now assign ArcSpells to a profile, and filter to only show specific
            profiles. New ArcSpells are assigned to your character's profile.
            This should help make it easier if you have lots of ArcSpells in your vault!

            - Assign a Profile: Right-Click the ArcSpell in the Vault!
            - Change Profile Filter: Left-Click the double-head icon in the top right. 
            - Change Default Filter: Right-Click the double-head icon in the top right.

        - You can now Import & Export ArcSpells from the game, to share externally.
            - To Export: Right-Click the ArcSpell and click Export, then copy the code.
            - To Import: Click the yellow up-arrow in the bottom left of the Vault.

    - Phase Vault:
        - You can now upload ArcSpells to the Phase Vault as 'Private'.
            - Private spells will only show in the vault for Officers+. Players
              will still be able to use private spells linked from Gossip menus.

        - Spell visibility (Private vs Public) is represented by the eye-con on 
            each spell row in the Phase Vault. Spells must be re-uploaded to change
            their visibility.

        - Transfer to Personal Vault button added. No more 'Edit -> Create' needed!

### - Gossip Integration Overhaul!
    - All Gossip Integrations have been completely rewriten / reintegrated.
          Please see below for a list of all major changes.

    - Phase Vault now has direct integration for adding an ArcSpell to a Gossip Menu!
        - With a Gossip Menu open, click on the 'head with a speech bubble' icon, or
            right-click an ArcSpell! Gossip editing requires Officer+.

### - IMPORTANT: Gossip Integration Changes
    - NEW: Add to Gossip button/UI for ArcSpells in the Phase Vault, noted above!
        - Just use that instead of learning this stuff!
    - NEW/CHANGED: You can now add Gossip tags to Gossip Text to run those actions
          automatically. This replaces '_auto' tags in gossip options.
    - CHANGED: Gossip tags can be shortened to <arc_ for text limit purposes. 
          Both "<arc_ ... >" and "<arcanum_ ... >" will work.
    - CHANGED: <arcanum_auto> & <arcanum_toggle> are now just <arcanum_show>.
          Auto vs On Click now depend on if you use it in Text or Option.
    - CHANGED: Auto tag removed as a tag extension. See above 'NEW' also.
        - Old tags will still function for legacy, but you should be
          using <arcanum_cast_(hide):spell> in '.ph fo np go text add' 
          instead now. I cannot gaurantee new tags with _auto will work..

    - VALID TAGS:
            |cffFFA500<arc_show>|r -- Opens the Spell Forge UI
            |cffFFA500<arc_cast: ..commID >|r -- Casts the (commID) from the Phase Vault
            |cffFFA500<arc_save: ..commID >|r -- Saves the (commID) from Phase -> Personal Vault
            |cffFFA500<arc_cmd: ..server command >|r -- Executes the server command given
            |cffFFA500<arc_macro: ..slash command >|r -- Executes the macro-script given
                Macro Script can be used in combination with ARC:API as well.

       - Tag Extensions: ( added to the end of a tag, before the :command )
            |cffFFA500_hide|r -- Hides the Gossip UI after executing the tag's function.
                    Example: <arc_cast_hide:teleportToStormwindSpell>
                NOTE: You should ALWAYS use _hide for teleporting spells
                      to avoid a bug in the gossip menus if you tele before closing.

### - NEW: ARC.API - A pseudo API to make scripting in ArcSpells easier.
      Functions:
            |cffFFA500ARC:COMM("command")|r    -- Sends a server command.
            |cffFFA500ARC:COPY("text / link")|r      -- Open a Dialog box to Copy the text/link
            |cffFFA500ARC:GETNAME()|r       -- Returns the Target's into chat. Try it on a MogIt NPC.
            |cffFFA500ARC:CAST("commID")|r         -- Casts an ArcSpell from your Personal Vault
            |cffFFA500ARC:CASTP("commID")|r       -- Casts an ArcSpell from the Phase Vault

            |cffFFA500ARC:IF("ArcVar", [trueCommand, falseCommand], [var1])|r
                -- Checks if the ArcVar is true. If true & false command provided, runs the
                    command depending the ArcVar. If no commands provided, returns true if
                    the ArcVar is true, or false if not. If Var1 provided, it will append the
                    var to the true & false command, allowing shorter writen functions.

            |cffFFA500ARC:IFS("ArcVar", "value", [trueCommand, falseCommand], [var1])|r
                -- Works similar to ARC:IF but checks if the ArcVar matches the "value".
                    i.e., ARC:IFS("WhatFruit","Apple") checks if WhatFruit = Apple.

            |cffFFA500ARC:TOG("ArcVar")|r             -- Toggles an ArcVar between True & False.
            |cffFFA500ARC:SET("ArcVar", "value")|r  -- Sets an ArcVar to the specificed "value".
            |cffFFA500ARC:GET("ArcVar")|r           -- Returns the value of an ArcVar. Needs embeded.

            Please see the User Guide for more information on the ARC.API, or use `/arc`.
            Frequent ARC.API functions can also be ran using a more friendly slash command,
            but are limited in that you cannot use spaces in the vars or commands.
                |cffFFA500/arc cast $commID|r -- Cast Personal ArcSpell (accepts spaces)
                |cffFFA500/arc castp $commID|r -- Cast Phase ArcSpell (accepts spaces)
                |cffFFA500/arc cmd $serverCommand|r -- (i.e, /arc cmd cheat fly) (accepts spaces)
                |cffFFA500/arc getname|r -- Prints your taget's name in your chatbox (Try on a MogIt NPC!)
                |cffFFA500/arc copy $text/link|r -- Open a box to copy the text/link (accepts spaces)
                |cffFFA500/arc tog $ArcVar|r -- (no spaces)
                |cffFFA500/arc set $ArcVar $value|r -- (no spaces)
                |cffFFA500/arc if $ArcVar $trueCommand $falseCommand $trueVar $flaseVar|r -- (no spaces)
                  - ex: /arc if ToggleTorch aura unaura 1234 all
                  - Casts aura 1234 if ToggleTorch is true, or unaura all if false.
                  - You can leave off $falseVar and $trueVar will be used for both true & false.
                |cffFFA500/arc ifs $ArcVar $value $trueCommand $falseCommand $trueVar $flaseVar|r
                  - Same as '/arc if' but tests if $ArcVar == $value instead of just true.


      NOTE: ArcVars exist in a global table, "ARC.VAR". You can access them directly if you
            understand Lua & know what you're doing. 

            ArcVars are |cffED4245NOT SAVED|r between sessions. Persistent Vars may come in the
            future if the need is there, but they won't be secure. If you think of a good use
            for them, let me know and I can push it up higher on the to-do list.

### - NEW: Changelogs are now documented in-game in the Settings panel.
           Along with Links to the User Guide on Discord & the forums!

### - BUG FIXES:
        - Reduced the number of phase-vault hard-refreshes. Vault refreshes if needed, but
                but you can forcefully trigger a refresh as well still.
        - Revert now properly executes the intended revert command without extra junk.
        - Slash /Command & Server .Command actions no longer break when a comma is present.
                - That said, Slash & Server actions no longer support comma multi-actions.

{h2:c} __________________________________________________________ {/h2}
##v1.0.0 (October 20th, 2022)

- Released! 

{h2:c} __________________________________________________________ {/h2}
{h1:c} Credits {/h1}
Artwork by T ( |cff5865F2AJT#0715|r )
Code by MindScape ( |cff5865F2MindScape#0332|r )
Code Support by Iyadriel ( |cff5865F2Haleth#0001|r )

Thank you to Azarchius & Razmatas for Epsilon Core, Executable, and Server support

### |cff57F287And thank YOU, the players of Epsilon, for being the drive behind this server, community, and the amazing things you have, and will, create.|r 
{h2:c} __________________________________________________________ {/h2}
]]


--[[ Blank Space for Tabbing : Copy this : ' ' ]]