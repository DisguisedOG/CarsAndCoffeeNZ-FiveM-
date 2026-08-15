SKSupercheap = SKSupercheap or {}

SKSupercheap.LOCATIONS = {
    {
        id = 'supercheap_downtown',
        coords = vector3(46.6713, -1749.1234, 29.3123),
        name = 'Supercheap Auto',
        blipSprite = 524,
        blipColor = 1,
    },
    {
        id = 'supercheap_paleto',
        coords = vector3(-130.4321, 6400.1234, 31.4321),
        name = 'Supercheap Auto (Paleto)',
        blipSprite = 524,
        blipColor = 1,
    }
}

SKSupercheap.CATALOG = {
    engine = {
        { id = 'spark_plugs_iridium', name = 'Iridium Spark Plugs', price = 150, type = 'consumable' },
        { id = 'engine_oil_5w30', name = 'Premium Synthetic Oil 5W-30', price = 80, type = 'consumable' },
        { id = 'air_filter_sport', name = 'High-Flow Air Filter', price = 120, type = 'part' },
    },
    turbo = {
        { id = 'turbo_wastegate_boost', name = 'Adjustable Wastegate actuator', price = 450, type = 'part' },
        { id = 'turbo_bov_baffle', name = 'Blow-Off Valve', price = 300, type = 'part' },
    },
    suspension = {
        { id = 'coilover_spring_firm', name = 'Stiffened Lowering Springs', price = 600, type = 'part' },
        { id = 'anti_roll_bar_rear', name = 'Rear Sway Bar Upgrade', price = 350, type = 'part' },
    },
    tools = {
        { id = 'mech_tool_workbench', name = 'Backyard Workbench', price = 1500, type = 'tool', prop = 'prop_tool_bench_02' },
        { id = 'mech_tool_lift', name = 'Hydraulic Car Lift', price = 3500, type = 'tool', prop = 'prop_car_lift_01' },
        { id = 'mech_tool_dyno', name = 'Compact Dyno Roller', price = 5000, type = 'tool', prop = 'prop_roadcone02a' },
        { id = 'mech_tool_psi_station', name = 'PSI Calibration Panel', price = 2500, type = 'tool', prop = 'prop_cabinet_02b' },
        { id = 'mech_tool_alignment', name = 'Wheel Alignment Rig', price = 1800, type = 'tool', prop = 'prop_wheel_01' },
        { id = 'mech_tool_turbo_bay', name = 'Turbo Calibration Desk', price = 3000, type = 'tool', prop = 'prop_laptop_01a' },
        { id = 'mech_tool_service_bay', name = 'Mechanic Service Lift', price = 2000, type = 'tool', prop = 'prop_crate_pile_01' }
    },
    consumables = {
        { id = 'regular_fuel_can', name = 'Regular Fuel Can (20L)', price = 50, type = 'consumable' },
        { id = 'red_fuel_can', name = 'Gumball Red Fuel Can (20L)', price = 250, type = 'consumable' }
    }
}
