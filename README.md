# BLZD ESX RP Chat - A Modern FiveM Chat System

A modern and configurable chat resource for FiveM servers using ESX Legacy. It provides multiple chat channels, local proximity messages, role-based tags, direct messages, admin chat, command suggestions, timestamps, sounds, and emoji support.

## Features

- ESX Legacy integration
- Modern NUI chat interface
- Multiple selectable chat channels
- Global and proximity-based messaging
- Local OOC chat
- Roleplay `/me` messages
- Private direct messages
- Restricted admin chat
- ESX job-based role tags
- ACE permission support
- Command autocomplete and suggestions
- Configurable message fading
- Configurable visible message limit
- Message timestamps
- Chat notification sounds
- Built-in emoji picker
- Individual client-side chat clearing
- Player server ID command

## Requirements

- FiveM server
- ESX Legacy
- A configured server artifact build
- ACE permissions for admin functionality

## Installation

1. Download or clone the resource into your server's `resources` directory.

2. Place the resource in a suitable folder, for example:

   ```text
   resources/[standalone]/BLZDChat
   ```

3. Add the resource to your `server.cfg`
    ```
    ensure es_extended
    ensure BLZDChat
    ```

4. Restart the server

## Configuration
All main settings can be changed in `config.lua`

### General Settings
```lua
Config.MaxMessages        = 100      -- Maximum number of messages retained by the chat UI.
Config.MaxVisibleMessages = 5        -- Maximum number of messages displayed while the chat is inactive.
Config.FadeTimeout        = 12000    -- Time in milliseconds before inactive chat messages fade.
Config.MaxInputLength     = 256      -- Maximum number of characters allowed in a message.
Config.DefaultChannel     = 'global' -- Channel selected when the player first joins.
Config.EnableSounds       = true     -- Enables or disables chat notification sounds.
Config.EnableTimestamps   = true     -- Shows or hides message timestamps.
Config.EnableEmojis       = true     -- Enables or disables the built-in emoji picker.
```

### Local Chat Range
```lua
Config.LocalChatRange = 25.0
```
This controls the maximum distance, in GTA units, from which players can see local chat and local OOC messages.
The range applies to:
- Local chat
- Local OOC chat
- `/me` messages

### Channels
Channels are configured through `Config.Channels`.
```lua
Config.Channels = {
    { id = 'global',    label = 'Global',       color = '#8B5CF6', icon = '🌍' },
    { id = 'local',     label = 'Local',        color = '#F59E0B', icon = '📍' },
    { id = 'ooc',       label = 'OOC',          color = '#6B7280', icon = '💬' },
    { id = 'ooclocal',  label = 'OOC Local',    color = '#78716C', icon = '🗨️' },
    { id = 'me',        label = 'Me',            color = '#10B981', icon = '🎭' },
    { id = 'dm',        label = 'DM',            color = '#10B981', icon = '✉️' },
    { id = 'admin',     label = 'Admin',         color = '#EF4444', icon = '🛡️', adminOnly = true },
}
```

### Roles
Labels that show before someone posts a chat message
```lua
Config.Roles = {
    ['admin']     = { label = 'ADMIN',   color = '#EF4444', priority = 90 },
    ['police']    = { label = 'LSPD',    color = '#3B82F6', priority = 50 },
    ['ambulance'] = { label = 'EMS',     color = '#EC4899', priority = 50 },
    ['mechanic']  = { label = 'MECH',    color = '#F97316', priority = 40 },
    ['citizen']   = { label = 'CITIZEN', color = '#6B7280', priority = 0  },
}
```

### Command Suggestions
Custom chat suggestions for commands. It will pick up on resource commands but this is if you add more commands to the chat or want custom suggestions.
```lua
Config.Suggestions = {
    { command = '/me',    description = 'Roleplay action',          params = {{ name = 'action',  help = 'What are you doing?' }} },
    { command = '/ooc',   description = 'Global OOC message',       params = {{ name = 'message', help = 'Your OOC message' }} },
    { command = '/looc',  description = 'Local OOC message',        params = {{ name = 'message', help = 'Your local OOC message' }} },
    { command = '/dm',    description = 'Direct message a player',  params = {{ name = 'id', help = 'Player server ID' }, { name = 'message', help = 'Your message' }} },
    { command = '/admin', description = 'Admin chat',               params = {{ name = 'message', help = 'Admin message' }} },
    { command = '/clear', description = 'Clear your chat',          params = {} },
    { command = '/id',    description = 'Show your server ID',      params = {} },
}
```

### Emojis
The emojis that show in the picker. This is for people that can't work out how to do Win + . to open the windows one.
```lua
Config.Emojis = {
    '😀', '😂', '🤣', '😊', '😎', '🤔', '😢', '😡', '🥺', '😍',
    '👍', '👎', '👋', '🙏', '💪', '🤝', '✌️', '🖐️', '👊', '🤙',
    '❤️', '🔥', '⭐', '💀', '🎉', '🚗', '🔫', '💰', '📻', '🏥',
    '🚔', '🚑', '🏎️', '⚡', '🎯', '💎', '🗝️', '📱', '🎵', '✅',
}
```