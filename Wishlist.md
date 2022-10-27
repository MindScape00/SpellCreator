SpellCreator wishlist:

- refactor gossip string parsing again: <https://pastebin.com/TL5T42ab>
- Item Forge integration (right click a forged item to cast an arcanum spell - basically reimplement Gossip so that it’s tag system can be reused)
- direct command usage tag (I.e., <comm:.tele stormwind>) to bypass making arcspells for simple actions. This shouldn’t be in arcanum tbh but it’s too small to make its own addon..

~~- add an option to mark a spell as “private” in the phase vault, and then it only shows up in the vault for Officer+. Still needs to be loaded into normal players memory so it can be called from a gossip tho!~~ Done
~~—— (if spelldata.private and not IsOfficer then —skip but count skips and adjust (button# = k - numSkips) — if it was private & player IS officer, show a lil eye icon to indicate it’s a private spell.)~~

- add icon support? If were integrating with item forge tho we might be able to just skip this, or add it so there a button to auto generate an item for them and uses that icon? Oh god is arcanum needing a new tab for item forge? No no..)

- ability to add section breaks with header text between rows

- Spell Variables ("If" buttons for actions, and a new action type "Script -> Imbedded Dropdown for 'Set Variable', 'Set Temp Var', and idk what else would be needed but more could be added there later if needed too - Maybe a simpler one of 'Toggle State' also which just flips a 'State' between true/false for easily toggled spells (i.e., my macro for toggling holding a torch))

~~- Add an easier macro-script function to directly cast spells~~ (Added: CastARC("spell") )

~~- Add to Gossip button / UI~~ Done
- Add support for Gossip body text for auto cast.

- Fix Private checkbox text cutting off if your UI is too small

- Add Gossip Tag Option for 'Save Spell' from Phase Vault (<arcanum_save:commID>)
  - Shit, need to refactor the Add to Gossip UI now to support another option lol...
  - While on it, improve gossip tag detection so it supports multiple tags, or comma separated spell names in tags.

- Forcefully deny commas in commID, too much worry if people use it and then it might break something later.




