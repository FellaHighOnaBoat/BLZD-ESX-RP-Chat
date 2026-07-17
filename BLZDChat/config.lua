Config = {}

Config.MaxMessages        = 100
Config.MaxVisibleMessages = 5
Config.FadeTimeout        = 12000
Config.MaxInputLength     = 256
Config.DefaultChannel     = 'global'
Config.EnableSounds       = true
Config.EnableTimestamps   = true
Config.EnableEmojis       = true

-- Range for local chat and local OOC
Config.LocalChatRange     = 25.0

-- Channels - users can freely type in any channel they have access to by selecting it
-- 'adminOnly' = true means only admin/ace chat.admin can use it
Config.Channels = {
    { id = 'global',    label = 'Global',       color = '#8B5CF6', icon = '🌍' },
    { id = 'local',     label = 'Local',        color = '#F59E0B', icon = '📍' },
    { id = 'ooc',       label = 'OOC',          color = '#6B7280', icon = '💬' },
    { id = 'ooclocal',  label = 'OOC Local',    color = '#78716C', icon = '🗨️' },
    { id = 'me',        label = 'Me',           color = '#10B981', icon = '🎭' },
    { id = 'dm',        label = 'DM',           color = '#10B981', icon = '✉️' },
    { id = 'admin',     label = 'Admin',        color = '#EF4444', icon = '🛡️', adminOnly = true },
}

-- Roles assigned to players based on their ESX job or ace permissions
Config.Roles = {
    ['admin']     = { label = 'ADMIN',   color = '#EF4444', priority = 90 },
    ['police']    = { label = 'LSPD',    color = '#3B82F6', priority = 50 },
    ['ambulance'] = { label = 'EMS',     color = '#EC4899', priority = 50 },
    ['mechanic']  = { label = 'MECH',    color = '#F97316', priority = 40 },
    ['citizen']   = { label = 'CITIZEN', color = '#6B7280', priority = 0  },
}

-- Commands that appear in the chat suggestion/autocomplete list
Config.Suggestions = {
    { command = '/me',    description = 'Roleplay action',          params = {{ name = 'action',  help = 'What are you doing?' }} },
    { command = '/ooc',   description = 'Global OOC message',       params = {{ name = 'message', help = 'Your OOC message' }} },
    { command = '/looc',  description = 'Local OOC message',        params = {{ name = 'message', help = 'Your local OOC message' }} },
    { command = '/dm',    description = 'Direct message a player',  params = {{ name = 'id', help = 'Player server ID' }, { name = 'message', help = 'Your message' }} },
    { command = '/admin', description = 'Admin chat',               params = {{ name = 'message', help = 'Admin message' }} },
    { command = '/clear', description = 'Clear your chat',          params = {} },
    { command = '/id',    description = 'Show your server ID',      params = {} },
}

Config.Emojis = {
    '😀', '😂', '🤣', '😊', '😎', '🤔', '😢', '😡', '🥺', '😍',
    '👍', '👎', '👋', '🙏', '💪', '🤝', '✌️', '🖐️', '👊', '🤙',
    '❤️', '🔥', '⭐', '💀', '🎉', '🚗', '🔫', '💰', '📻', '🏥',
    '🚔', '🚑', '🏎️', '⚡', '🎯', '💎', '🗝️', '📱', '🎵', '✅',
}