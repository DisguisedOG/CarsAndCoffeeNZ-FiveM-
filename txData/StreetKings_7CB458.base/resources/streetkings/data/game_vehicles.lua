---@class GameVehicle
---@field model string
---@field price integer
---@field class string 'C'|'B'|'A'|'S'

---@class StarterGameVehicleStats
---@field topSpeed integer
---@field accel integer
---@field handling integer
---@field braking integer

---@class StarterGameVehicle
---@field model string
---@field displayName string
---@field brand string
---@field vehicleType string
---@field value integer
---@field class string
---@field stats StarterGameVehicleStats

local STARTER_CAR_CLASS_BAND = {
    C = { topSpeed = 5.4, accel = 5.0, handling = 6.8, braking = 6.0 },
    B = { topSpeed = 6.2, accel = 5.8, handling = 7.6, braking = 6.8 },
    A = { topSpeed = 7.2, accel = 6.6, handling = 8.4, braking = 7.6 },
    S = { topSpeed = 8.2, accel = 7.4, handling = 9.0, braking = 8.4 },
}

---@param class string
---@param modifiers table<string, number>
---@return table<string, number>
local function scaleStarterStats(class, modifiers)
    local band = STARTER_CAR_CLASS_BAND[class] or STARTER_CAR_CLASS_BAND.C
    local stats = {
        topSpeed = band.topSpeed + (modifiers.topSpeed or 0),
        accel = band.accel + (modifiers.accel or 0),
        handling = band.handling + (modifiers.handling or 0),
        braking = band.braking + (modifiers.braking or 0),
    }

    return {
        topSpeed = stats.topSpeed,
        speed = stats.topSpeed,
        accel = stats.accel,
        acceleration = stats.accel,
        handling = stats.handling,
        braking = stats.braking,
        brake = stats.braking,
    }
end

---@type StarterGameVehicle[]
---@type StarterGameVehicle[]
SKStarterVehicles = {
    {
        model = 'na6',
        displayName = 'MX-5 (NA)',
        brand = 'Mazda',
        vehicleType = 'automobile',
        value = 35000,
        class = 'B',
        stats = scaleStarterStats('B', {
            topSpeed = 0.1,
            accel = 0.1,
            handling = 0.6,
            braking = 0,
        })
    },
    {
        model = '205',
        displayName = '205',
        brand = 'Peugeot',
        vehicleType = 'automobile',
        value = 14000,
        class = 'C',
        stats = scaleStarterStats('C', {
            topSpeed = 0,
            accel = 0,
            handling = 1.0,
            braking = 0.2,
        })
    },
    {
        model = 'nis180',
        displayName = '180SX',
        brand = 'Nissan',
        vehicleType = 'automobile',
        value = 21000,
        class = 'C',
        stats = scaleStarterStats('C', {
            topSpeed = 0.2,
            accel = 0.4,
            handling = 0.4,
            braking = 0.3,
        })
    },
    {
        model = 'e21',
        displayName = 'E21',
        brand = 'BMW',
        vehicleType = 'automobile',
        value = 22000,
        class = 'C',
        stats = scaleStarterStats('C', {
            topSpeed = 0.1,
            accel = 0.2,
            handling = 0,
            braking = 0,
        })
    }
}

---@type table<string, StarterGameVehicle>
SKStarterVehiclesByModel = {}

for _, vehicle in ipairs(SKStarterVehicles) do
    SKStarterVehiclesByModel[vehicle.model] = vehicle
end

---@type table<string, GameVehicle[]>
SKGameVehicles = {

    automobile = {
        -- C class
        { model = 'issi3',      price = 14000,  class = 'C' },  -- Weeny Issi Classic
        { model = 'club',       price = 15000,  class = 'C' },  -- BF Club
        { model = 'warrener2',  price = 16000,  class = 'C' },  -- Vulcar Warrener HKR
        { model = 'asterope2',  price = 17000,  class = 'C' },  -- Karin Asterope GZ
        { model = 'futo2',      price = 19500,  class = 'C' },  -- Karin Futo GTX
        { model = 'iwagen',     price = 19500,  class = 'C' },  -- Obey I-Wagen
        { model = 'kanjo',      price = 20000,  class = 'C' },  -- Dinka Blista Kanjo
        { model = 'postlude',   price = 23500,  class = 'C' },  -- Dinka Postlude
        { model = 'zion3',      price = 25500,  class = 'C' },  -- ÃƒÆ’Ã…â€œbermacht Zion Classic
        -- B class
        { model = 'kuruma',     price = 29000,  class = 'B' },  -- Karin Kuruma
        { model = 'sultan2',    price = 36000,  class = 'B' },  -- Karin Sultan RS
        { model = 'sugoi',      price = 38000,  class = 'B' },  -- Dinka Sugoi
        { model = 'jester3',    price = 40500,  class = 'B' },  -- Annis Jester Classic
        { model = 'flashgt',    price = 42500,  class = 'B' },  -- Vapid Flash GT
        { model = 'previon',    price = 45000,  class = 'B' },  -- Karin Previon
        { model = 'eurosx32',   price = 47000,  class = 'B' },  -- Annis Euros X32
        { model = 'rt3000',     price = 48000,  class = 'B' },  -- Dinka RT3000
        { model = 'chavosv6',   price = 50000,  class = 'B' },  -- Dinka Chavos V6
        { model = 'tailgater2', price = 51000,  class = 'B' },  -- Obey Tailgater S
        { model = 'zr350',      price = 55000,  class = 'B' },  -- Annis ZR350
        -- A class
        { model = 'uranus',     price = 57500,  class = 'A' },  -- Vapid Uranus LozSpeed
        { model = 'euros',      price = 58500,  class = 'A' },  -- Annis Euros
        { model = 'sultan3',    price = 61500,  class = 'A' },  -- Karin Sultan Classic Custom
        { model = 'minimus',    price = 63000,  class = 'A' },  -- Annis Minimus
        { model = 'cypher',     price = 65000,  class = 'A' },  -- ÃƒÆ’Ã…â€œbermacht Cypher
        { model = 'fr36',       price = 66000,  class = 'A' },  -- Fathom FR36
        { model = 'hardy',      price = 66000,  class = 'A' },  -- Annis Hardy
        { model = 'penumbra2',  price = 67500,  class = 'A' },  -- Maibatsu Penumbra FF
        -- S class
        { model = 'woodlander', price = 70000,  class = 'S' },  -- Karin Woodlander
        { model = 'calico',     price = 73500,  class = 'S' },  -- Karin Calico GTF
        { model = 'remus',      price = 77500,  class = 'S' },  -- Annis Remus
        { model = 'vectre',     price = 83000,  class = 'S' },  -- Emperor Vectre
        { model = 'italigto',   price = 85000,  class = 'S' },  -- Grotti Itali GTO
        { model = 'jester4',    price = 88500,  class = 'S' },  -- Dinka Jester RR
        { model = '124spider',  price = 44500,  class = 'B' },
        { model = '155q4',      price = 13500,  class = 'C' },
        { model = 'aqv',        price = 58500,  class = 'A' },
        { model = 'rs318',      price = 62000,  class = 'A' },
        { model = 'audirs4',    price = 46500,  class = 'B' },
        { model = 's3sedan',    price = 48000,  class = 'B' },
        { model = 's8d2',       price = 17000,  class = 'C' },
        { model = 'e21',        price = 34000,  class = 'B' },
        { model = 'bmw1er',     price = 44000,  class = 'B' },
        { model = 'm135i',      price = 42500,  class = 'B' },
        { model = 'm2f22',      price = 42000,  class = 'B' },
        { model = 'e46',        price = 122000, class = 'S' },
        { model = 'm3f80',      price = 45500,  class = 'B' },
        { model = 'fk8',        price = 37000,  class = 'B' },
        { model = 'dc5',        price = 43000,  class = 'B' },
        { model = 'nc1',        price = 75000,  class = 'A' },
        { model = 'ap2',        price = 48000,  class = 'B' },
        { model = 'veln',       price = 44500,  class = 'B' },
        { model = 'na6',        price = 35000,  class = 'B' },
        { model = 'fd',         price = 58500,  class = 'A' },
        { model = 'rx811',      price = 16000,  class = 'C' },
        { model = 'mcjcw20',    price = 40500,  class = 'B' },
        { model = 'mr53',       price = 14500,  class = 'C' },
        { model = 'eclipse',    price = 43000,  class = 'B' },
        { model = 'evo9mr',     price = 90500,  class = 'S' },
        { model = 'lanex400',   price = 77500,  class = 'A' },
        { model = 'nis180',     price = 37000,  class = 'B' },
        { model = '350z',       price = 48500,  class = 'B' },
        { model = 'nis15',      price = 66000,  class = 'A' },
        { model = 'majsr',      price = 39500,  class = 'B' },
        { model = 'skyline',    price = 94500,  class = 'S' },
        { model = 'r35',        price = 96500,  class = 'S' },
        { model = '205',        price = 38500,  class = 'B' },
        { model = '205t',       price = 14000,  class = 'C' },
        { model = 'cliors',     price = 17000,  class = 'C' },
        { model = 'twizy',      price = 16500,  class = 'C' },
        { model = 'brz13',      price = 36000,  class = 'B' },
        { model = 'gdwrxsti',   price = 88000,  class = 'S' },
        { model = 'toy86',      price = 43500,  class = 'B' },
        { model = 'jzx100',     price = 34000,  class = 'B' },
        { model = 'tsgr20',     price = 75000,  class = 'A' },
        { model = 'prius',      price = 15000,  class = 'C' },
        { model = 'a80',        price = 99500,  class = 'S' },
        { model = 'volvo850r',  price = 36000,  class = 'B' },
        { model = 's60pole',    price = 30500,  class = 'B' },
        { model = 'golf4',      price = 38000,  class = 'B' },
        { model = 'golf7r',     price = 30500,  class = 'B' },
        -- B class
        { model = 'khamelion',       price = 49000,  class = 'B' }, -- Hijak Khamelion
        { model = 'voltic',          price = 51500,  class = 'B' }, -- Coil Voltic
        { model = 'neon',            price = 57000,  class = 'B' }, -- Pfister Neon
        { model = 'imorgon',         price = 61000,  class = 'B' }, -- ÃƒÆ’Ã¢â‚¬â€œverflÃƒÆ’Ã‚Â¶d Imorgon
        { model = 'sentinel6',       price = 62000,  class = 'B' }, -- ÃƒÆ’Ã…â€œbermacht Sentinel 6
        { model = 'vorschlaghammer', price = 64500,  class = 'B' }, -- Benefactor Vorschlaghammer
        -- A class
        { model = 'schlagen',        price = 75000,  class = 'A' }, -- Benefactor Schlagen GT
        { model = 'comet5',          price = 82500,  class = 'A' }, -- Pfister Comet SR
        { model = 'growler',         price = 86000,  class = 'A' }, -- Maibatsu Growler
        { model = 'itali2',          price = 87000,  class = 'A' }, -- Grotti Itali Classic
        { model = 'cyclone',         price = 89000,  class = 'A' }, -- Coil Cyclone
        -- S class
        { model = 'comet6',          price = 91000,  class = 'S' }, -- Pfister Comet S2
        { model = 'tempesta',        price = 91500,  class = 'S' }, -- Pegassi Tempesta
        { model = 'torero2',         price = 92000,  class = 'S' }, -- Pegassi Torero XO
        { model = 'sentinel5',       price = 95000,  class = 'S' }, -- ÃƒÆ’Ã…â€œbermacht Sentinel GTS
        { model = 'banshee3',        price = 97000,  class = 'S' }, -- Bravado Banshee GTS
        { model = 'coquette6',       price = 100500, class = 'S' }, -- Invetero Coquette D5
        { model = 'db11',            price = 67000,  class = 'A' },
        { model = 'ast',             price = 69000,  class = 'A' },
        { model = 'vantage',         price = 67000,  class = 'A' },
        { model = 'a6',              price = 31500,  class = 'B' },
        { model = 'a8lfsi',          price = 44000,  class = 'B' },
        { model = 'r820',            price = 95500,  class = 'S' },
        { model = 'rs5',             price = 67000,  class = 'A' },
        { model = '2013rs7',         price = 41000,  class = 'B' },
        { model = 'ttrs',            price = 44000,  class = 'B' },
        { model = 'bmwe38',          price = 37500,  class = 'B' },
        { model = '17m760i',         price = 43500,  class = 'B' },
        { model = 'i8',              price = 67000,  class = 'A' },
        { model = 'e92',             price = 63000,  class = 'A' },
        { model = 'bmwm4',           price = 41500,  class = 'B' },
        { model = 'f82',             price = 58000,  class = 'A' },
        { model = 'f82st',           price = 40000,  class = 'B' },
        { model = 'f82duke',         price = 40000,  class = 'B' },
        { model = 'f824slw',         price = 40000,  class = 'B' },
        { model = 'f82lw',           price = 40000,  class = 'B' },
        { model = 'f82hs',           price = 40000,  class = 'B' },
        { model = 'm5e60',           price = 113000, class = 'S' },
        { model = 'm5',              price = 43500,  class = 'B' },
        { model = 'bmwm5f90',        price = 43000,  class = 'B' },
        { model = 'm6f13',           price = 62000,  class = 'A' },
        { model = 'bmwm8',           price = 88500,  class = 'S' },
        { model = 'z4bmw',           price = 45500,  class = 'B' },
        { model = 'bug09',           price = 75000,  class = 'A' },
        { model = '458it',           price = 40500,  class = 'B' },
        { model = '488gtb',          price = 43000,  class = 'B' },
        { model = 'fc15',            price = 46500,  class = 'B' },
        { model = 'f430s',           price = 96500,  class = 'S' },
        { model = 'aperta',          price = 122500, class = 'S' },
        { model = 'pista',           price = 61000,  class = 'A' },
        { model = 'pistas',          price = 61000,  class = 'A' },
        { model = 'fairlane66',      price = 13500,  class = 'C' },
        { model = 'focusrs',         price = 15000,  class = 'C' },
        { model = 'fgt',             price = 87500,  class = 'S' },
        { model = 'gt17',            price = 103000, class = 'S' },
        { model = 'fpace',           price = 28500,  class = 'B' },
        { model = 'xkgt',            price = 37000,  class = 'B' },
        { model = 'agera2011',       price = 60500,  class = 'A' },
        { model = 'ccx',             price = 89500,  class = 'S' },
        { model = 'regera16',        price = 146500, class = 'S' },
        { model = 'rmodlp750',       price = 134500, class = 'S' },
        { model = 'lp700',           price = 95500,  class = 'S' },
        { model = 'rmodlp770',       price = 123500, class = 'S' },
        { model = 'countach',        price = 72500,  class = 'A' },
        { model = 'lp610',           price = 70500,  class = 'A' },
        { model = '18performante',   price = 87000,  class = 'S' },
        { model = 'lp670',           price = 72000,  class = 'A' },
        { model = 'lwlp670',         price = 72000,  class = 'A' },
        { model = 'rcf',             price = 58000,  class = 'A' },
        { model = 'mgrantur2010',    price = 45000,  class = 'B' },
        { model = 'mc12',            price = 92500,  class = 'S' },
        { model = '570gt',           price = 86500,  class = 'S' },
        { model = '720s',            price = 87000,  class = 'S' },
        { model = 'p1',              price = 94500,  class = 'S' },
        { model = 'senna',           price = 71500,  class = 'A' },
        { model = 'e400',            price = 42500,  class = 'B' },
        { model = 'c63s',            price = 44500,  class = 'B' },
        { model = 'c63sc',           price = 33500,  class = 'B' },
        { model = 'cls2015',         price = 67500,  class = 'A' },
        { model = 'benze55',         price = 73000,  class = 'A' },
        { model = 'e63s',            price = 46500,  class = 'B' },
        { model = 'w463as',          price = 56500,  class = 'A' },
        { model = 'w463a',           price = 34500,  class = 'B' },
        { model = 'g5502019',        price = 34500,  class = 'B' },
        { model = 'g632019',         price = 34500,  class = 'B' },
        { model = 'g632019x',        price = 34500,  class = 'B' },
        { model = 'g634x4',          price = 34500,  class = 'B' },
        { model = 'rmodgt63',        price = 107000, class = 'S' },
        { model = 'amggtr',          price = 120000, class = 'S' },
        { model = 'sls',             price = 88000,  class = 'S' },
        { model = '600sl',           price = 37000,  class = 'B' },
        { model = 'mbc63',           price = 40500,  class = 'B' },
        { model = 'e300',            price = 48000,  class = 'B' },
        { model = 'w202',            price = 68000,  class = 'A' },
        { model = 'gtrnismo17',      price = 95000,  class = 'S' },
        { model = 'huayra',          price = 95500,  class = 'S' },
        { model = '718b',            price = 47500,  class = 'B' },
        { model = '911turbos',       price = 57000,  class = 'A' },
        { model = 'cgt',             price = 98000,  class = 'S' },
        { model = 'panamera17turbo', price = 46500,  class = 'B' },
        { model = 'wraith',          price = 30500,  class = 'B' },
        { model = 'models',          price = 40000,  class = 'B' },
        -- C class
        { model = 'ruiner',         price = 11000,  class = 'C' }, -- Imponte Ruiner
        { model = 'blade',          price = 12000,  class = 'C' }, -- Vapid Blade
        { model = 'moonbeam',       price = 13000,  class = 'C' }, -- Declasse Moonbeam
        { model = 'gauntlet3',      price = 15500,  class = 'C' }, -- Bravado Gauntlet Classic
        { model = 'impaler',        price = 18000,  class = 'C' }, -- Declasse Impaler
        { model = 'ellie',          price = 23000,  class = 'C' }, -- Vapid Ellie
        -- B class
        { model = 'vigero',         price = 25500,  class = 'B' }, -- Declasse Vigero
        { model = 'gauntlet',       price = 28500,  class = 'B' }, -- Bravado Gauntlet
        { model = 'greenwood',      price = 30500,  class = 'B' }, -- Bravado Greenwood
        { model = 'tampa',          price = 32500,  class = 'B' }, -- Declasse Tampa
        { model = 'dominator10',    price = 35000,  class = 'B' }, -- Vapid Dominator FX
        { model = 'dominator8',     price = 36000,  class = 'B' }, -- Vapid Dominator GTT
        { model = 'impaler5',       price = 43000,  class = 'B' }, -- Declasse Impaler SZ
        -- A class
        { model = 'gauntlet5',      price = 47500,  class = 'A' }, -- Bravado Gauntlet Classic
        { model = 'dominator9',     price = 56000,  class = 'A' }, -- Vapid Dominator GT
        { model = 'gauntlet4',      price = 59000,  class = 'A' }, -- Bravado Gauntlet Hellfire
        { model = 'dominator7',     price = 60000,  class = 'A' }, -- Vapid Dominator ASP
        -- S class
        { model = 'vigero2',        price = 73000,  class = 'S' }, -- Declasse Vigero ZX
        { model = 'buffalo4',       price = 75000,  class = 'S' }, -- Bravado Buffalo STX
        { model = 'ctsv16',         price = 43000,  class = 'B' },
        { model = 'gmt900escalade', price = 15500,  class = 'C' },
        { model = 'camaro_ss',      price = 39000,  class = 'B' },
        { model = 'zl12017',        price = 48500,  class = 'B' },
        { model = 'c7',             price = 62500,  class = 'A' },
        { model = 'stingray',       price = 44500,  class = 'B' },
        { model = 'corvettezr1',    price = 115500, class = 'S' },
        { model = '16challenger',   price = 57000,  class = 'A' },
        { model = '69charger',      price = 37000,  class = 'B' },
        { model = '16charger',      price = 47000,  class = 'B' },
        { model = 'demon',          price = 78000,  class = 'A' },
        { model = 'ram2500',        price = 17000,  class = 'C' },
        { model = 'viper',          price = 47000,  class = 'B' },
        { model = 'acr',            price = 64500,  class = 'A' },
        { model = 'mustang65',      price = 13500,  class = 'C' },
        { model = 'mustang19',      price = 48500,  class = 'B' },
        { model = '96impala',       price = 36500,  class = 'B' },
        { model = 'boss429',        price = 38000,  class = 'B' },
        -- C class
        { model = 'yosemite1500', price = 12000, class = 'C' },    -- Declasse Yosemite 1500
        { model = 'l35',          price = 14000, class = 'C' },    -- Walton L35
        { model = 'patriot3',     price = 17500, class = 'C' },    -- Mammoth Patriot Mil-Spec
        -- B class
        { model = 'kamacho',      price = 28000, class = 'B' },    -- Canis Kamacho
        { model = 'freecrawler',  price = 35500, class = 'B' },    -- Canis Freecrawler
        { model = 'aleutian',     price = 38500, class = 'B' },    -- Vapid Aleutian
        { model = 'astron',       price = 40000, class = 'B' },    -- Pfister Astron
        -- A class
        { model = 'caracara2',    price = 53500, class = 'A' },    -- Vapid Caracara
        { model = 'firebolt',     price = 54500, class = 'A' },    -- Vapid Firebolt
        { model = 'castigator',   price = 55500, class = 'A' },    -- Canis Castigator
        { model = 'monstrociti',  price = 56500, class = 'A' },    -- Maibatsu MonstroCiti
        -- S class
        { model = 'novak',        price = 58500, class = 'S' },    -- Lampadati Novak
        { model = 'jubilee',      price = 59500, class = 'S' },    -- Enus Jubilee
        { model = 'everon3',      price = 66000, class = 'S' },    -- Karin Everon RS
        { model = 'toros',        price = 82500, class = 'S' },    -- Pegassi Toros
        { model = 'q820',         price = 33500, class = 'B' },
        { model = 'bentaygast',   price = 76500, class = 'A' },
        { model = 'x6mf16',       price = 47000, class = 'B' },
        { model = 'checol17',     price = 17000, class = 'C' },
        { model = 'gxraptor',     price = 29000, class = 'B' },
        { model = 'srt8',         price = 57500, class = 'A' },
        { model = 'srt8b',        price = 38000, class = 'B' },
        { model = 'jp12',         price = 34500, class = 'B' },
        { model = 'rr12',         price = 16500, class = 'C' },
        { model = 'man',          price = 12500, class = 'C' },
        { model = 'rrst',         price = 31000, class = 'B' },
        { model = 'suzukigv',     price = 17000, class = 'C' },
        { model = 'r50',          price = 46000, class = 'B' },
    }
}
local REALISTIC_CLASS_BANDS = {
    C = { topSpeed = 5.2, accel = 4.8, handling = 6.8, braking = 6.0 },
    B = { topSpeed = 6.0, accel = 5.6, handling = 7.6, braking = 6.8 },
    A = { topSpeed = 7.0, accel = 6.4, handling = 8.4, braking = 7.6 },
    S = { topSpeed = 8.2, accel = 7.4, handling = 9.0, braking = 8.4 },
}

local MODEL_TUNING_BIAS = {
    ['205'] = { topSpeed = -0.3, accel = -0.2, handling = 0.5, braking = 0.1 },
    ['205t'] = { topSpeed = -0.4, accel = -0.3, handling = 0.6, braking = 0.1 },
    ['na6'] = { topSpeed = 0.1, accel = 0.1, handling = 0.5, braking = 0.1 },
    ['nis180'] = { topSpeed = 0.2, accel = 0.3, handling = -0.1, braking = 0 },
    ['bmwe21'] = { topSpeed = -0.1, accel = -0.1, handling = -0.2, braking = -0.1 },
    ['e21'] = { topSpeed = -0.1, accel = -0.1, handling = -0.2, braking = -0.1 },
    ['toy86'] = { topSpeed = 0.1, accel = 0.2, handling = 0.4, braking = 0.1 },
    ['a80'] = { topSpeed = 0.5, accel = 0.5, handling = 0.2, braking = 0.1 },
    ['r35'] = { topSpeed = 0.7, accel = 0.6, handling = 0.2, braking = 0 },
    ['gtrnismo17'] = { topSpeed = 0.7, accel = 0.6, handling = 0.2, braking = 0 },
    ['amggtr'] = { topSpeed = 0.8, accel = 0.7, handling = 0.3, braking = 0.1 },
    ['huayra'] = { topSpeed = 0.7, accel = 0.7, handling = 0.2, braking = 0.1 },
    ['p1'] = { topSpeed = 0.8, accel = 0.8, handling = 0.3, braking = 0.1 },
    ['senna'] = { topSpeed = 0.7, accel = 0.7, handling = 0.3, braking = 0.1 },
    ['twizy'] = { topSpeed = -1.0, accel = -0.7, handling = 0.4, braking = 0.3 },
    ['prius'] = { topSpeed = -0.4, accel = -0.3, handling = 0.2, braking = 0.1 },
    ['viper'] = { topSpeed = 0.2, accel = 0.4, handling = -0.2, braking = 0 },
    ['e63s'] = { topSpeed = 0.2, accel = 0.3, handling = -0.1, braking = 0 },
    ['cls2015'] = { topSpeed = 0.2, accel = 0.2, handling = 0, braking = 0.1 },
    ['fgt'] = { topSpeed = 0.6, accel = 0.6, handling = 0.2, braking = 0.1 },
    ['rs5'] = { topSpeed = 0.4, accel = 0.3, handling = 0.1, braking = 0.1 },
    ['m5e60'] = { topSpeed = 0.5, accel = 0.5, handling = 0.1, braking = 0.1 },
    ['m5'] = { topSpeed = 0.4, accel = 0.4, handling = 0.1, braking = 0.1 },
    ['f82'] = { topSpeed = 0.4, accel = 0.4, handling = 0.2, braking = 0.1 },
    ['e92'] = { topSpeed = 0.3, accel = 0.3, handling = 0.1, braking = 0.1 },
    ['m2f22'] = { topSpeed = 0.2, accel = 0.2, handling = 0.2, braking = 0.1 },
    ['wraith'] = { topSpeed = -0.2, accel = -0.2, handling = -0.1, braking = 0.2 },
}

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function hashString(modelName)
    local total = 0
    for i = 1, #modelName do
        total = total + string.byte(modelName, i)
    end
    return total % 100
end

local function generateVehicleStats(modelName, vehicleClass, price)
    local band = REALISTIC_CLASS_BANDS[vehicleClass] or REALISTIC_CLASS_BANDS.C
    local seed = hashString(tostring(modelName or '')) / 100
    local priceFactor = clamp((price or 20000) / 140000, 0, 1)
    local bias = MODEL_TUNING_BIAS[(tostring(modelName or ''):lower())] or {}

    local topSpeed = band.topSpeed + (seed * 0.4 - 0.2) + (priceFactor * 0.5) + (bias.topSpeed or 0)
    local accel = band.accel + (seed * 0.3 - 0.15) + (priceFactor * 0.4) + (bias.accel or 0)
    local handling = band.handling + (seed * 0.3 - 0.15) + (bias.handling or 0)
    local braking = band.braking + (seed * 0.2 - 0.1) + (priceFactor * 0.2) + (bias.braking or 0)

    topSpeed = clamp(math.floor(topSpeed * 10 + 0.5) / 10, 3.5, 10.0)
    accel = clamp(math.floor(accel * 10 + 0.5) / 10, 3.2, 9.4)
    handling = clamp(math.floor(handling * 10 + 0.5) / 10, 5.2, 9.9)
    braking = clamp(math.floor(braking * 10 + 0.5) / 10, 4.8, 9.6)

    return {
        topSpeed = topSpeed,
        speed = topSpeed,
        accel = accel,
        acceleration = accel,
        handling = handling,
        braking = braking,
        brake = braking,
    }
end

local function applyRealisticVehicleStats()
    for _, group in pairs(SKGameVehicles) do
        for _, vehicle in ipairs(group) do
            if type(vehicle) == 'table' and vehicle.model then
                vehicle.stats = generateVehicleStats(vehicle.model, vehicle.class, vehicle.price)
            end
        end
    end
end

applyRealisticVehicleStats()