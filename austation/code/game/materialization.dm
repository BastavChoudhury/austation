/obj/structure/table/mat_shiritori
	name = "\improper Materialization Shiritori"
	desc = "A magical Shiritori table capable of temporarily materializing any object that exists in this reality."
	icon = 'austation/icons/obj/structures/magic_table.dmi'
	icon_state = "magic_table"
	max_integrity = 300
	canSmoothWith = null
	flags_1 = NODECONSTRUCT_1
	var/current_letter = ""
	var/time_left = 40 SECONDS
	var/active = FALSE
	var/game_starting = FALSE // prep period
	var/start_time = 15 // how many seconds people get to opt in
	var/turns = 0 // how many turns have passed
	var/static/list/atom_list // starts off as empty, we only want to make this if we have a table, otherwise we're just wasting memory
	var/list/countdown_warns = list(50, 100, 150) // used in process(), list contains at what times we should announce time_left.
	var/list/spent_objs = list() // typepaths that have been used before
	var/list/entities = list() // spawned entities that are currently in existance
	var/list/players = list()
	var/mob/living/carbon/human/current_player
	var/list/knockouts = list()
	var/static/list/blacklist // handled in setup_blacklist(). Contains root paths that aren't supposed to be spawned (Yes, a bit of a pain to maintain, but it's not the end of the world if someone forgets to update it. The alternative is having a variable on every damn datum)

/obj/structure/table/mat_shiritori/Destroy()
	end_game()
	return ..()

/obj/structure/table/mat_shiritori/proc/prepare_game()
	if(active || game_starting)
		return
	setup_blacklist()
	players.len = 0
	knockouts.len = 0
	time_left = initial(time_left)
	say("Game starting in [start_time] seconds. Place your hand on the table to play.")
	start_game()

//  Called after everything is ready
/obj/structure/table/mat_shiritori/proc/start_game()
	set waitfor = FALSE
	game_starting = TRUE
	for(var/i in 1 to start_time)
		var/countdown = start_time - (i - 1)
		switch(countdown)
			if(5)
				say("Game starting in 5...")
			if(1 to 4)
				say("[countdown]...")
		sleep(10)
	for(var/mob/living/L as() in players)
		if(QDELETED(L) || L.stat == DEAD)
			remove_player(L)
			continue
	if(length(players) > 1)
		if(!atom_list)
			atom_list = generate_name_list(typesof(/atom/movable))
		active = TRUE
		current_player = pick(players)
		say("[current_player] will start.")
		to_chat(current_player, "<span class='notice'>It is now your turn.</span>")
		playsound(src, 'sound/effects/gong.ogg', 100, 0, 5)
		START_PROCESSING(SSobj, src)
	else
		say("Insufficient players")
		end_game()
	game_starting = FALSE

/obj/structure/table/mat_shiritori/proc/end_game()
	players.len = 0
	knockouts.len = 0
	spent_objs.len = 0
	turns = 0
	QDEL_LIST(entities)
	time_left = initial(time_left)
	countdown_warns = initial(countdown_warns)
	current_player = null
	for(var/mob/living/carbon/human/H in players)
		if(active)
			to_chat(H, "<span class='info'>The game has ended.</span>")
		REMOVE_TRAIT(H, TRAIT_PACIFISM, "shiritori")
	STOP_PROCESSING(SSobj, src)
	active = FALSE

/obj/structure/table/mat_shiritori/attack_hand(mob/user)
	if(!ishuman(user))
		return ..()
	if(active)
		to_chat(user, "<span class='info'>You can't join an active game.</span>")
	if(alert(user, "Would you like to [game_starting ? "join the" : "start a"] game of Materialization Shiritori?", "The gods", "Yes", "No") == "Yes")
		var/mob/living/carbon/human/H = user
		if(H.stat == DEAD || !H.mind?.hasSoul)
			return
		if(HAS_TRAIT(H, TRAIT_MUTE))
			to_chat(H, "<span class='warning'>You can't play if you can't speak!</span>")
			return
		if(!game_starting)
			prepare_game()
		else
			say("[H] has joined.")
		add_player(H)

/obj/structure/table/mat_shiritori/proc/player_say(datum/source, list/speech_args)
	SIGNAL_HANDLER
	if(source == current_player)
		INVOKE_ASYNC(src, .proc/find_object, speech_args[SPEECH_MESSAGE])

/obj/structure/table/mat_shiritori/proc/find_object(phrase as text)
	phrase = lowertext(phrase)
	if(length(current_letter) && phrase[1] != current_letter)
		visible_message("<span class='warning'>Invalid word, entity must begin with \an <b>[current_letter]</b></span>")
		return
	if(phrase[length(phrase)] == ".")
		phrase = copytext(phrase, 1, -1) // trims off the last character if it's a period
	var/regex/valid_end_letter = regex(@"[a-z]")
	if(!findtext(phrase, valid_end_letter, -1))
		visible_message("<span class='warning'>Word must end with a letter.</span>")
		return
	if(spent_objs[phrase])
		visible_message("<span class='warning'>\"[phrase]\" has already been materialized. <b>[current_player] has been eliminated!</b></span>")
		to_chat(current_player, "<span class='danger'>This has been said before, you've been eliminated!</span>")
		remove_player(current_player)
		return

	var/Opath = atom_list[phrase]
	if(!Opath)
		visible_message("<span class='warning'>Invalid entity.</span>")
		return
	if(islist(Opath))
		Opath -= blacklist
		Opath = pick(Opath)
	if(!Opath || blacklist[Opath])
		visible_message("<span class='warning'>Entity too vague or dangerous to summon.</span>")
		return
	var/obj/item/shiritori_ball/ball = new(loc)
	ball.prime_spawn(src, Opath, current_player)
	current_player.put_in_hands(ball)
	spent_objs[phrase] = Opath
	current_letter = phrase[length(phrase)]
	playsound(src, 'sound/magic/clockwork/invoke_general.ogg', 100, TRUE)
	switch_player()

/obj/structure/table/mat_shiritori/proc/add_player(mob/living/carbon/human/H)
	if(!istype(H))
		return
	if((H in players) || (H in knockouts))
		return
	players += H
	to_chat(H, "<span class='notice'>Welcome to <b>Materialization Shiritori!</b>\n \
				Similar to traditional Shiritori, but any valid word submitted by the player will materialize infront of them, as long as it exists in this world.</span>\n \
				<span class='info'>The last player standing is declared as the winner, players can be eliminated in 3 different ways:\n \
				<b>1:</b> Failing to name a valid entity within [initial(time_left) / 10] seconds of the last player's turn.\n \
				<b>2:</b> Attempting to summon an entity that has already been mentioned.\n \
				<b>3:</b> Death.\n \
				You cannot harm your opponents through <b>direct</b> means. All summoned entities will be destroyed once the game has concluded.</span>")
	ADD_TRAIT(H, TRAIT_PACIFISM, "shiritori")
	RegisterSignal(H, COMSIG_MOB_SAY, .proc/player_say)

/obj/structure/table/mat_shiritori/proc/remove_player(mob/living/carbon/human/H)
	players -= H
	knockouts += H
	if(H == current_player)
		switch_player(length(players) > 2)
	if(!QDELETED(H)) // in case they got gibbed or some other weird thing happened
		REMOVE_TRAIT(H, TRAIT_PACIFISM, "shiritori")
		UnregisterSignal(H, COMSIG_MOB_SAY)
	if(length(players) == 1) // squid game
		visible_message("<span class='boldannounce'>[current_player] has won the game!</span>")
		playsound(src, 'sound/effects/gong.ogg', 100, 0, 5)
		playsound(src, 'sound/effects/bamf.ogg', 100, 0, 5)
		end_game()


/obj/structure/table/mat_shiritori/proc/switch_player(alert = TRUE)
	current_player = next_list_item(current_player, players)
	time_left = initial(time_left)
	countdown_warns = initial(countdown_warns)
	if(QDELETED(current_player) || current_player.stat == DEAD)
		remove_player(current_player)
		return
	if(alert)
		if(turns)
			to_chat(current_player, "<span class='notice'>It is now your turn.</span>")
		else
			say("[current_player] is starting.")
			to_chat(current_player, "<span class='notice'>You're going first, you get to pick the first word.</span>")
	turns++
	playsound(src, 'sound/arcade/hit.ogg', 100, TRUE)

/obj/structure/table/mat_shiritori/process(delta_time)
	if(!active)
		return PROCESS_KILL
	for(var/mob/living/L as() in players)
		if(QDELETED(L) || L.stat == DEAD)
			remove_player(L)
			continue
	time_left -= delta_time SECONDS
	var/cdlen = length(countdown_warns)
	if(cdlen && time_left <= countdown_warns[cdlen])
		say("[countdown_warns[cdlen] * 0.1]...")
		countdown_warns.len--

	if(time_left <= 0)
		visible_message("<span class='warning'>[current_player] has ran out of time!</span>")
		playsound(src, 'sound/effects/clock_tick.ogg', 120, FALSE, 2)
		remove_player(current_player)

/obj/structure/table/mat_shiritori/examine()
	. = ..()
	if(active)
		if(current_letter)
			. += "<span class='info'>The next word must start with <b>[uppertext(current_letter)]</b></span>"
		. += "\n<span class='info'>[length(knockouts)] players have been eliminated. Turn [turns].</span>"
	else
		. += "<span class='info'>It doesn't look like anyone is playing it right now.</span>"

// Dynamic list initialization, saves memory
/obj/structure/table/mat_shiritori/proc/setup_blacklist(force = FALSE)
	if(blacklist && !force)
		return
	// This is not typesof, each path blacklists that atom only, good for root datums that have no functionality
	blacklist = typecacheof(list(
		/obj/structure/table/mat_shiritori,
		/obj/item/shiritori_ball,
		/obj/effect/decal/cleanable,
		/obj/item/radio/headset,
		/obj/item/clothing/head/helmet/space,
		/obj/item/book/manual,
		/obj/item/reagent_containers/food/drinks,
		/obj/item/reagent_containers/food,
		/obj/item/reagent_containers,
		/obj/machinery/atmospherics,
		/obj/machinery/portable_atmospherics,
		/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack,
		/obj/item/mecha_parts/mecha_equipment,
		/obj/item/storage,
		/obj/item/clothing,
		/obj/item/stock_parts,
		/obj/item/gun,
		/obj/item/organ,
		/obj/item,
		/obj/machinery/power,
		/obj/machinery,
		/obj,
		/mob/living/carbon,
		/mob/living/simple_animal,
		/mob/living,
		/mob
	), FALSE, TRUE)

	// This one DOES include subtypes, this should contain items that can circumvent the game's rules, make it really unfun or just break the server
	blacklist += typecacheof(list(
		/obj/effect,
		/obj/anomaly/singularity,
		/obj/item/projectile/hvp,
		/obj/item/reagent_containers/food/snacks/store/bread/recycled,
		/obj/machinery/portable_atmospherics,
		/obj/item/uplink,
		/obj/machinery/nuclearbomb
	))

// -------- Shiritori Ball, used to spawn the selected atom --------


/obj/item/shiritori_ball
	name = "materialization ball"
	desc = "Materializes selected entities at it's location after a short delay."
	icon = 'austation/icons/obj/items.dmi'
	icon_state = "shiri_ball"
	var/entity_path
	var/countdown = 5
	var/obj/structure/table/mat_shiritori/table
	var/mob/living/carbon/human/owner

/obj/item/shiritori_ball/proc/prime_spawn(obj/structure/table/mat_shiritori/table, mob/living/carbon/human/owner, entity_path)
	src.entity_path = entity_path
	src.table = table
	src.owner = owner
	spawnit()

// Not using process because that only ticks every 2 seconds and we want to send a message every second
/obj/item/shiritori_ball/proc/spawnit()
	set waitfor = FALSE
	for(var/i in 1 to countdown)
		if(owner)
			to_chat(owner, "<span class='warning'>[countdown - (i - 1)]...</span>")
		sleep(10)
	if(table)
		var/atom/movable/M = new entity_path(loc)
		table.entities += M
	else
		visible_message("<span class='warning'>\The [src] withers away</span>")
	qdel(src)
