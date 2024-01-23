0.0.5
- [e_core/server/labor.lua] (addOfflineLabor) Add offline labor timestamp. When logging in, the player receives the lab points collected during the offline time, with the current time stamp attached.
- [e_core/bridge/qb/shared.lua] (convertItems) Ignore non valid items and non-existent labels

0.0.4
- The getPlayer() function has been extended. It is given two optional parameters.
The change affects the:
- [bridge/esx/client.lua] (getPlayer)
- [bridge/esx/shared.lua] (convertPlayer)

- [bridge/qb/client.lua] (getPlayer)
- [bridge/qb/shared.lua] (convertPlayer)
The changes do not affect the standalone folder. Always copy and overwrite (if necessary) the functions of eCore there!
