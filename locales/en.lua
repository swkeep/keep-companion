local Translations = {
    -- general Notify
    error = {
        no_pet_under_control = 'Atleast one pet must be under your control',
        badword_inside_pet_name = 'Do not name your pet like that!',
        more_than_one_word_as_name = 'You can not use that many words in you pet name!',
        failed_to_start_procces = 'Failed to start procces!',
        failed_to_find_pet = 'could not find your pet!',
        could_not_do_that = 'Could not do that',
        string_type = 'wrong name type (only string)!',
        not_enough_first_aid = 'You need first aid to do this!',
        reached_max_allowed_pet = 'You can not have more than %s active pets!',
        failed_to_validate_name = 'We can not validate this name try something else maybe!?',
        failed_to_rename = 'Failed to rename: %s',
        failed_to_rename_same_name = 'The previous name is the same as the new one: %s',
        your_pet_is_dead = 'Your pet is dead try again when your pet is alive',
        your_pet_died_by = 'Your pet died by %s',
        not_owner_of_pet = 'You are not owner of this pet',

        failed_to_remove_item_from_inventory = 'Failed to remove from your inventory',
        failed_to_transfer_ownership_same_owner = 'You can not transfer your pet to yourself!',
        failed_to_transfer_ownership_could_not_find_new_owner_id = 'Could not find new owner (wrong id)',
        failed_to_transfer_ownership_missing_current_owner = 'Can not transfer this pet missing current owner information!',

        not_enough_water_bottles = 'Your not carrying enough water bottles min: %d',
        not_enough_water_in_your_bottle = 'Your water bottle is empty!',

        pet_died = '%s died!'
    },
    success = {
        pet_initialization_was_successful = 'Congratulation on your new companion',
        pet_rename_was_successful = 'Your pet name changed to ',
        healing_was_successful = "Your pet healed for: %s maxHealth: %s",
        successful_revive = '%s your pet revived',
        successful_ownership_transfer = 'The transfer was successful. you can now give this pet to the new owner',
        successful_drinking = 'drinking was successful wait a little bit to take effect',
        successful_grooming = 'grooming was successful',
    },
    info = {
        use_3th_eye = 'Use your 3th eye on your pet',
        full_life_pet = 'your pet is on full health',
        still_on_cooldown = "still on cooldown remaining: %s sec",
        level_up = '%s gain new level %d'
    },
    menu = {
        general_menu_items = {
            btn_leave = 'Leave',
            btn_back = 'Back',
            success = 'success',
            confirm = 'Confirm'
        },

        main_menu = {
            header = 'Name: %s',
            sub_header = 'current pet under your control',
            btn_actions = 'Actions',
            btn_switchcontrol = 'Switch Control',
            switchcontrol_header = 'Switch Pet Under Your Control',
            switchcontrol_sub_header = 'click on pet which you want to control',
        },

        action_menu = {
            header = 'Name: %s',
            sub_header = 'current pet under your control',
            follow = 'Follow Owner',
            hunt = 'Hunt',
            hunt_and_grab = 'Hunt and Grab',
            go_there = 'Go There',
            wait = 'Wait here',
            get_in_car = 'Get in car',
            beg = 'Do some tricks',
            paw = 'Paw',
            play_dead = 'Play dead',
            tricks = 'Tricks',
            error = {
                pet_unable_to_hunt = "Your pet can not hunt",
                not_meet_min_requirement_to_hunt = 'Your pet needs to lvl up in order to hunt. (min level: %s)',
                already_hunting_something = 'already hunting something!',
                pet_unable_to_do_that = 'unable to do your command',

                -- get into car
                need_to_be_inside_car = 'You need to be inside a car',
                to_far = 'To far',
                no_empty_seat = 'no empty seat found!'
            },
            success = {


            },
            info = {

            }
        },

        tricks = {
            header = 'Name: %s',
            sub_header = 'current pet under your control',

        },

        switchControl_menu = {
            header = 'Name: %s',
            sub_header = 'current pet under your control',

        },

        customization_menu = {
            header = 'Customization menu',
            sub_header = '',

            btn_rename = 'Rename',
            btn_txt_btn_rename = 'current name: ',

            btn_select_variation = 'Select variation',
            btn_txt_select_variation = 'current color: ',


            rename = {
                inputs = {
                    header = 'Type new name'
                }
            }
        },

        rename_menu = {
            header = 'Current name',
            btn_rename = 'Rename',
        },

        variation_menu = {
            header = 'Current color',
            btn_select_variation = 'Select variation',
            btn_txt_select_variation = 'choice color of you pet',

            selection_menu = {
                header = 'Variation list',
                btn_variation_items = 'Variation: ',
                btn_desc = 'select to take effect',
            }

        },
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
