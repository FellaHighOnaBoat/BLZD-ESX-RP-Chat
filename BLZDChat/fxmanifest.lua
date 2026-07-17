fx_version 'cerulean'
game 'gta5'

description 'A Modern Chat Resource for FiveM'
author 'BLZD'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/sounds/*.ogg'
}

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'