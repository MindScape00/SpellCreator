local addonName, ns = ...
--[[                                                                                       ]]
-- Max Length of a line is within the brackets.
ns.ChangelogText = [[

{h3:c} See the User Guide for more help on how to use Arcanum.{/h3}
{h3:c} [Link - Builder's Haven Discord Guide](https://discord.com/channels/718813797611208788/1031832007031930880/1032773498600439898) - [Link - Epsilon Forums Guide](https://forums.epsilonwow.net/topic/3413-addon-arcanum-spell-forge-user-guide/) {/h3}

{h1:c} Changelog {/h1}
{h2:c} __________________________________________________________ {/h2}
##v1.3.2 (February 11th, 2023)

### - Hotfix:

    - Fixed Sparks storage limitation causing crashes if too many sparks
        were saved in a phase. Now it's 'unlimited'.
    - Added a warning when trying to save a spell that is too big for the
        the phase vault (encoded string of 3750 characters or more).

{h2:c} __________________________________________________________ {/h2}
##v1.3.1 (February 2nd, 2023)

### - Changes:

    - Fixed updating Sparks for those already in the phase when a Spark is created,
          edited, or deleted. Woops!
    - Added a few more Spark border styles, thanks to skylar/sunkencastles!

{h2:c} __________________________________________________________ {/h2}
##v1.3.0 (January 31st, 2023)

### - Changes:

    - SPARKS!  Arcanum Sparks are a new, innovative way to provide interaction
               between players & ArcSpells in a phase!
           - When a player walks over a |cffFFA500Spark Trigger|r, they will be prompted with a
             non-intrusive, clickable |cffFFA500extrabar button|r to cast that ArcSpell from the Phase!
           - Sparks can be placed anywhere, and have a customizable activation radius
             for how close a player must be to activate the trigger & show the Spark!
                 - To create a Spark, |cffFFA500right-click|r a spell in your phase's Phase Vault and
                   select |cffFFA500Create Spark|r!
                 - You can manage sparks in your phase using the 'Spark' |cffFFA500lightning|r
                   |cffFFA500bolt icon|r in the bottom right of your Phase Vault.

    - Quickcast Expansion!  |cffFFA500Quickcast|r has been expanded to allow multiple |cffFFA500Books|r,
                as well as multiple |cffFFA500Pages|r in each book!
            - You can manage your books, and pages, by |cffFFA500right-clicking|r a book.
            - Books can be |cffFF6B6Bs|cffFFFF6Bt|cff6BFF6By|cff6BFFFFl|cff6B6BFFe|cffFF6BFFd|r with various skins via the Right-Click menu on them!
            - You can create |cffFFA500Dynamic Pages|r based on Profiles, which will always show all the
                 ArcSpells in that profile.
            - Accidentally closed all your Books? You can reopen them from the settings menu.
            - Books & Pages are saved across your entire account, but which Books are shown
                 is saved per-character, so each character can have their own Book if you want!
            - A Book Manager UI is available to help manage pages & books via AddOn Settings.

    - ARC.PHASE:API - We've added support for new |cffFFA500ARC.PHASE|r Vars in the ARC:API system.
            - ARC.PHASE Vars are saved between sessions, and saved per-phase!
            - These are accessed via new actions, or in Macro Scripts using ARC.PHASE
                functions, or directly using "/arc phase" commands.
            - You can see more info in the updated |cffFFA500user-guide|r (links above).

    - More Actions!  We've added more actions to help you accomplish tasks you
            may not have even thought of yet because you didn't realize you could.
            - Revert actions now trigger instantly when a spell is cancelled as well.

    - Behind-the-scenes improvements!  Shout-out to |cff57F287Iyadriel|r for providing immense support
        on improving the 'behind the scenes' code, including rewriting the entire drop-down
        menu system - twice! You'll see this bring some UI improvements, and allows us too
        do cool things, like adding input boxes directly into the drop-downs!
        Arcanum would not be as great as it is without their amazing help <3

    - Bug Fixes:  We've squashed a lot of bugs.. Here's a quick list!
        Gossips only working on first click; "SpellCreator was blocked..." messages; ARC:IFS work
        properly for single-commands just like ARC:IF; URL Copy pop-up no longer extends wider
        than the screen and becomes un-usable; Escape codes now work properly in text actions;
        Stop Spells properly stops spells; Properly load the phase vault on Phase Change & Login;
        Reset Anim now .. kinda properly resets your anim, you'll need to move first before you
        can use other anims again though.. engine limitation it seems; Profiles are easier
        to navigate in the dropdown now & doesn't miss 'account' when toggling Show All.

{h2:c} __________________________________________________________ {/h2}
##v1.2.0 (December 21st, 2022)

### - Highlights:

    - ICONS!  ArcSpells can now have icons assigned, which are used in the
            vaults, Quickcast, Castbars, and Integrations when available!

    - Quickcast!  ArcSpells can be assigned to Quickcast via right-click in your personal
            vault. Quickcast is an easier way to quickly access & cast frequent spells.
            Add a spell from your vault, then mouse-over the Quickcast book to get started!

    - NEW Actions!  We've added tons of new actions to make it easier to do what you want
            without needing to figure out the scripting side or making a command. We've
            also reworked the Action Drop-down Menu, grouping actions into categories,
            to make it easier to find what you're looking for.

    - Castbar!  ArcSpells longer than 0.25 seconds now have a castbar!
            Hate it? Want it channeled? You can toggle it off or to show as channeled
            by using the Cast/Channel checkbox in the top 'Attic' area in the Forge!

    - Keybinds!  You can assign keybindings to ArcSpells via right-click in your personal
            vault. Note: Keybinds are unique, you can't have two spells on one binding.

    - OPie Integration!  ArcSpells can be added directly to OPie rings if you have OPie
            installed. You can add them just as you would any other action, using the new
            Arcanum - Spell Forge section when adding an item to a ring.

### - More Changes & QOL Updates:
    - Everywhere:
        - Tooltips are more consistent and easier to follow. Tip: Read the ToolTIPs for
            TIPS on how to use Arcanum & what things do!

    - Gossip:
        - Fixed a few bugs with the Add to Gossip UI.
        - Added a new <arc_copy:url> tag to make gossip options to copy a URL easier.

    - Forge UI:
        - New rows added will pre-fill with the same delay as the row you're adding from.
        - More alerts to help you know when an error occurs, like casting an ArcSpell that
            doesn't exist in your vault from another ArcSpell.
        - Editing a spell now puts the vault in Editing mode with 'Save' button instead of
            'Create', and does not make you confirm to over-write the save.
        - Trying to load another spell into the editor, or trying to reset the editor,
            with unsaved changes, will now warn you that you have unsaved changes first.
        - A new 'Profile' dropdown lives in the top of the Forge UI, to assign a spell
            directly to a profile when creating it.

    - Vaults:
        - Spell Visibility in Phase Vault's can now be directly changed using the
            private icon without having to reupload it.
        - Hotkeys, Quickcast, and Profiles can all be assigned from right-clicking a
            spell in your vault!
        - You can now search in your Personal & Phase vaults for a spell by name.

    - Chat Links:
        - Chat links have been reworked to be less reliant on your character being online.
            Links also take up much less characters in messages. All spell data is now
            sent to a client directly when shared, and has it stored in a cache so
            it can be saved if desired without having to request it from the owner again.

    - ARC:API
        - ARC:RAND() added as a replacement for GetRandomArgument() which Blizz removes
            in 9.0+ for some reason.
        - ARC:CMD has replaces the ARC:COMM function so that it matches Gossip <arc_cmd:>
            tags and the /arc cmd command. ARC:COMM will still function in the background.
        - ARC:IF & ARC:IFS now support single command specification, so you can specify
            the command to run if it passes the check, or do nothing if not.
        - /arc commands now accept spaces in arguments by using "" around them.
            - Example: /arc if HasKeys ".phase tele inside the door"

### - Bugs Fixed:
    - Phase Vault did not load correctly when entering a phase that required a
        loading screen.
    - Multi-Tags did not work if using the Immersion addon for gossips.
    - Profiles reset when loading & re-saving a spell. They're now remembered!
    - Phase vault could get stuck loading when changing phases under certain conditions.
    - Phase vault could occasionally show duplicated, until refreshed.
    - Personal vault is now correctly sorted in alphabetical order.

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
            |cffFFA500ARC:GETNAME()|r       -- Returns the Target's name into chat. Try it on a MogIt NPC.
            |cffFFA500ARC:CAST("commID")|r         -- Casts an ArcSpell from your Personal Vault
            |cffFFA500ARC:CASTP("commID")|r       -- Casts an ArcSpell from the Phase Vault

            |cffFFA500ARC:IF("ArcVar", [trueCommand, falseCommand], [var1])|r
                -- Checks if the ArcVar is true. If true & false command provided, runs the
                    command depending on the ArcVar. If no commands provided, returns true if
                    the ArcVar is true, or false if not. If Var1 provided, it will append the
                    var to the true & false command, allowing shorter written functions.

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

### - NEW: Changelogs are now documented in-game in the Addon Settings panel.
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
Artwork, Assets, Ideas, and Inspiration by 'T' ( |cff5865F2AJT#0715|r )
Code by MindScape ( |cff5865F2MindScape#0332|r )
Code by Iyadriel ( |cff5865F2Haleth#0001|r )
IconPicker borrowed from DiceMaster (Thank you Skylar! |cff5865F2sunkencastles#1807|r )

Thank you to Azarchius & Razmatas for Epsilon Core, Executable, and Server support

### |cff57F287And thank YOU, the players of Epsilon, for being the drive behind this server, community, and the amazing things you have, and will, create.|r
{h2:c} __________________________________________________________ {/h2}
]]


--[[ Blank Space for Tabbing : Copy this : ' ' ]]
