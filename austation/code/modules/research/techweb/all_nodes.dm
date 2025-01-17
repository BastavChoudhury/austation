//Base Nodes

/datum/techweb_node/cyborg
	austation_design_ids_remove = list("borgupload")

/////////////////////////Bluespace tech/////////////////////////

/datum/techweb_node/bag_of_holding
	hidden = FALSE
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 10000)

/datum/techweb_node/quantum_spin
	hidden = FALSE
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 7500)

/datum/techweb_node/micro_bluespace
	austation_design_ids = list("bluespace_belt")

/datum/techweb_node/practical_bluespace
	austation_design_ids = list("BScustom_epi")

/datum/techweb_node/unregulated_bluespace
	austation_design_ids = list("bluespace_jar")

/////////////////////////Mining tech/////////////////////////

/datum/techweb_node/basic_mining
	austation_design_ids = list("minebot_fab")  //  adds the minebot_fab on top of the existing tech at this node

/datum/techweb_node/xpr_mining
	id = "xpr_mining"
	display_name = "Experimental Mining Technology"
	description = "Pushing the boundaries of what our mining equipment can do"
	prereq_ids = list("adv_mining")
	design_ids = list("mech_kinetic_accelerator", "hyperaoemod", "repeatermod", "resonatormod", "bountymod")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 1000)
	export_price = 5000

/datum/techweb_node/bluespace_mining
	id = "bluespace_mining"
	hidden = TRUE
	display_name = "Bluespace Mining Technology"
	description = "Harness the power of bluespace to make materials out of nothing. Slowly."
	prereq_ids = list("practical_bluespace", "adv_mining")
	design_ids = list("bluespace_miner")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)
	export_price = 5000

/datum/techweb_node/bluespace_mining/New() //Techweb nodes don't have an init,
	. = ..()

	hidden = !CONFIG_GET(flag/bsminer_researchable)

/////////////////////////Biotech/////////////////////////

/datum/techweb_node/adv_biotech
	austation_design_ids = list("custom_epi", "meddarter")

/datum/techweb_node/linkedsurgery_implant
	hidden = FALSE

/////////////////////////Advanced Surgery/////////////////////////

/datum/techweb_node/combat_cyber_implants
	hidden = FALSE
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 7500)

/datum/techweb_node/adv_combat_cyber_implants
	hidden = FALSE
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)

/datum/techweb_node/exp_surgery
	austation_design_ids = list("surgery_cortex_imprint", "surgery_cortex_folding")

/////////////////////////robotics tech/////////////////////////

/datum/techweb_node/cyborg_upg_util
	austation_design_ids = list("borg_upgrade_cooking")

/datum/techweb_node/ai
	austation_design_ids = list("dadbot_module", "rickroll_module", "dagothur_module", "crewsimov_module", "disboard_module")
	austation_design_ids_remove = list("aiupload")


////////////////////////mech technology////////////////////////

/datum/techweb_node/phazon
	hidden = FALSE
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 10000)

/datum/techweb_node/adv_mecha_tools
	austation_design_ids = list("mech_ion_thrusters")

////////////////////////bio processing////////////////////////

/datum/techweb_node/bio_process
	austation_design_ids = list("cake_printer")

/////////////////////////weaponry tech/////////////////////////

/datum/techweb_node/exotic_ammo
	hidden = FALSE
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)

/datum/techweb_node/beam_weapons
	hidden = FALSE
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)

/datum/techweb_node/adv_beam_weapons
	hidden = FALSE
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)

/datum/techweb_node/radioactive_weapons
	hidden = FALSE
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)

