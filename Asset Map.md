# Project Z asset map

The library contains 178 catalog entries and 877 GLB files. This includes 52 first-phase entries and 89 separate collision helper files.

Each `res://` path is relative to the `PROJECT_Z` Godot project. The main GLB is a starting point. Other files in the folder contain standalone kit pieces, visual variants, or levels of detail when supplied.

Files under `collision/` are reference meshes for building Godot collision shapes. Gameplay behavior and physics setup are separate from the model files.

The source is the ASSET CATALOG sheet in Project_Z_3D_Asset_Register_and_Prompts.xlsx. The source ZIPs and Blender scripts are stored outside the game project.

## Buildings (66)

| ID | Asset | Priority | Files | Main GLB | Godot folder |
| --- | --- | --- | ---: | --- | --- |
| PZ-001 | Wall panel 4m solid | P0 | 2 | `ProjectZ_Wall_4m_Intact.glb` | `res://assets/buildings/modular_architecture/pz_001_wall_panel_4m_solid/` |
| PZ-002 | Wall panel with window | P0 | 1 | `PROJECT_Z_WallPanel_Window_4x3.glb` | `res://assets/buildings/modular_architecture/pz_002_wall_panel_with_window/` |
| PZ-003 | Wall panel with doorway | P0 | 1 | `PROJECT_Z_Wall_4x3_Doorway_0p9x2p1.glb` | `res://assets/buildings/modular_architecture/pz_003_wall_panel_with_doorway/` |
| PZ-004 | Floor and ceiling tiles | P0 | 6 | `PZ_Floor_Ceiling_Kit_4m.glb` | `res://assets/buildings/modular_architecture/pz_004_floor_and_ceiling_tiles/` |
| PZ-005 | Roof kit pitched and flat | P0 | 2 | `PROJECT_Z_Roof_Kit_Pitched_Flat.glb` | `res://assets/buildings/modular_architecture/pz_005_roof_kit_pitched_and_flat/` |
| PZ-006 | Door frame and hinged door | P0 | 1 | `ProjectZ_NG26_ExteriorDoor.glb` | `res://assets/buildings/modular_architecture/pz_006_door_frame_and_hinged_door/` |
| PZ-007 | Window frame and glass | P0 | 2 | `PROJECT_Z_Window_Frame_Glass_Blinds.glb` | `res://assets/buildings/modular_architecture/pz_007_window_frame_and_glass/` |
| PZ-008 | Staircase and railing kit | P0 | 1 | `PROJECT_Z_Staircase_Railing_Kit.glb` | `res://assets/buildings/modular_architecture/pz_008_staircase_and_railing_kit/` |
| PZ-009 | Balcony and awning kit | P1 | 1 | `ProjectZ_Balcony_Awning_Kit.glb` | `res://assets/buildings/modular_architecture/pz_009_balcony_and_awning_kit/` |
| PZ-010 | Interior partition wall kit | P0 | 6 | `PROJECT_Z_InteriorPartition_CompleteKit.glb` | `res://assets/buildings/modular_architecture/pz_010_interior_partition_wall_kit/` |
| PZ-011 | Apartment exterior facade kit | P1 | 7 | `PROJECT_Z_Keldvale_ThreeFloor_Apartment_Facade_Kit.glb` | `res://assets/buildings/modular_architecture/pz_011_apartment_exterior_facade_kit/` |
| PZ-012 | Concrete pillar and beam kit | P0 | 15 | `PZ_Concrete_Pillar_Beam_Kit_ALL.glb` | `res://assets/buildings/modular_architecture/pz_012_concrete_pillar_and_beam_kit/` |
| PZ-013 | Brick storefront facade | P1 | 1 | `PROJECT_Z_BrickStorefront.glb` | `res://assets/buildings/modular_architecture/pz_013_brick_storefront_facade/` |
| PZ-014 | Industrial metal siding kit | P1 | 17 | `PROJECT_Z_Industrial_Metal_Siding_Kit.glb` | `res://assets/buildings/modular_architecture/pz_014_industrial_metal_siding_kit/` |
| PZ-015 | Glass curtain-wall facade kit | P2 | 1 | `PROJECT_Z_Glass_CurtainWall_Facade_Kit.glb` | `res://assets/buildings/modular_architecture/pz_015_glass_curtain_wall_facade_kit/` |
| PZ-016 | Elevator door and shaft kit | P2 | 1 | `ProjectZ_Elevator_Door_Shaft_Kit.glb` | `res://assets/buildings/modular_architecture/pz_016_elevator_door_and_shaft_kit/` |
| PZ-017 | Fire-escape staircase kit | P1 | 2 | `ProjectZ_ESC30_FireEscape.glb` | `res://assets/buildings/modular_architecture/pz_017_fire_escape_staircase_kit/` |
| PZ-018 | Fence and gate kit | P0 | 1 | `PROJECT_Z_Fence_and_Gate_Kit.glb` | `res://assets/buildings/modular_architecture/pz_018_fence_and_gate_kit/` |
| PZ-019 | Interior trim and skirting kit | P1 | 17 | `PZ_InteriorTrim_CompleteKit.glb` | `res://assets/buildings/modular_architecture/pz_019_interior_trim_and_skirting_kit/` |
| PZ-020 | Damage overlay architectural kit | P1 | 1 | `PROJECT_Z_DamageOverlayKit.glb` | `res://assets/buildings/modular_architecture/pz_020_damage_overlay_architectural_kit/` |
| PZ-021 | Two-storey suburban house | P0 | 4 | `PZ_Suburban_House_8x12_Complete.glb` | `res://assets/buildings/points_of_interest/pz_021_two_storey_suburban_house/` |
| PZ-022 | Small grocery store | P0 | 6 | `PROJECT_Z_Northline_Corner_Market_10x14.glb` | `res://assets/buildings/points_of_interest/pz_022_small_grocery_store/` |
| PZ-023 | Village farmhouse and barn | P1 | 4 | `PROJECT_Z_Alderbrook_Farmhouse_Barn_Kit.glb` | `res://assets/buildings/points_of_interest/pz_023_village_farmhouse_and_barn/` |
| PZ-024 | Detached garage and workshop | P0 | 1 | `PROJECT_Z_Detached_Garage_Workshop.glb` | `res://assets/buildings/points_of_interest/pz_024_detached_garage_and_workshop/` |
| PZ-025 | Rural police station | P1 | 2 | `ProjectZ_RP16_RuralPoliceStation.glb` | `res://assets/buildings/points_of_interest/pz_025_rural_police_station/` |
| PZ-026 | Medical clinic | P1 | 1 | `PROJECT_Z_Medical_Clinic.glb` | `res://assets/buildings/points_of_interest/pz_026_medical_clinic/` |
| PZ-027 | Small hospital wing | P2 | 2 | `PROJECT_Z_Small_Hospital_Wing.glb` | `res://assets/buildings/points_of_interest/pz_027_small_hospital_wing/` |
| PZ-028 | Village school | P1 | 1 | `PROJECT_Z_VillageSchool.glb` | `res://assets/buildings/points_of_interest/pz_028_village_school/` |
| PZ-029 | Warehouse building | P1 | 1 | `ProjectZ_Warehouse_Building.glb` | `res://assets/buildings/points_of_interest/pz_029_warehouse_building/` |
| PZ-030 | Gas station building | P1 | 10 | `CW24_01_Store_Shell_12x8m.glb` | `res://assets/buildings/points_of_interest/pz_030_gas_station_building/` |
| PZ-031 | Multi-storey parking garage | P2 | 3 | `PZ_MorrowPark_Combined_Floor_and_Ramp.glb` | `res://assets/buildings/points_of_interest/pz_031_multi_storey_parking_garage/` |
| PZ-032 | Midrise apartment shell | P1 | 11 | `PZ_Midrise_TypicalStorey_Repeatable.glb` | `res://assets/buildings/points_of_interest/pz_032_midrise_apartment_shell/` |
| PZ-033 | Office tower facade module | P2 | 6 | `PROJECT_Z_Office_Tower_Facade_Module.glb` | `res://assets/buildings/points_of_interest/pz_033_office_tower_facade_module/` |
| PZ-034 | Shopping mall interior corridor | P2 | 2 | `ProjectZ_MALL12_ShoppingMallConcourse.glb` | `res://assets/buildings/points_of_interest/pz_034_shopping_mall_interior_corridor/` |
| PZ-035 | University laboratory building | P2 | 1 | `PROJECT_Z_University_Laboratory_Building.glb` | `res://assets/buildings/points_of_interest/pz_035_university_laboratory_building/` |
| PZ-036 | Fire station building | P1 | 2 | `PROJECT_Z_Fire_Station.glb` | `res://assets/buildings/points_of_interest/pz_036_fire_station_building/` |
| PZ-037 | Historic town hall | P2 | 1 | `PROJECT_Z_HistoricTownHall.glb` | `res://assets/buildings/points_of_interest/pz_037_historic_town_hall/` |
| PZ-038 | Riverside fishing cabin | P1 | 1 | `ProjectZ_Riverside_Fishing_Cabin.glb` | `res://assets/buildings/points_of_interest/pz_038_riverside_fishing_cabin/` |
| PZ-058 | Metro turnstiles and ticket hall | P2 | 1 | `PROJECT_Z_Metro_Turnstiles_and_Ticket_Hall.glb` | `res://assets/buildings/rail_facilities/pz_058_metro_turnstiles_and_ticket_hall/` |
| PZ-062 | Rail station building | P2 | 15 | `PZ_Greyhaven_Station_Layout_REFERENCE.glb` | `res://assets/buildings/rail_facilities/pz_062_rail_station_building/` |
| PZ-064 | Train yard service depot | P2 | 1 | `ProjectZ_Train_Yard_Service_Depot.glb` | `res://assets/buildings/rail_facilities/pz_064_train_yard_service_depot/` |
| PZ-066 | Airport terminal facade kit | P2 | 6 | `PROJECT_Z_Airport_Terminal_Facade_KIT_ALL.glb` | `res://assets/buildings/airport/pz_066_airport_terminal_facade_kit/` |
| PZ-067 | Airport jet bridge | P2 | 1 | `PZ_Airport_JetBridge.glb` | `res://assets/buildings/airport/pz_067_airport_jet_bridge/` |
| PZ-068 | Airport control tower | P2 | 1 | `PROJECT_Z_Airport_Control_Tower.glb` | `res://assets/buildings/airport/pz_068_airport_control_tower/` |
| PZ-069 | Aircraft hangar | P2 | 1 | `PROJECT_Z_Aircraft_Hangar_H04.glb` | `res://assets/buildings/airport/pz_069_aircraft_hangar/` |
| PZ-072 | Cargo port quay kit | P2 | 2 | `ProjectZ_QY10_CargoPortQuay.glb` | `res://assets/buildings/harbor/pz_072_cargo_port_quay_kit/` |
| PZ-073 | Container gantry crane | P2 | 2 | `PROJECT_Z_Graywater_STS_Container_Crane.glb` | `res://assets/buildings/harbor/pz_073_container_gantry_crane/` |
| PZ-074 | Harbor warehouse and containers | P2 | 4 | `PROJECT_Z_Harbor_Warehouse_Containers_Kit.glb` | `res://assets/buildings/harbor/pz_074_harbor_warehouse_and_containers/` |
| PZ-075 | Fishing harbor pier and boats | P1 | 1 | `PROJECT_Z_Fishing_Harbor_Pier_and_Skiff.glb` | `res://assets/buildings/harbor/pz_075_fishing_harbor_pier_and_boats/` |
| PZ-076 | Lighthouse and coastal beacon | P2 | 3 | `PROJECT_Z_Lighthouse_CoastalBeacon_Master.glb` | `res://assets/buildings/harbor/pz_076_lighthouse_and_coastal_beacon/` |
| PZ-084 | Substation transformer yard | P2 | 1 | `PROJECT_Z_Substation_Transformer_Yard.glb` | `res://assets/buildings/utility_facilities/pz_084_substation_transformer_yard/` |
| PZ-087 | Dam floodgate module | P2 | 1 | `ProjectZ_Dam_Floodgate_Module.glb` | `res://assets/buildings/utility_facilities/pz_087_dam_floodgate_module/` |
| PZ-088 | Water treatment plant | P2 | 9 | `PZ_CFW_00_WaterTreatmentPlant_ASSEMBLED_REFERENCE.glb` | `res://assets/buildings/utility_facilities/pz_088_water_treatment_plant/` |
| PZ-091 | Wastewater sewer treatment kit | P2 | 8 | `PZ_WWT_03_Inspection_Chamber_3m.glb` | `res://assets/buildings/utility_facilities/pz_091_wastewater_sewer_treatment_kit/` |
| PZ-092 | Cell tower and antenna racks | P2 | 1 | `PZ_CellTower_AntennaRacks.glb` | `res://assets/buildings/utility_facilities/pz_092_cell_tower_and_antenna_racks/` |
| PZ-096 | Fortified gate and watchtower | P1 | 6 | `PROJECT_Z_Blackline_Fortified_Gate_Watchtower_KIT.glb` | `res://assets/buildings/base_building/pz_096_fortified_gate_and_watchtower/` |
| PZ-102 | Raised greenhouse frame | P1 | 1 | `ProjectZ_Raised_Greenhouse_Frame.glb` | `res://assets/buildings/base_building/pz_102_raised_greenhouse_frame/` |
| PZ-110 | Small prefab shelter cabin | P0 | 1 | `PZ_Small_Prefab_Shelter.glb` | `res://assets/buildings/base_building/pz_110_small_prefab_shelter_cabin/` |
| PZ-140 | Volcanic observatory and seismic station | P2 | 5 | `PZ_Volcanic_Observatory_Complete_Kit.glb` | `res://assets/buildings/landmarks/pz_140_volcanic_observatory_and_seismic_station/` |
| PZ-169 | City stadium exterior kit | P2 | 7 | `PROJECT_Z_CityStadium_Master.glb` | `res://assets/buildings/landmarks/pz_169_city_stadium_exterior_kit/` |
| PZ-170 | Amusement park ferris wheel | P2 | 2 | `PROJECT_Z_FW40_Skyring_Ferris_Wheel.glb` | `res://assets/buildings/landmarks/pz_170_amusement_park_ferris_wheel/` |
| PZ-172 | Military checkpoint kit | P1 | 13 | `PZ_Checkpoint_ALL_Modules_Catalog.glb` | `res://assets/buildings/landmarks/pz_172_military_checkpoint_kit/` |
| PZ-173 | Prison gate and courtyard | P2 | 1 | `PZ_Prison_Gate_Courtyard_RC26.glb` | `res://assets/buildings/landmarks/pz_173_prison_gate_and_courtyard/` |
| PZ-174 | Remote radio tower compound | P2 | 9 | `PZ_RAD_00_Remote_Radio_Compound_Combined.glb` | `res://assets/buildings/landmarks/pz_174_remote_radio_tower_compound/` |
| PZ-175 | Mountain cable car station | P2 | 1 | `PROJECT_Z_Mountain_Cable_Car_Station.glb` | `res://assets/buildings/landmarks/pz_175_mountain_cable_car_station/` |
| PZ-178 | Seaside resort hotel lobby | P2 | 3 | `PZ_Seaside_Resort_Lobby.glb` | `res://assets/buildings/landmarks/pz_178_seaside_resort_hotel_lobby/` |

## Roads (23)

| ID | Asset | Priority | Files | Main GLB | Godot folder |
| --- | --- | --- | ---: | --- | --- |
| PZ-039 | Asphalt straight road module | P0 | 5 | `PROJECT_Z_Road_Straight_Asphalt_10m.glb` | `res://assets/roads/streets/pz_039_asphalt_straight_road_module/` |
| PZ-040 | Road intersection four-way | P0 | 6 | `PZ_FourWay_Junction_24m_COMPLETE.glb` | `res://assets/roads/streets/pz_040_road_intersection_four_way/` |
| PZ-041 | Road T junction | P0 | 1 | `PROJECT_Z_Road_T_Junction.glb` | `res://assets/roads/streets/pz_041_road_t_junction/` |
| PZ-042 | Sidewalk curb and ramp kit | P0 | 16 | `ProjectZ_SC20_SidewalkCurbRamp_Kit.glb` | `res://assets/roads/streets/pz_042_sidewalk_curb_and_ramp_kit/` |
| PZ-043 | Highway lane and barrier kit | P1 | 1 | `PROJECT_Z_Highway_Lane_and_Barrier_Kit.glb` | `res://assets/roads/streets/pz_043_highway_lane_and_barrier_kit/` |
| PZ-044 | Urban bridge road kit | P1 | 13 | `PZ_Urban_Bridge_Inspection_Catalog.glb` | `res://assets/roads/streets/pz_044_urban_bridge_road_kit/` |
| PZ-045 | Road tunnel portal and lining | P2 | 4 | `PROJECT_Z_RoadTunnel_Portal_Lining.glb` | `res://assets/roads/streets/pz_045_road_tunnel_portal_and_lining/` |
| PZ-046 | Traffic light signal set | P1 | 1 | `ProjectZ_Traffic_Light_Signal_Set.glb` | `res://assets/roads/streets/pz_046_traffic_light_signal_set/` |
| PZ-047 | Street lamp and utility pole | P0 | 4 | `PZ_Rural_Wooden_Utility_Pole_10m.glb` | `res://assets/roads/streets/pz_047_street_lamp_and_utility_pole/` |
| PZ-048 | Bus stop shelter | P1 | 7 | `PZ_MorrowTransit_BusShelter_COMPLETE.glb` | `res://assets/roads/streets/pz_048_bus_stop_shelter/` |
| PZ-049 | Road signs and markers kit | P0 | 1 | `PROJECT_Z_Road_Signs_and_Markers_Kit.glb` | `res://assets/roads/streets/pz_049_road_signs_and_markers_kit/` |
| PZ-050 | Drainage and manhole kit | P1 | 4 | `PROJECT_Z_Drainage_Manhole_Kit.glb` | `res://assets/roads/streets/pz_050_drainage_and_manhole_kit/` |
| PZ-051 | Crash barrier wreckage kit | P1 | 2 | `ProjectZ_CBW26_CrashBarrierWreckage.glb` | `res://assets/roads/streets/pz_051_crash_barrier_wreckage_kit/` |
| PZ-052 | Urban alley service kit | P1 | 11 | `PROJECT_Z_UrbanAlley_ServiceKit.glb` | `res://assets/roads/streets/pz_052_urban_alley_service_kit/` |
| PZ-053 | Railway track straight | P1 | 1 | `ProjectZ_Railway_Track_Straight_10m.glb` | `res://assets/roads/rail_and_metro/pz_053_railway_track_straight/` |
| PZ-054 | Railway turnout switch | P2 | 4 | `PROJECT_Z_Railway_RightHand_Turnout_28m_COMPLETE.glb` | `res://assets/roads/rail_and_metro/pz_054_railway_turnout_switch/` |
| PZ-055 | Rail bridge and viaduct | P2 | 15 | `PZ_Rail_Viaduct_10m_Assembled_Example.glb` | `res://assets/roads/rail_and_metro/pz_055_rail_bridge_and_viaduct/` |
| PZ-056 | Metro tunnel kit | P2 | 7 | `PZ_MorrowMetro_DoubleTrackTunnel_10m_COMPLETE.glb` | `res://assets/roads/rail_and_metro/pz_056_metro_tunnel_kit/` |
| PZ-057 | Metro station platform kit | P2 | 6 | `PZ_MetroStation_Platform_10m_Straight.glb` | `res://assets/roads/rail_and_metro/pz_057_metro_station_platform_kit/` |
| PZ-063 | Rail crossing barrier | P1 | 1 | `PZ_Rail_Crossing_XR04.glb` | `res://assets/roads/rail_and_metro/pz_063_rail_crossing_barrier/` |
| PZ-065 | Airport runway and taxiway kit | P2 | 11 | `PZ_Airfield_Modular_Kit_Catalog.glb` | `res://assets/roads/airfield/pz_065_airport_runway_and_taxiway_kit/` |
| PZ-071 | Airport runway lights | P2 | 10 | `PZ_Airport_Runway_Lights_Full_Kit.glb` | `res://assets/roads/airfield/pz_071_airport_runway_lights/` |
| PZ-176 | Volcanic lava observatory bridge | P2 | 16 | `PZ_Caldera_13_Module_Inspection_Catalog.glb` | `res://assets/roads/bridges/pz_176_volcanic_lava_observatory_bridge/` |

## Vehicles (21)

| ID | Asset | Priority | Files | Main GLB | Godot folder |
| --- | --- | --- | ---: | --- | --- |
| PZ-059 | Metro train carriage | P2 | 1 | `PROJECT_Z_Metro_Train_Carriage.glb` | `res://assets/vehicles/rail/pz_059_metro_train_carriage/` |
| PZ-060 | Freight train locomotive | P2 | 2 | `ProjectZ_ARD4826_FreightLocomotive.glb` | `res://assets/vehicles/rail/pz_060_freight_train_locomotive/` |
| PZ-061 | Freight wagon and container | P2 | 3 | `PROJECT_Z_FreightWagon_Container_Master.glb` | `res://assets/vehicles/rail/pz_061_freight_wagon_and_container/` |
| PZ-070 | Airport ground-service cart | P2 | 9 | `PZ_Baggage_Trolley.glb` | `res://assets/vehicles/airport_service/pz_070_airport_ground_service_cart/` |
| PZ-141 | Sedan car | P1 | 2 | `PROJECT_Z_Unbranded_2026_Sedan_CloseUp.glb` | `res://assets/vehicles/road/pz_141_sedan_car/` |
| PZ-142 | Pickup truck | P1 | 2 | `PROJECT_Z_Korvex_KX4_Pickup_Truck.glb` | `res://assets/vehicles/road/pz_142_pickup_truck/` |
| PZ-143 | Motorcycle | P1 | 2 | `ProjectZ_BIKE26_DualSportMotorcycle.glb` | `res://assets/vehicles/road/pz_143_motorcycle/` |
| PZ-144 | City bus | P2 | 2 | `PROJECT_Z_City_Bus.glb` | `res://assets/vehicles/road/pz_144_city_bus/` |
| PZ-145 | Ambulance | P1 | 4 | `PZ_Greyhaven_EMS_Ambulance_07.glb` | `res://assets/vehicles/road/pz_145_ambulance/` |
| PZ-146 | Police patrol car | P1 | 2 | `PROJECT_Z_Police_Patrol_Sedan.glb` | `res://assets/vehicles/road/pz_146_police_patrol_car/` |
| PZ-147 | Fire engine | P2 | 1 | `ProjectZ_Fire_Engine.glb` | `res://assets/vehicles/road/pz_147_fire_engine/` |
| PZ-148 | Cargo semi-truck | P2 | 7 | `PZ_IRONVALE_IV630_DV136_ASSEMBLED_REFERENCE.glb` | `res://assets/vehicles/road/pz_148_cargo_semi_truck/` |
| PZ-149 | Farm tractor | P1 | 6 | `PZ_FIELDWARD_75D_Tractor_COMPLETE.glb` | `res://assets/vehicles/utility/pz_149_farm_tractor/` |
| PZ-150 | Excavator | P2 | 1 | `PZ_Excavator_DF180.glb` | `res://assets/vehicles/utility/pz_150_excavator/` |
| PZ-151 | Fishing motorboat | P2 | 2 | `PZ_BOAT_01_Tideline520_Fishing_Motorboat.glb` | `res://assets/vehicles/water/pz_151_fishing_motorboat/` |
| PZ-152 | Speedboat | P2 | 1 | `PZ_Rescue_Speedboat.glb` | `res://assets/vehicles/water/pz_152_speedboat/` |
| PZ-153 | Transport helicopter | P2 | 1 | `PROJECT_Z_Transport_Helicopter.glb` | `res://assets/vehicles/aircraft/pz_153_transport_helicopter/` |
| PZ-154 | Regional turboprop airplane | P2 | 2 | `PROJECT_Z_K28_Regional_Twin_Turboprop.glb` | `res://assets/vehicles/aircraft/pz_154_regional_turboprop_airplane/` |
| PZ-155 | Armored utility truck | P2 | 3 | `PZ_Ironveil6_Armored_Truck_Hero.glb` | `res://assets/vehicles/utility/pz_155_armored_utility_truck/` |
| PZ-171 | Harbor container ship | P2 | 2 | `PROJECT_Z_Harbor_Container_Ship.glb` | `res://assets/vehicles/water/pz_171_harbor_container_ship/` |
| PZ-177 | Post-apocalypse wrecked aircraft | P2 | 2 | `PROJECT_Z_Mistral_AR6_Wrecked_Aircraft.glb` | `res://assets/vehicles/aircraft/pz_177_post_apocalypse_wrecked_aircraft/` |

## Characters (5)

| ID | Asset | Priority | Files | Main GLB | Godot folder |
| --- | --- | --- | ---: | --- | --- |
| PZ-156 | Playable survivor male body | P0 | 3 | `ProjectZ_SurvivorMale_Urban_UNRIGGED.glb` | `res://assets/characters/survivors/pz_156_playable_survivor_male_body/` |
| PZ-157 | Playable survivor female body | P1 | 4 | `ProjectZ_SURV26_FemaleSurvivor_01_WeatheredOlive.glb` | `res://assets/characters/survivors/pz_157_playable_survivor_female_body/` |
| PZ-161 | Survivor clothing pack | P1 | 13 | `PZ_Survivor_01_Hoodie_Charcoal.glb` | `res://assets/characters/gear/pz_161_survivor_clothing_pack/` |
| PZ-162 | Tactical backpack and holster | P0 | 8 | `PZ_MorrowTrail35_Backpack_COMPLETE.glb` | `res://assets/characters/gear/pz_162_tactical_backpack_and_holster/` |
| PZ-168 | Wilderness animal deer | P2 | 3 | `PZ_Red_Deer_Adult_Stag_LOD0_UNRIGGED.glb` | `res://assets/characters/wildlife/pz_168_wilderness_animal_deer/` |

## Zombies (3)

| ID | Asset | Priority | Files | Main GLB | Godot folder |
| --- | --- | --- | ---: | --- | --- |
| PZ-158 | Common infected civilian | P0 | 1 | `PROJECT_Z_Common_Infected_Civilian.glb` | `res://assets/zombies/pz_158_common_infected_civilian/` |
| PZ-159 | Infected worker variant | P1 | 2 | `PZ_Infected_Construction_Worker_09_UNRIGGED.glb` | `res://assets/zombies/pz_159_infected_worker_variant/` |
| PZ-160 | Infected medic variant | P1 | 2 | `ProjectZ_Infected_Medic_Variant_Runtime_Optimized.glb` | `res://assets/zombies/pz_160_infected_medic_variant/` |

## Props (60)

| ID | Asset | Priority | Files | Main GLB | Godot folder |
| --- | --- | --- | ---: | --- | --- |
| PZ-077 | Diesel generator | P0 | 2 | `PROJECT_Z_BRACKEN_DG6500_Diesel_Generator.glb` | `res://assets/props/utilities_and_industry/pz_077_diesel_generator/` |
| PZ-078 | Solar panel array | P0 | 6 | `PZ_HelioVale_HX180_2x2_SolarArray_REFERENCE.glb` | `res://assets/props/utilities_and_industry/pz_078_solar_panel_array/` |
| PZ-079 | Battery rack and inverter | P0 | 1 | `PZ_Battery_Rack_HG48.glb` | `res://assets/props/utilities_and_industry/pz_079_battery_rack_and_inverter/` |
| PZ-080 | Water storage barrel and tank | P0 | 5 | `PZ_Water_Storage_Complete_Kit.glb` | `res://assets/props/utilities_and_industry/pz_080_water_storage_barrel_and_tank/` |
| PZ-081 | Water filter and pump | P0 | 7 | `PROJECT_Z_Fieldline_Water_Filter_Pump_KIT.glb` | `res://assets/props/utilities_and_industry/pz_081_water_filter_and_pump/` |
| PZ-082 | Electrical distribution cabinet | P1 | 2 | `PROJECT_Z_Electrical_Distribution_Cabinet.glb` | `res://assets/props/utilities_and_industry/pz_082_electrical_distribution_cabinet/` |
| PZ-083 | Power line tower and transformer | P1 | 6 | `ProjectZ_PLT35_PowerPylonAndTransformer.glb` | `res://assets/props/utilities_and_industry/pz_083_power_line_tower_and_transformer/` |
| PZ-085 | Wind turbine | P2 | 2 | `PZ_Ravenwind_RW112_Wind_Turbine.glb` | `res://assets/props/utilities_and_industry/pz_085_wind_turbine/` |
| PZ-086 | Small hydro turbine and sluice | P2 | 3 | `PROJECT_Z_MicroHydro_Sluice_Turbine_Master.glb` | `res://assets/props/utilities_and_industry/pz_086_small_hydro_turbine_and_sluice/` |
| PZ-089 | Fuel tank and pump station | P1 | 8 | `PZ_MorrowFuel_Tanks_Bund_PumpStation_COMPLETE.glb` | `res://assets/props/utilities_and_industry/pz_089_fuel_tank_and_pump_station/` |
| PZ-090 | Factory production line | P2 | 1 | `PZ_Factory_Production_Line_IV26.glb` | `res://assets/props/utilities_and_industry/pz_090_factory_production_line/` |
| PZ-093 | Industrial pipe and valve kit | P1 | 1 | `PROJECT_Z_Industrial_Pipe_Valve_Kit.glb` | `res://assets/props/utilities_and_industry/pz_093_industrial_pipe_and_valve_kit/` |
| PZ-094 | Greenhouse irrigation equipment | P1 | 6 | `PROJECT_Z_Greenhouse_Irrigation_GIK01_KIT.glb` | `res://assets/props/utilities_and_industry/pz_094_greenhouse_irrigation_equipment/` |
| PZ-095 | Wooden barricade kit | P0 | 4 | `PROJECT_Z_Wooden_Barricade_Kit_3_Variations.glb` | `res://assets/props/base_building/pz_095_wooden_barricade_kit/` |
| PZ-097 | Crafting workbench | P0 | 11 | `PROJECT_Z_Crafting_Workbench.glb` | `res://assets/props/base_building/pz_097_crafting_workbench/` |
| PZ-098 | Storage shelving and crate | P0 | 16 | `ProjectZ_STOR26_StorageProps.glb` | `res://assets/props/base_building/pz_098_storage_shelving_and_crate/` |
| PZ-099 | Camp cooking stove | P0 | 1 | `PROJECT_Z_Camp_Cooking_Stove.glb` | `res://assets/props/base_building/pz_099_camp_cooking_stove/` |
| PZ-100 | Rainwater harvesting kit | P0 | 20 | `PZ_Rainwater_17_Module_Inspection_Catalog.glb` | `res://assets/props/base_building/pz_100_rainwater_harvesting_kit/` |
| PZ-101 | Vegetable garden plot | P0 | 6 | `PROJECT_Z_VegetableGarden_Kit_Catalogue.glb` | `res://assets/props/base_building/pz_101_vegetable_garden_plot/` |
| PZ-103 | Small compost bin | P1 | 5 | `PZ_Mossfield_CompostBin_110cm_COMPLETE.glb` | `res://assets/props/base_building/pz_103_small_compost_bin/` |
| PZ-104 | Wooden perimeter palisade | P1 | 10 | `PZ_Palisade_Modular_Catalog.glb` | `res://assets/props/base_building/pz_104_wooden_perimeter_palisade/` |
| PZ-105 | Water well and hand pump | P1 | 1 | `PZ_Water_Well_Hand_Pump_HWP26.glb` | `res://assets/props/base_building/pz_105_water_well_and_hand_pump/` |
| PZ-106 | Medical treatment bed | P0 | 4 | `PZ_MED_00_Combined_Kit.glb` | `res://assets/props/base_building/pz_106_medical_treatment_bed/` |
| PZ-107 | Tool repair station | P1 | 1 | `PZ_Tool_Repair_Station.glb` | `res://assets/props/base_building/pz_107_tool_repair_station/` |
| PZ-108 | Smoker and food drying rack | P1 | 3 | `PROJECT_Z_MR26_Smoker_And_Drying_Rack_KIT.glb` | `res://assets/props/base_building/pz_108_smoker_and_food_drying_rack/` |
| PZ-109 | Base security alarm | P1 | 5 | `PZ_Base_Security_Alarm_Complete_Kit.glb` | `res://assets/props/base_building/pz_109_base_security_alarm/` |
| PZ-111 | Sofa and armchair kit | P0 | 4 | `PROJECT_Z_FIELDHAVEN_Sofa_Armchair_KIT.glb` | `res://assets/props/interiors_and_street_props/pz_111_sofa_and_armchair_kit/` |
| PZ-112 | Kitchen cabinet set | P0 | 10 | `PROJECT_Z_Kitchen_Cabinet_Set.glb` | `res://assets/props/interiors_and_street_props/pz_112_kitchen_cabinet_set/` |
| PZ-113 | Bed and bedside table | P0 | 5 | `ProjectZ_BED26_BedBedsideLamp.glb` | `res://assets/props/interiors_and_street_props/pz_113_bed_and_bedside_table/` |
| PZ-114 | Bathroom fixture kit | P1 | 1 | `PROJECT_Z_Bathroom_Fixture_Kit.glb` | `res://assets/props/interiors_and_street_props/pz_114_bathroom_fixture_kit/` |
| PZ-115 | Dining table and chair | P0 | 7 | `PZ_Dining_4_Seat_Inspection_Assembly.glb` | `res://assets/props/interiors_and_street_props/pz_115_dining_table_and_chair/` |
| PZ-116 | Metal locker and cabinet | P0 | 3 | `PROJECT_Z_Metal_Locker_Cabinet_Master.glb` | `res://assets/props/interiors_and_street_props/pz_116_metal_locker_and_cabinet/` |
| PZ-117 | Office desk and computer | P1 | 1 | `ProjectZ_Office_Desk_Computer.glb` | `res://assets/props/interiors_and_street_props/pz_117_office_desk_and_computer/` |
| PZ-118 | Hospital bed and trolley | P1 | 7 | `PZ_LUCENT_HospitalBed_And_Trolley_REFERENCE.glb` | `res://assets/props/interiors_and_street_props/pz_118_hospital_bed_and_trolley/` |
| PZ-119 | Supermarket shelf kit | P0 | 7 | `PZ_Market_ALL_2m_Modules_Catalog.glb` | `res://assets/props/interiors_and_street_props/pz_119_supermarket_shelf_kit/` |
| PZ-120 | Wooden crates and pallets | P0 | 7 | `PZ_Wooden_Crates_Pallets_CP26.glb` | `res://assets/props/interiors_and_street_props/pz_120_wooden_crates_and_pallets/` |
| PZ-121 | Dumpster and trash bags | P1 | 8 | `PZ_DST_00_Dumpster_Trash_Kit_Combined.glb` | `res://assets/props/interiors_and_street_props/pz_121_dumpster_and_trash_bags/` |
| PZ-122 | Street bench and trash can | P1 | 4 | `PZ_StreetBench_TrashCan.glb` | `res://assets/props/interiors_and_street_props/pz_122_street_bench_and_trash_can/` |
| PZ-123 | Fuel pump dispenser | P1 | 1 | `PROJECT_Z_Fuel_Pump_Dispenser.glb` | `res://assets/props/interiors_and_street_props/pz_123_fuel_pump_dispenser/` |
| PZ-124 | Emergency signage and posters | P1 | 11 | `PROJECT_Z_ES26_ALL_Signage_Posters_KIT.glb` | `res://assets/props/interiors_and_street_props/pz_124_emergency_signage_and_posters/` |
| PZ-125 | Building ventilation and AC units | P1 | 6 | `PZ_Building_HVAC_Complete_Kit.glb` | `res://assets/props/interiors_and_street_props/pz_125_building_ventilation_and_ac_units/` |
| PZ-126 | First-aid and loot item kit | P0 | 10 | `PROJECT_Z_FirstAid_Loot_Kit_Master.glb` | `res://assets/props/interiors_and_street_props/pz_126_first_aid_and_loot_item_kit/` |
| PZ-127 | Temperate broadleaf tree | P0 | 5 | `PROJECT_Z_Temperate_Oak_Tree_LOD0.glb` | `res://assets/props/nature/pz_127_temperate_broadleaf_tree/` |
| PZ-128 | Conifer tree | P0 | 5 | `ProjectZ_PINE10_Conifer_Summer_LOD0.glb` | `res://assets/props/nature/pz_128_conifer_tree/` |
| PZ-129 | Shrub and undergrowth kit | P0 | 19 | `PROJECT_Z_Shrub_Undergrowth_Kit_CATALOG_2K.glb` | `res://assets/props/nature/pz_129_shrub_and_undergrowth_kit/` |
| PZ-130 | Rock and boulder kit | P0 | 26 | `PZ_Rock_Boulder_8_Shape_Catalog.glb` | `res://assets/props/nature/pz_130_rock_and_boulder_kit/` |
| PZ-131 | Fallen log and stump kit | P0 | 10 | `PROJECT_Z_FallenLogStump_Master.glb` | `res://assets/props/nature/pz_131_fallen_log_and_stump_kit/` |
| PZ-132 | Riverbank rocks and driftwood | P1 | 1 | `ProjectZ_Riverbank_Rocks_Driftwood.glb` | `res://assets/props/nature/pz_132_riverbank_rocks_and_driftwood/` |
| PZ-133 | Farm crops growth stages | P1 | 17 | `PZ_Crops_All16_REFERENCE.glb` | `res://assets/props/nature/pz_133_farm_crops_growth_stages/` |
| PZ-134 | Swamp vegetation kit | P2 | 12 | `PZ_Swamp_Vegetation_10Variant_Catalog.glb` | `res://assets/props/nature/pz_134_swamp_vegetation_kit/` |
| PZ-135 | Desert and dryland kit | P2 | 13 | `PZ_Desert_Dryland_Scatter_DK26.glb` | `res://assets/props/nature/pz_135_desert_and_dryland_kit/` |
| PZ-136 | Alpine vegetation kit | P2 | 15 | `PZ_ALP_00_Alpine_Vegetation_ALL_Combined.glb` | `res://assets/props/nature/pz_136_alpine_vegetation_kit/` |
| PZ-137 | Snow-covered trees kit | P2 | 5 | `PZ_SnowTrees_Kit.glb` | `res://assets/props/nature/pz_137_snow_covered_trees_kit/` |
| PZ-138 | Cave entrance rock kit | P2 | 1 | `PROJECT_Z_Cave_Entrance_Rock_Kit.glb` | `res://assets/props/nature/pz_138_cave_entrance_rock_kit/` |
| PZ-139 | Volcanic basalt and lava rocks | P2 | 11 | `PROJECT_Z_VR26_Volcanic_Basalt_Lava_ALL_KIT.glb` | `res://assets/props/nature/pz_139_volcanic_basalt_and_lava_rocks/` |
| PZ-163 | Handheld flashlight | P0 | 1 | `PZ_Handheld_Flashlight_BT26.glb` | `res://assets/props/gear/pz_163_handheld_flashlight/` |
| PZ-164 | Simple hammer and crowbar | P0 | 4 | `PZ_TOOL_00_Hammer_Crowbar_Combined.glb` | `res://assets/props/gear/pz_164_simple_hammer_and_crowbar/` |
| PZ-165 | Hunting knife and machete | P1 | 3 | `PZ_HuntingKnife_Machete.glb` | `res://assets/props/gear/pz_165_hunting_knife_and_machete/` |
| PZ-166 | Fictional civilian rifle | P1 | 1 | `PROJECT_Z_Fictional_Civilian_Rifle.glb` | `res://assets/props/gear/pz_166_fictional_civilian_rifle/` |
| PZ-167 | Medical kit and bandages wearable | P0 | 7 | `PZ_Medical_Pickups_Combined_Kit.glb` | `res://assets/props/gear/pz_167_medical_kit_and_bandages_wearable/` |
