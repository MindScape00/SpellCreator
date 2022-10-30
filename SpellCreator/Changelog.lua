local addonName, addonTable = ...

addonTable.ChangelogText = [[
#v1.1.0 (October 31st, 2022)
- NEW: Add Phase Vault ArcSpell to Gossip Button!
      - Phase Vault now has direct integration for adding an
      ArcSpell to a Gossip Menu! With a Gossip Menu open, just
      click on the head with a speech bubble icon! (Officer+)
- NEW: Private ArcSpells in Phase Vault!
      - ArcSpells uploaded to the Phase Vault can now be
      marked as private. Private spells will only show in the
      vault for Officers+. Players will still be able to use
      the spells from Integrations (i.e., Gossip).
- UPDATED: Forge UI
      - The + - buttons to add/remove rows have been reworked
      into a cleaner, more user-friendly UI.
      - A new "Clear & Reset UI" button has been added!
      - New background flickering 'animations'.
- UPDATED: Transfer to Personal Vault Button added.
      - This should make it easier to transfer spells to your
      personal vault. No more having to edit & save.
- RE-WORKED: Gossip ArcTags have been re-implemented.
      - The new implementation was needed for supporting
      the new Add to Gossip button/UI.
      - NEW: You can now add ArcTags to Gossip Text to run
            those actions automatically. This replaces auto
            tags in gossip options.
      - CHANGED: <arcanum_auto> & <arcanum_toggle> are now
            just <arcanum_show>. Auto functions in gossip
            text, toggle in gossip options.
      - CHANGED: Auto tag removed as an option tag extension.
            - Old uses will still function for legacy, but
            you should be using <arcanum_cast_(hide):spell>
            in '.ph fo np go text add' instead now.

## _________________________________________________

#v1.0.0 (October 25th, 2022)

- Released! 

## _________________________________________________


See the User Guide for more help on how to use Arcanum.
[Builder's Haven Discord Guide](https://discord.com/channels/718813797611208788/1031832007031930880/1032773498600439898) - [Epsilon Forums Guide](https://forums.epsilonwow.net/topic/3413-addon-arcanum-spell-forge-user-guide/?tab=comments#comment-15529)
]]


--[[ Blank Space for Tabbing : Copy this : ' ' ]]