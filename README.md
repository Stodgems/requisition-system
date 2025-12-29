# Vehicle Requisition System

## Features

- **Terminal Entities**: Interactive terminals that players can use to spawn vehicles
- **Spawn Areas**: Define custom spawn zones using the toolgun with directional spawning
- **Vehicle Return System**: Return vehicles to terminals when parked in spawn areas
- **Vehicle Customization**: Players can select skins and bodygroups before spawning
- **Automatic Model Caching**: LVS/Simfphys vehicle models automatically cached on server start
- **Admin Management**: Full admin panel for managing vehicles, terminals, and spawn areas
- **Job & Qualification Restrictions**: Limit vehicle access by job and/or qualifications from the Qualification System
- **Multi-Vehicle Support**: Compatible with GMod default vehicles, TDM Cars, LVS, and Simfphys vehicles
- **SAM Integration**: Supports SAM permission system
- **Custom Spawn Functions**: Add custom Lua code to vehicle spawning
- **Vehicle Tracking**: Tracks spawned vehicles per player with configurable limits
- **Cooldown System**: Optional cooldown timers for vehicle spawning
- **Auto-despawn**: Vehicles automatically removed on player disconnect
- **Terminal Persistence**: Terminals auto-load per map with `!reqsave` command
- **Custom Terminal Models**: Each terminal can have a unique model

## Installation

1. Place the `requisition-system` folder in `garrysmod/addons/`
2. Restart your server or reload addons
3. Configure admin ranks in `lua/autorun/sh_requisition_config.lua`

## Configuration

Edit `lua/autorun/sh_requisition_config.lua` to customize:

- **AdminRanks**: Define which usergroups can access admin features
- **AdminCommand**: Change the chat command to open admin menu (default: `!reqadmin`)
- **TerminalSettings**:
  - `default_model`: Default model for new terminals (default: `models/props_combine/combine_interface001.mdl`)
  - `display_name`: Text displayed above terminals (default: `"Requisition Terminal"`)
  - `text_height_offset`: Height above terminal for text display in units (default: `60`)
  - `show_terminal_id`: Show terminal ID number (default: `true`)
  - `show_use_hint`: Show "Press E to use" hint (default: `true`)
- **VehicleSettings**:
  - `cooldown_time`: Cooldown duration in seconds
  - `max_vehicles_per_player`: Maximum vehicles per player
  - `spawn_height_offset`: Height above ground to spawn vehicles

## Usage

### For Admins

#### Creating Spawn Areas
1. Equip the **Spawn Area Creator** tool from the toolgun
2. **Look in the direction you want vehicles to face** when spawning
3. Left-click to set the first corner (captures spawn direction, snapped to 15° increments)
4. Right-click to set the second corner
5. A **red arrow** will appear showing the vehicle spawn direction
6. Enter a name for the spawn area
7. The area is now available for terminals

**Note**: Vehicles will spawn at the **center** of the spawn area facing the direction you looked when setting the first corner

#### Managing Vehicles
1. Type `!reqadmin` (or your configured command) in chat
2. Go to the **Vehicles** tab
3. Click **+ Add New Vehicle**
4. Fill in:
   - **Vehicle Name**: Display name (auto-filled when selecting from dropdown)
   - **Entity Class**: Select from dropdown (includes GMod vehicles, TDM Cars, LVS, Simfphys)
   - **Allowed Jobs**: Select multiple jobs from list (shown with team colors)
   - **Required Qualifications**: Select multiple qualifications from list
   - **Custom Function**: Optional Lua code executed on spawn
5. Click **Create Vehicle**

**Note**: The system automatically detects vehicle models and KeyValues (for TDM Cars). LVS and Simfphys vehicles are automatically supported

#### Setting Up Terminals
1. Spawn a **Requisition Terminal** from the entities tab
2. Right-click the terminal with the physgun (hold secondary fire)
3. Select a **Spawn Area** from the dropdown
4. (Optional) Change the **Terminal Model** to customize its appearance
5. Check which **Vehicles** should be available at this terminal
6. Click **Save Configuration**

**Note**: Each terminal can have a unique model. Multiple terminals can exist on the same map with different models.

#### Saving Terminal Positions
1. Place and configure all terminals on your map
2. Type `!reqsave` in chat to save terminal positions for this map
3. Terminals will automatically spawn on server restart for this specific map
4. Use the admin menu to delete terminals if needed

#### Managing Terminals
1. Type `!reqadmin` in chat
2. Go to the **Terminals** tab
3. View all terminals with their positions and assigned areas
4. Click **Edit** to configure a terminal
5. Click **Delete** to remove a terminal

#### Managing Areas
1. Type `!reqadmin` in chat
2. Go to the **Spawn Areas** tab
3. View all spawn areas with their bounds
4. Click **Delete** to remove an area (warns if terminals use it)

### For Players

#### Spawning Vehicles
1. Approach a Requisition Terminal
2. Press **E** (use key) to open the terminal interface
3. Browse available vehicles
4. Vehicles show:
   - Green accent: You can spawn this vehicle
   - Red accent: You don't meet requirements (locked)
5. Click **Spawn Vehicle** button
6. **If the vehicle has skins or bodygroups**, a customization menu appears:
   - Use **sliders** to select skin number
   - Use **sliders** to select bodygroup variants
   - Click **Spawn Vehicle** to confirm
7. **If no customization options**, vehicle spawns immediately
8. Vehicle will spawn at the **center** of the assigned area facing the designated direction

#### Returning Vehicles
1. Park your vehicle in the spawn area where you spawned it
2. Open the terminal (Press **E**)
3. Click the **Return Vehicle** button in the top-right of the terminal UI
4. If you have multiple vehicles in the area, select which one to return
5. The vehicle will be removed and freed from your vehicle limit

**Note**: The Return Vehicle button shows the count of vehicles you have in the spawn area. You can only return vehicles that are currently parked within the spawn zone (checked by X/Y position, not height)

## Integration with Qualification System

The requisition system integrates seamlessly with the Qualification System:

1. **Vehicle Requirements**: Add qualification names to vehicle restrictions
2. **Permission Check**: System automatically checks if player has required qualifications
3. **Custom Functions**: Access qualification data in custom spawn functions

Example custom function:
```lua
-- Apply special modifications based on qualifications
if QualSystem:PlayerHasQualification(ply, "pilot_advanced") then
    vehicle:SetColor(Color(255, 215, 0)) -- Gold color for advanced pilots
end
```

## Permissions

### Admin Access
- Usergroups defined in `Config.AdminRanks`
- SAM permission: `requisition_admin`

### Vehicle Access
- Job-based: Vehicle must be in player's allowed jobs list
- Qualification-based: Player must have all required qualifications
- Both conditions must be met if both are specified

## Database Tables

- `requisition_areas`: Spawn area definitions (includes spawn_angle for directional spawning)
- `requisition_terminals`: Terminal entity data
- `requisition_vehicles`: Vehicle definitions (includes key_values for TDM Cars)
- `requisition_terminal_vehicles`: Terminal-vehicle relationships
- `requisition_saved_terminals`: Map-specific terminal persistence data

## Commands

### Chat Commands
- `!reqadmin` - Opens the global admin menu
- `!reqsave` - Saves all terminals for the current map (admin only)

### Console Commands
- `reqsystem_cache_models` - Manually cache vehicle models for LVS/Simfphys vehicles (admin/console only)
- `reqsystem_wipe` - Warning prompt to wipe database (console only)
- `reqsystem_wipe_confirm` - Confirms and executes database wipe (console only, IRREVERSIBLE)

## Troubleshooting

**Terminal not working?**
- Check that the terminal has an assigned spawn area
- Verify vehicles are assigned to the terminal
- Ensure the spawn area has clear space

**Can't spawn vehicles?**
- Check job restrictions match your current job
- Verify you have required qualifications
- Check if you've hit the vehicle limit
- Wait for cooldown timer to expire

**Customization menu not appearing?**
- Vehicle may not have skins or bodygroups
- For LVS vehicles: Run `reqsystem_cache_models` to cache model paths
- Check that vehicle has a model stored in the database (check admin menu)
- Restart server to trigger automatic model caching

**Admin menu not opening?**
- Verify you're in the admin ranks list in config
- Check SAM permissions if using SAM
- Try running the command again: `!reqadmin`

## Supported Vehicle Types

- **Default GMod Vehicles**: Airboat, Jalopy, Jeep (prop_vehicle_jeep)
- **TDM Cars**: Custom vehicles using vehiclescript KeyValues
- **LVS Vehicles**: All LVS base types (wheeldrive, tank, helicopter, bike, starfighter, etc.)
- **Simfphys Vehicles**: Compatible with Simfphys vehicle framework
