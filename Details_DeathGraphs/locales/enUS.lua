local L = LibStub("AceLocale-3.0"):NewLocale("Details_DeathGraphs", "enUS", true)
if not L then return end

L["STRING_ENCOUNTER_MAXSEGMENTS"] = "Current Encounter Max Segments"
L["STRING_ENCOUNTER_MAXSEGMENTS_DESC"] = "Maximum amount of segments to store on the 'Current Encounter' display."
L["STRING_ENDURANCE_DEATHS_THRESHOLD"] = "Endurance Deaths Threshold"
L["STRING_ENDURANCE_DEATHS_THRESHOLD_DESC"] = "The first |cFFFFFF00X|r players to die loses endurance percentage."
L["STRING_FLAWLESS"] = "|cFF44FF44Flawless Player!|r"
L["STRING_OPTIONS"] = "Options"
L["STRING_PLUGIN_DESC"] = [=[During boss encounters, capture raid members deaths and build statistics from it.

- |cFFFFFFFFCurrent Encounter|r: |cFFFF9900show deaths for the latest segments.

- |cFFFFFFFFTimeline|r: |cFFFF9900show a graph telling when debuffs and spells from the boss are casted on raid members and draw lines representing where deaths are happening.

- |cFFFFFFFFEndurance|r: |cFFFF9900show a list of players with a percentage indicating how much tries they were alive in the encounter.

- |cFFFFFFFFOverall|r: |cFFFF9900Mantain a list of players with their death and also the damage taken by spell before the death.]=]
L["STRING_PLUGIN_NAME"] = "Advanced Death Logs"
L["STRING_PLUGIN_WELCOME"] = [=[Welcome to Advanced Death Logs!


-|cFFFFFF00Current Encounter|r: show deaths from the last boss encouter, by default it stores deaths for the last two segments, you may increase this at the options panel.

- |cFFFFFF00Timeline|r: Show where your raid is dying most at time, also shows the time for enemy abilities.

- |cFFFFFF00Endurance|r: Measure player skill from who is dying first in a encounter, by default the first 5 players to die loses Endurance Percentage.

- |cFFFFFF00Overall|r: show common death logs plus the overall damage taken before the player's death.


- You can always close the window by clicking with the right mouse button!]=]
L["STRING_RESET"] = "Reset Data"
L["STRING_TIMELINE_DEATHS_THRESHOLD"] = "Timeline Deaths Threshold"
L["STRING_TIMELINE_DEATHS_THRESHOLD_DESC"] = "The first |cFFFFFF00X|r deaths in the encounter are registered to show on the timeline graphic."
L["STRING_TOOLTIP"] = "Show death graphics"
L["STRING_10NORMAL"] = "10 Normal"
L["STRING_10NORMAL_DESC"] = "Record deaths when you are playing on 10 normal difficulty."
L["STRING_25NORMAL"] = "25 Normal"
L["STRING_25NORMAL_DESC"] = "Record deaths when you are playing on 25 normal difficulty."
L["STRING_10HEROIC"] = "10 Heroic"
L["STRING_10HEROIC_DESC"] = "Record deaths when you are playing on 10 heroic difficulty."
L["STRING_25HEROIC"] = "25 Heroic"
L["STRING_25HEROIC_DESC"] = "Record deaths when you are playing on 25 heroic difficulty."
