0.0.8
- Transition to exclusive support for ox_target. If you use a target system, ox_target must be installed.

#### Why is this happening?
Ox_target has discontinued compatibility with qb_target. This currently only affects qb_core and ox_target users.

This means the module responsible for converting options and other parameters has been removed from ox_target. I decided not to integrate this into e_core because the qb_target system is outdated. Moving forward, I have chosen to support the modern ox_target natively.

#### What has changed:
e_core/bridge/global/client.lua: Adds ox exports.

e_core/bridge/esx/client.lua: Removal of qtarget-related functions

e_core/bridge/qb/client.lua: Removal of qb-target-related functions

0.0.7
- extends qb-core item remove function
- small bugfix
0.0.6
- Error: SEND_NUI_MESSAGE: invalid JSON passed in frame (rapidjson error code 3)
- The initial labor value could have been NaN, so the Nui interface did not open, only the cursor was visible.
  The change affects the:
- [lib/config_check.lua] -- added
- [fxmanifest.lua]
- [server/meta.lua] (prepareMeta)

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
