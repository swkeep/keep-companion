# keep-companion

- qbcore pet script

## Features

- XP and leveling system
- Food system
- thirst sytem
- Health system (heal and revive)
- Auto naming (At first usage) & Renaming
- pet variation
- Control pet's actions
- Pet shop
- Pet animation
- ...

# WIP status:

- Pls, note this project is a work in progress.

## Usage

- open the menu with "o"
- menu keybind can be customized inside settings and Fivem keybinds

## Previews

![shop](https://raw.githubusercontent.com/swkeep/keep-companion/main/.github/images/shop.jpg)
![petshop](https://raw.githubusercontent.com/swkeep/keep-companion/main/.github/images/shop2.jpg)
![tooltip](https://raw.githubusercontent.com/swkeep/keep-companion/main/.github/images/tooltip.jpg)
![spawn](https://raw.githubusercontent.com/swkeep/keep-companion/main/.github/images/call.jpg)
![menu](https://raw.githubusercontent.com/swkeep/keep-companion/main/.github/images/menu.jpg)
![commands](https://raw.githubusercontent.com/swkeep/keep-companion/main/.github/images/levelup.jpg)
![pets](https://raw.githubusercontent.com/swkeep/keep-companion/main/.github/images/pets.jpg)

## installation

- The installation may seem a bit longer than it should be, but it's just a lot of text

# step 1: Dependencies

- [qb-target](https://github.com/BerkieBb/qb-target)
- [qbcore framework](https://github.com/qbcore-framework)
- [qb-menu](https://github.com/qbcore-framework/qb-menu)
- [qbcore inventory](https://github.com/qbcore-framework/qb-inventory)
- [lj-inventory](https://github.com/loljoshie/lj-inventory) -- in screenshot
- [qb-shops](https://github.com/qbcore-framework/qb-shops)

# step 2: add items

-- Add this code at end of qb-core\shared\items.lua

```lua
    -- ================ Keep-companion ================
    ["keepcompanionhusky"] = {
        ["name"] = "keepcompanionhusky",
        ["label"] = "Husky",
        ["weight"] = 500,
        ["type"] = "item",
        ["image"] = "A_C_Husky.png",
        ["unique"] = true,
        ["useable"] = true,
        ["shouldClose"] = true,
        ["combinable"] = nil,
        ["description"] = "Husky is your royal companion!"
    },
    ["keepcompanionpoodle"] = {
        ["name"] = "keepcompanionpoodle",
        ["label"] = "Poodle",
        ["weight"] = 500,
        ["type"] = "item",
        ["image"] = "A_C_Poodle.png",
        ["unique"] = true,
        ["useable"] = true,
        ["shouldClose"] = true,
        ["combinable"] = nil,
        ["description"] = "Poodle is your royal companion!"
    },
    ["keepcompanionrottweiler"] = {
        ["name"] = "keepcompanionrottweiler",
        ["label"] = "Rottweiler",
        ["weight"] = 500,
        ["type"] = "item",
        ["image"] = "A_Rottweiler.png",
        ["unique"] = true,
        ["useable"] = true,
        ["shouldClose"] = true,
        ["combinable"] = nil,
        ["description"] = "Rottweiler is your royal companion!"
    },
    ["keepcompanionwesty"] = {
        ["name"] = "keepcompanionwesty",
        ["label"] = "Westy",
        ["weight"] = 500,
        ["type"] = "item",
        ["image"] = "A_C_Westy.png",
        ["unique"] = true,
        ["useable"] = true,
        ["shouldClose"] = true,
        ["combinable"] = nil,
        ["description"] = "Westy is your royal companion!"
    },
    ["keepcompanionmtlion"] = {
        ["name"] = "keepcompanionmtlion",
        ["label"] = "MtLion",
        ["weight"] = 500,
        ["type"] = "item",
        ["image"] = "A_C_MtLion.png",
        ["unique"] = true,
        ["useable"] = true,
        ["shouldClose"] = true,
        ["combinable"] = nil,
        ["description"] = "MtLion is your royal companion!"
    },
    ["keepcompanionmtlion2"] = {
        ["name"] = "keepcompanionmtlion2",
        ["label"] = "Panter",
        ["weight"] = 500,
        ["type"] = "item",
        ["image"] = "A_C_MtLion.png",
        ["unique"] = true,
        ["useable"] = true,
        ["shouldClose"] = true,
        ["combinable"] = nil,
        ["description"] = "Panter is your royal companion!"
    },
    ["keepcompanioncat"] = {
        ["name"] = "keepcompanioncat",
        ["label"] = "Cat",
        ["weight"] = 500,
        ["type"] = "item",
        ["image"] = "A_C_Cat_01.png",
        ["unique"] = true,
        ["useable"] = true,
        ["shouldClose"] = true,
        ["combinable"] = nil,
        ["description"] = "Cat is your royal companion!"
    },
    ["keepcompanionpug"] = {
        ["name"] = "keepcompanionpug",
        ["label"] = "Pug",
        ["weight"] = 500,
        ["type"] = "item",
        ["image"] = "A_C_Pug.png",
        ["unique"] = true,
        ["useable"] = true,
        ["shouldClose"] = true,
        ["combinable"] = nil,
        ["description"] = "Pug is your royal companion!"
    },
    ["keepcompanionretriever"] = {
        ["name"] = "keepcompanionretriever",
        ["label"] = "Retriever",
        ["weight"] = 500,
        ["type"] = "item",
        ["image"] = "A_C_Retriever.png",
        ["unique"] = true,
        ["useable"] = true,
        ["shouldClose"] = true,
        ["combinable"] = nil,
        ["description"] = "Retriever is your royal companion!"
    },
    ["keepcompanionshepherd"] = {
        ["name"] = "keepcompanionshepherd",
        ["label"] = "Shepherd",
        ["weight"] = 500,
        ["type"] = "item",
        ["image"] = "A_C_shepherd.png",
        ["unique"] = true,
        ["useable"] = true,
        ["shouldClose"] = true,
        ["combinable"] = nil,
        ["description"] = "Shepherd is your royal companion!"
    },
    -- new pets
    ["keepcompanioncoyote"]     = {
		["name"] = "keepcompanioncoyote",
		["label"] = "Coyote",
		["weight"] = 500,
		["type"] = "item",
		["image"] = "A_C_Coyote.png",
		["unique"] = true,
		["useable"] = true,
		["shouldClose"] = true,
		["combinable"] = nil,
		["description"] = "Coyote is your royal companion!"
	},
	["keepcompanionrabbit"]     = {
		["name"] = "keepcompanionrabbit",
		["label"] = "Rabbit",
		["weight"] = 500,
		["type"] = "item",
		["image"] = "A_C_Rabbit_01.png",
		["unique"] = true,
		["useable"] = true,
		["shouldClose"] = true,
		["combinable"] = nil,
		["description"] = "Rabbit is your royal companion!"
	},
	["keepcompanionhen"]        = {
		["name"] = "keepcompanionhen",
		["label"] = "Hen",
		["weight"] = 500,
		["type"] = "item",
		["image"] = "A_C_Hen.png",
		["unique"] = true,
		["useable"] = true,
		["shouldClose"] = true,
		["combinable"] = nil,
		["description"] = "Hen is your royal companion!"
	},
    ["keepcompanionrat"] = {
        ["name"] = "keepcompanionrat",
        ["label"] = "Rat",
        ["weight"] = 500,
        ["type"] = "item",
        ["image"] = "A_C_Rat.png",
        ["unique"] = true,
        ["useable"] = true,
        ["shouldClose"] = true,
        ["combinable"] = nil,
        ["description"] = "Your royal companion!"
    },
    ---
    ["petfood"] = {
        ["name"] = "petfood",
        ["label"] = "pet food",
        ["weight"] = 500,
        ["type"] = "item",
        ["image"] = "petfood.png",
        ["unique"] = false,
        ["useable"] = true,
        ["shouldClose"] = true,
        ["combinable"] = nil,
        ["description"] = "food for your companion!"
    },
    ["collarpet"] = {
        ["name"] = "collarpet",
        ["label"] = "Pet collar",
        ["weight"] = 500,
        ["type"] = "item",
        ["image"] = "collarpet.png",
        ["unique"] = false,
        ["useable"] = true,
        ["shouldClose"] = true,
        ["combinable"] = true,
        ["description"] = "Rename your pets!"
    },
    ["firstaidforpet"] = {
        ["name"] = "firstaidforpet",
        ["label"] = "First aid for pet",
        ["weight"] = 500,
        ["type"] = "item",
        ["image"] = "firstaidforpet.png",
        ["unique"] = false,
        ["useable"] = true,
        ["shouldClose"] = true,
        ["combinable"] = nil,
        ["description"] = "Revive your pet!"
    },
	["petnametag"]              = {
		["name"] = "petnametag",
		["label"] = "Name tag",
		["weight"] = 500,
		["type"] = "item",
		["image"] = "petnametag.png",
		["unique"] = false,
		["useable"] = true,
		["shouldClose"] = true,
		["combinable"] = nil,
		["description"] = "Rename your pet"
	},
    ["petwaterbottleportable"]  = {
		["name"] = "petwaterbottleportable",
		["label"] = "Portable water bottle",
		["weight"] = 1000,
		["type"] = "item",
		["image"] = "petwaterbottleportable.png",
		["unique"] = true,
		["useable"] = true,
		["shouldClose"] = true,
		["combinable"] = nil,
		["description"] = "Flask to store water for your pets"
	},
    ["petgroomingkit"]  = {
		["name"] = "petgroomingkit",
		["label"] = "Pet Grooming Kit",
		["weight"] = 1000,
		["type"] = "item",
		["image"] = "petgroomingkit.png",
		["unique"] = true,
		["useable"] = true,
		["shouldClose"] = true,
		["combinable"] = nil,
		["description"] = "Pet Grooming Kit"
	},
```

# step 3: qb-shop

- Here is tables qb-shops/config.lua

```lua
-- add it at end of Config.Products table
    ["petshop"] = {
        [1] = {
            name = 'keepcompanionwesty',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 1
        },
        [2] = {
            name = 'keepcompanionshepherd',
            price = 150000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 2
        },
        [3] = {
            name = 'keepcompanionretriever',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 3
        },
        [4] = {
            name = 'keepcompanionrottweiler',
            price = 75000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 4
        },
        [5] = {
            name = 'keepcompanionpug',
            price = 95000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 5
        },
        [6] = {
            name = 'keepcompanionpoodle',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 6
        },

        [7] = {
            name = 'keepcompanionmtlion2',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 7
        },
        [8] = {
            name = 'keepcompanioncat',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 8
        },
        [9] = {
            name = 'keepcompanionmtlion',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 9
        },
        [10] = {
            name = 'keepcompanionhusky',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 10
        },
        [11] = {
            name = 'petfood',
            price = 500,
            amount = 1000,
            info = {},
            type = 'item',
            slot = 11
        },
        [12] = {
            name = 'collarpet',
            price = 50000,
            amount = 50,
            info = {},
            type = 'item',
            slot = 12
        },
        [13] = {
            name = 'firstaidforpet',
            price = 5000,
            amount = 50,
            info = {},
            type = 'item',
            slot = 13
        },
        [14] = {
            name = 'petnametag',
            price = 5000,
            amount = 50,
            info = {},
            type = 'item',
            slot = 14
        },
        [15] = {
            name = 'petwaterbottleportable',
            price = 5000,
            amount = 50,
            info = {},
            type = 'item',
            slot = 15
        },
        [16] = {
            name = 'petgroomingkit',
            price = 5000,
            amount = 50,
            info = {},
            type = 'item',
            slot = 16
        },
        [17] = {
            name = 'keepcompanionrabbit',
            price = 15000,
            amount = 50,
            info = {},
            type = 'item',
            slot = 17
        },
        [18] = {
            name = 'keepcompanionhen',
            price = 5000,
            amount = 50,
            info = {},
            type = 'item',
            slot = 18
        },
        [19] = {
            name = 'keepcompanioncoyote',
            price = 50000,
            amount = 50,
            info = {},
            type = 'item',
            slot = 19
        },
    }

```

```lua
-- add it at end of Config.Locations table
    ["petshop"] = {
        ["label"] = "Pet Shop",
        ["coords"] = vector4(561.18, 2741.51, 42.87, 199.08), --or vector4(-659.87, -936.46, 21.83, 130.04), --  for mlo https://www.gta5-mods.com/maps/
        ["ped"] = 'S_M_M_StrVend_01',
        ["scenario"] = "WORLD_HUMAN_COP_IDLES",
        ["radius"] = 1.5,
        ["targetIcon"] = "fas fa-paw",
        ["targetLabel"] = "Open Pet Shop",
        ["products"] = Config.Products["petshop"],
        ["showblip"] = true,
        ["blipsprite"] = 267,
        ["blipcolor"] = 5
    },
```

# step 4: tooltip

- i'm using lj-inventory just find where tooltip codes are!
- in inventory\js\app.js find FormatItemInfo() there is if statement like: if (itemData.name == "id_card")
- track where all of elseif statments ends then add else if below at there

```javascript
else if (
    itemData.name == "keepcompanionhusky" ||
    itemData.name == "keepcompanionrottweiler" ||
    itemData.name == "keepcompanionmtlion" ||
    itemData.name == "keepcompanionmtlion2" ||
    itemData.name == "keepcompanioncat" ||
    itemData.name == "keepcompanionpoodle" ||
    itemData.name == "keepcompanionpug" ||
    itemData.name == "keepcompanionretriever" ||
    itemData.name == "keepcompanionshepherd" ||
    itemData.name == "keepcompanionwesty" ||
    itemData.name == "keepcompanioncoyote" ||
    itemData.name == "keepcompanionrabbit" ||
    itemData.name == "keepcompanionhen"
) {
    let gender = itemData.info.gender;
    gender ? (gender = "male") : (gender = "female");
    $(".item-info-title").html("<p>" + itemData.info.name + "</p>");
    $(".item-info-description").html(
        "<p><strong>Owner Phone: </strong><span>" +
        itemData.info.owner.phone +
        "</span></p><p><strong>Variation: </strong><span>" +
        `${itemData.info.variation}` +
        "</span></p><p><strong>Gender: </strong><span>" +
        `${gender}` +
        "</span></p><p><strong>Health: </strong><span>" +
        itemData.info.health +
        "</span></p><p><strong>Xp/Max: </strong><span>" +
        `${itemData.info.XP} / ${maxExp(itemData.info.level)}` +
        "</span></p><p><strong>Level: </strong><span>" +
        itemData.info.level +
        "</span></p><p><strong>Age: </strong><span>" +
        callAge(itemData.info.age) +
        "</span></p><p><strong>Food: </strong><span>" +
        itemData.info.food +
        "</span></p>" +
        "</span></p><p><strong>Thirst: </strong><span>" +
        itemData.info.thirst +
        "</span></p>"
    );
}
else if (itemData.name == "petwaterbottleportable") {
    $(".item-info-title").html("<p>" + itemData.label + "</p>");
    $(".item-info-description").html("<p>capacity(L): " + itemData.info.liter + "</p>");
}
```

- and add this codes at end of inventory\js\app.js

```javascript
function callAge(age) {
  let max = 0;
  let min = 0;
  if (age === 0) {
    return 0;
  }
  for (let index = 1; index < 10; index++) {
    max = 60 * 60 * 24 * index;
    min = 60 * 60 * 24 * (index - 1);
    if (age >= min && age <= max) {
      return index - 1;
    }
  }
}

function maxExp(level) {
  let xp = Math.floor(
    (1 / 4) * Math.floor((level + 300) * Math.pow(2, level / 7))
  );
  return xp;
}

function currentLvlExp(xp) {
  let maxExp = 0;
  let minExp = 0;

  for (let index = 0; index <= 50; index++) {
    maxExp = Math.floor(Math.floor((i + 300) * (2 ^ (i / 7))) / 4);
    minExp = Math.floor(Math.floor((i - 1 + 300) * (2 ^ ((i - 1) / 7))) / 4);
    if (xp >= minExp && xp <= maxExp) {
      return i;
    }
  }
}
```

#K9

- important steps for k9 to work
- first open you inventory script qb-inventory/server/main.lua
- find this event

```lua
RegisterNetEvent('inventory:server:SetIsOpenState')
```

- add code below after or before this event (not inside it!)
  ![shop](https://raw.githubusercontent.com/swkeep/keep-companion/main/.github/images/new_k9_patch.PNG)

- then go to script confing file find Config.inventory_name and change it to your inventory's name
