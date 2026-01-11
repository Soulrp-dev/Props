shared_script '@soul-main/protection_shared-obfuscated.lua'
shared_script '@soul-main/ai_module_fg-obfuscated.lua'


fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'DNT'
description 'Sistema de coleções'
version '2.0'

dependencies {
    'vrp',
    'oxmysql',
    'ox_lib'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@vrp/lib/Utils.lua',
    'shared/config.lua',
    'shared/utils.lua',
    'shared/catalog.lua'
}

-- Client
client_scripts {
    '@vrp/config/Native.lua',
    'client-side/bootstrap.lua',
    'client-side/nui.lua',
    'client-side/trade.lua',
    'client-side/collections.lua',
    'client-side/objects.lua',
    'client-side/commands.lua'
}

-- Server
server_scripts {
    '@vrp/config/Groups.lua',
    '@vrp/config/Item.lua',
    '@vrp/config/Vehicle.lua',
    '@oxmysql/lib/MySQL.lua',
    'server-side/bootstrap.lua',
    'server-side/database.lua',
    'server-side/trade.lua',
    'server-side/collections.lua',
    'server-side/objects.lua',
    'server-side/commands.lua',
}

-- UI
ui_page 'web-side/index.html'

files {
    'web-side/**/*',
    'shared/img/*.png',
}

data_file 'DLC_ITYP_REQUEST' 'stream/Soul_Cachorro.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Soul_menina.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Soul_menino.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Soul_dragaob.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Soul_dragaop.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/LV_cinnaxmelodycatcafe.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/LV_kuromicatcafe.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/LV_mymelodycatcafe.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/LV_pochaaccocatcafe.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/LV_pompompurincatcafe.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/gnd_looneytunes.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/Soul_capivara_marrom.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Soul_capivara_natal.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Soul_capivara_verde.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Soul_capivara_piloto.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Soul_capivara_r6.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Soul_capivara_coelho.ydr'

data_file 'DLC_ITYP_REQUEST' 'stream/paradise_box2_by_joao.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/Soul_patinho.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Soul_patinho_sino.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Soul_pato_pisca.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Soul_pato_gelo.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Soul_pato_rena.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/gotica_harry.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/gotica_draco.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/gotica_hermione.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/gotica_luna.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/gotica_dobby.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/gotica_voldemorte.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/Soul_cap3.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/LV_teddynew.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/*.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/totem.ydr'
data_file 'DLC_ITYP_REQUEST' 'stream/totem.ytd'
data_file 'DLC_ITYP_REQUEST' 'stream/totem.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/gotica_kittybanguela.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/gotica_kittyet.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/gotica_kittyfuria.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/gotica_kittyunicornio.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/rainbow_poneialice.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/rainbow_poneialice2.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/rainbow_poneimel.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/panda_labubu01.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/panda_labubu02.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/panda_labubu03.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/panda_labubu04.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/panda_labubu05.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/dreamsstore_stitch1.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/dreamsstore_stitch2.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/dreamsstore_stitch3.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/bgd_chanel_grinch.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/gnd_olaf.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/rbs_msa_boo.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/rbs_msa_ceiamae.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/rbs_msa_mike.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/rbs_msa_randall_boggs.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/rbs_msa_roz.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/rbs_msa_sulley.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/vny_snowsoul.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/vny_grinchsoul.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/vny_lightsoul.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/vny_noelsoul.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/vny_trenosoul.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/Soul_gatinha1.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/Soul_gatinha2.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/Soul_gatinha3.ytyp' 

data_file 'DLC_ITYP_REQUEST' 'stream/flay_globoneveazza.ytyp' 

data_file 'DLC_ITYP_REQUEST' 'stream/dreamsstore_aisha.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/dreamsstore_blom.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/dreamsstore_flora.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/dreamsstore_musa.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/dreamsstore_stella.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/dreamsstore_tecna.ytyp' 

data_file 'DLC_ITYP_REQUEST' 'stream/wave_bat_prop.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/wave_cap_prop.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/wave_hulk_prop.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/wave_iron_prop.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/wave_spider_prop.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/wave_super_prop.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/wave_cleo_prop.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/wave_cwolf_prop.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/wave_drac_prop.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/wave_lagoona_prop.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/wave_frankie_prop.ytyp' 

data_file 'DLC_ITYP_REQUEST' 'stream/myc_baby.ytyp' 

data_file 'DLC_ITYP_REQUEST' 'stream/balaox1.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/balaox2.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/balaox3.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/balaox4.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/balaox5.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/balaox6.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/balaox7.ytyp'


data_file 'DLC_ITYP_REQUEST' 'stream/Merida.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Sailor.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/barbie.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Mirabel.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Olaf.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Woody.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/SpiderMan.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/StrollerToyPINK.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/stollerwithcow.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/strollerdollblood.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/strollerdollblue.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/strollerdollbombom.ytyp'


data_file 'DLC_ITYP_REQUEST' 'stream/gotica_demogorgon.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/gotica_eleven.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/gotica_lucas.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/gotica_max.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/gotica_mike.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/gotica_vecna.ytyp' 
data_file 'DLC_ITYP_REQUEST' 'stream/gotica_will.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/Koch_Store_Mcqueen.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Koch_Store_Luigi.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Koch_Store_Guido.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Koch_Store_Sally.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Koch_Store_Mater.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Koch_Store_Doc.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/Koch_Store_Cruz.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/dreamsstore_jerry.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/dreamsstore_ratocego.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/dreamsstore_ratato.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/cutekizeteddy_by_joao.ytyp'