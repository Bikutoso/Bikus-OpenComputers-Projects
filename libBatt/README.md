
# LibBatt
Manage batteries without hassle.<br>
Supports RF/FE, IC2 EU, and GregTech CEu EU.
Have mod specific functions for CEu, and IC2
## Variables
* **list** - Table of all known batteries
* **address** - Address of current primary battery
## Generic Functions
Functions in this section can be accessed by the module name directly. E.g. `batt.function()`
___
**refresh()**
Rebuilds the table of known batteries and updates primary battery (if no user defined primary battery is defined) and returns the address of the primary battery <br>
_NOTE: This should not be necessary in most cases, as it'll refresh automatically when needed_
```lua
batt = require("libBatt")

batt.refresh() -- "00000000-0000-0000-0000-000000000000"
```
**getEnergyStored(address, side)**
Returns the current power level of the primary battery or the specified battery if given an address. <br>
_NOTE: Not sure what `side` does, RF based batteries have them and it was easy to add an argument for_
```lua
batt = require("libBatt")

print(batt.getEnergyStored()) -- 100
print(batt.getEnergyStored("11111111-1111-1111-1111-111111111111")) -- 2048
```
**getMaxEnergyStored(address, side)**
Returns the max power level of the primary battery or the specified battery if given an address. <br>
_NOTE: Not sure what `side` does, RF based batteries have them and it was easy to add an argument for_```lua
```lua
batt = require("libBatt")

print(batt.getEnergyMaxStored()) -- 1000
print(batt.getEnergyMaxStored("11111111-1111-1111-1111-111111111111")) -- 50000
```
**convert(type)**
Sets the library to convert EU or RF to the selected type (EU/RF)
```lua
batt = require("libBatt")

--Primary battery is a IC2 battery
print(batt.getEnergyStored()) -- 100
batt.convert("RF")
print(batt.getEnergyStored()) -- 400
```
**getUnit(address)**
Returns the energy type of the primary battery or the specified battery if given an address. <br>
_NOTE: If a type is selected by `convert()` it'll display that type_
```lua
batt = rquire("libBatt")

curPower = batt.getEnergyStored()
type = batt.getUnit()
print(curPower.." "..type.."/t") -- "100 RF/t"
```
**setPrimary(address)**
Sets the primary battery to the specified address, `nil` automatically selects a new address
```lua
batt = require("libBatt")

print(batt.address) -- "00000000-0000-0000-0000-000000000000"

batt.setPrimary("11111111-1111-1111-1111-111111111111")
print(batt.address) --"11111111-1111-1111-1111-111111111111"

batt.setPrimary()
print(batt.address) -- "00000000-0000-0000-0000-000000000000" (might not be the same as before)
```
## IC2 Specific Functions
Functions in this section require the IC submodule. E.g. `batt.IC.function()`
___
**GetSinkTier(address)**
Returns the tier of the primary battery or the specified battery if given an address. <br>
_NOTE: Returns `0` if not an IC2 battery_
```lua
batt = require("libBatt")

print(batt.GetSinkTier()) -- 3
```
## GregTech CEu Specific Functions
Functions in this section require the GT submodule. E.g. `batt.GT.function()`
___
**getInputAmperage(address)**
Returns the input amperage of the primary battery or the specified battery if given an address.
```lua
batt = require("libBatt")

print(batt.getInputAmperage()) -- 2
```
**getInputVoltage(address)**
Returns the input voltage of the primary battery or the specified battery if given an address.
```lua
batt = require("libBatt")

print(batt.getInputVoltage()) -- 32
```
**getInputPerSec(address)**
Returns the input EU/s of the primary battery or the specified battery if given an address.
```lua
batt = require("libBatt")

print(batt.getInputPerSec()) -- 32
```
**getOutputAmperage(address)**
Returns the output amperage of the primary battery or the specified battery if given an address.
```lua
batt = require("libBatt")

print(batt.getOutputAmperage()) -- 2
```
**getOutputVoltage(address)**
Returns the output voltage of the primary battery or the specified battery if given an address.
```lua
batt = require("libBatt")

print(batt.getOutputVoltage()) -- 32
```
**getOutputPerSec(address)**
Returns the output EU/s of the primary battery or the specified battery if given an address.
```lua
batt = require("libBatt")

print(batt.getOutputPerSec()) -- 32
```
**getCover(address, side)**
Returns the cover on the specified side of the primary battery or the specified battery if given an address.

