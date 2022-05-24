local Translations = {
    error = {
        no_pet_under_control = 'Atleast one pet must be under your control',
        badword_inside_pet_name = 'Do not name your pet like that!',
        more_than_one_word_as_name = 'You can not use that many words in you pet name!',
        failed_to_start_procces = 'Failed to start procces!',
        failed_to_find_pet = 'could not find your pet!',
        string_type = 'wrong name type (only string)!',
        not_enough_first_aid = 'You need first aid to do this!',
        reached_max_allowed_pet = 'You can not have more than %s active pets!',
        failed_to_validate_name = 'We can not validate this name try something else maybe!?',
        failed_to_rename = 'Failed to rename: %s',
        failed_to_rename_same_name = 'The previous name is the same as the new one: %s',
        not_meet_min_requirement_to_hunt = 'Your pet needs to lvl up in order to hunt. (min level: %s)',
        your_pet_is_dead = 'Your pet is dead try again when your pet is alive',
        your_pet_died_hunger = 'Your pet died by hunger',
    },
    success = {
        pet_initialization_was_successful = 'Congratulation on your new companion',
        pet_rename_was_successful = 'Your pet name changed to ',
        healing_was_successful = "Your pet healed for: %s maxHealth: %s",
        successful_revive = '%s your pet revived',
    },
    info = {
        use_3th_eye = 'Use your 3th eye on your pet',
        full_life_pet = 'your pet is on full health',
        still_on_cooldown = "still on cooldown remaining: %s sec",
        pet_unable_to_hunt = "Your pet can not hunt",
    },
    menu = {
        follow = 'Follow Owner',
        hunt = 'Hunt',
        hunt_and_grab = 'Hunt and Grab',
        go_there = 'Go There',
        wait = 'Wait here',
        get_in_car = 'Get in car',
        beg = 'Do some tricks',
        paw = 'Paw',
        pet_name = 'Name: %s',
        menu_leave = 'Leave',
        menu_back = 'Back',
        menu_header_tricks = 'Tricks',
        manu_switch_header = 'Switch Pet Under Your Control',
        manu_switch_sub_header = 'click on pet which you want to control',
        menu_pet_main_sub_header = 'current pet under your control',
        menu_btn_switchcontroll = 'Switch Control',
        menu_btn_actions = 'Actions'
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
