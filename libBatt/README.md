
# LibBatt
A library to manage multiple batteries with unified method names between power types.<br>
Works with RF/FE, GT5 EU, CEu EU and IC2 EU power.
## Variables
* **list** - Table of all known batteries
* **currentAddress** - Address of current primary battery
## Generic Functions
Functions in this section can be accessed by the module name directly. E.g. `battery.function()`
___
**refresh()**
Rebuilds the table of known batteries and updates primary battery (if no user defined primary battery is defined) and returns the address of the primary battery <br>
_NOTE: This should not be necessary in most cases, as it'll refresh automatically when needed_
```lua
battery = require("libBatt")

battery.refresh() -- "00000000-0000-0000-0000-000000000000"
```
**getEnergyStored(address, side)**
Returns the current power level of the primary battery or the specified battery if given an address. <br>
_NOTE: Not sure what `side` does, RF based batteries have them and it was easy to add an argument for_
```lua
battery = require("libBatt")

print(battery.getEnergyStored()) -- 100
print(battery.getEnergyStored("11111111-1111-1111-1111-111111111111")) -- 2048
```
**getMaxEnergyStored(address, side)**
Returns the max power level of the primary battery or the specified battery if given an address. <br>
_NOTE: Not sure what `side` does, RF based batteries have them and it was easy to add an argument for_
```lua
battery = require("libBatt")

print(battery.getEnergyMaxStored()) -- 1000
print(battery.getEnergyMaxStored("11111111-1111-1111-1111-111111111111")) -- 50000
```
**convert(type)**
Sets the library to convert EU or RF to the selected type (EU/RF)
```lua
battery = require("libBatt")

--Primary battery is a IC2 battery
print(battery.getEnergyStored()) -- 100
battery.convert("RF")
print(battery.getEnergyStored()) -- 400
```
**setCurrentPowerType(powerType)**
Sets the display and converstion power type of the primary battery ~~or the specified battery if given an address.~~
```lua
battery = rquire("libBatt")

curPower = battery.getEnergyStored()

type = battery.setCurrentPowerType()
print(curPower.." "..type.."/t") -- "100 RF/t"


```
**setPrimary(address)**
Sets the primary battery to the specified address, `nil` automatically selects a new address
```lua
battery = require("libBatt")

print(battery.address) -- "00000000-0000-0000-0000-000000000000"

battery.setPrimary("11111111-1111-1111-1111-111111111111")
print(battery.address) --"11111111-1111-1111-1111-111111111111"

battery.setPrimary()
print(battery.address) -- "00000000-0000-0000-0000-000000000000" (might not be the same as before)
```
## IC2 Specific Functions
Functions in this section require the IC submodule. E.g. `battery.IC.function()`
___
**GetSinkTier(address)**
Returns the tier of the primary battery or the specified battery if given an address. <br>
_NOTE: Returns `0` if not an IC2 battery_
```lua
battery = require("libBatt")

print(battery.GetSinkTier()) -- 3
```
## GregTech CEu Specific Functions
Functions in this section require the GT submodule. E.g. `battery.GT.function()`
___
**getInputAmperage(address)**
Returns the input amperage of the primary battery or the specified battery if given an address.
```lua
battery = require("libBatt")

print(battery.getInputAmperage()) -- 2
```
**getInputVoltage(address)**
Returns the input voltage of the primary battery or the specified battery if given an address.
```lua
battery = require("libBatt")

print(battery.getInputVoltage()) -- 32
```
**getInputPerSec(address)**
Returns the input EU/s of the primary battery or the specified battery if given an address.
```lua
battery = require("libBatt")

print(battery.getInputPerSec()) -- 32
```
**getOutputAmperage(address)**
Returns the output amperage of the primary battery or the specified battery if given an address.
```lua
battery = require("libBatt")

print(battery.getOutputAmperage()) -- 2
```
**getOutputVoltage(address)**
Returns the output voltage of the primary battery or the specified battery if given an address.
```lua
battery = require("libBatt")

print(battery.getOutputVoltage()) -- 32
```
**getOutputPerSec(address)**
Returns the output EU/s of the primary battery or the specified battery if given an address.
```lua
battery = require("libBatt")

print(battery.getOutputPerSec()) -- 32
```
**getCover(address, side)**
Returns the cover on the specified side of the primary battery or the specified battery if given an address.

`Gender love, not hate`
