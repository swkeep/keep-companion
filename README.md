# keep-companion

- qbcore pet script

## Features

- xp and level system
- food and health system
- auto naming & renaming system
- random pet variation
- command pet by menu
- pet shop
- pet animation
- ...

# WIP status:

Note that project still not ready yet. but you can still test it and help me in development.

- xp and level system ==> basic implementation
- food ==> not implemented
- pet animation ==> not implemented
- ...

## Hotkey

- open the menu with "o"

## Previews

![shop](https://raw.githubusercontent.com/swkeep/keep-companion/main/.github/images/shop.png)
![petshop](https://raw.githubusercontent.com/swkeep/keep-companion/main/.github/images/petshop.png)
![tooltip](https://raw.githubusercontent.com/swkeep/keep-companion/main/.github/images/tooltip.png)
![spawn](https://raw.githubusercontent.com/swkeep/keep-companion/main/.github/images/spawn.png)
![menu](https://raw.githubusercontent.com/swkeep/keep-companion/main/.github/images/menu.png)
![commands](https://raw.githubusercontent.com/swkeep/keep-companion/main/.github/images/commands.png)

## installation

- The installation may seem a bit longer than it should be, but it's just a lot of text

# step 1: Dependencies

- [qb-target](https://github.com/BerkieBb/qb-target)
- [qbcore framework](https://github.com/qbcore-framework)
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
    ["keepcompanionmtLion"] = {
        ["name"] = "keepcompanionmtLion",
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
    ["keepcompanionmtLion2"] = {
        ["name"] = "keepcompanionmtLion2",
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
    }
```

# step 3: qb-shop

- Here is tables qb-shops/config.lua

```lua
-- add it at end of Config.Products table
    ["petShop"] = {
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
            name = 'keepcompanionretriever',
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
            name = 'keepcompanionmtLion2',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 7
        },
        [8] = {
            name = 'keepcompanionmtLion3',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 8
        },
        [9] = {
            name = 'keepcompanionmtLion',
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
        }
    }

```

```lua
-- add it at end of Config.Locations table
    ["petShop"] = {
        ["label"] = "Pet Shop",
        ["coords"] = {
            [1] = vector4(-3225.63, 928.89, 13.9, 297.06),
            -- [2] = vector4(-659.87, -936.46, 21.83, 130.04), -- umcomment if you are using https://www.gta5-mods.com/maps/mlo-pet-shop
        },
        ["ped"] = {
            ["model"] = 'S_M_M_StrVend_01'
        },
        ["radius"] = 1.5,
        ["products"] = Config.Products["petShop"],
        ["showblip"] = true,
        ["blipsprite"] = 267,
        ["colour"] = 5
    }
```

# step 4: tooltip

- i'm using lj-inventory just find where tooltip codes are!
- in inventory\js\app.js find FormatItemInfo() there is if statement like: if (itemData.name == "id_card")
- track where all of elseif statments ends then add else if below at there

```javascript
else if (
            itemData.name == "keepcompanionhusky" ||
            itemData.name == "keepcompanionrottweiler" ||
            itemData.name == "keepcompanionmtLion" ||
            itemData.name == "keepcompanionpoodle" ||
            itemData.name == "keepcompanionpug" ||
            itemData.name == "keepcompanionretriever" ||
            itemData.name == "keepcompanionshepherd" ||
            itemData.name == "keepcompanionwesty"
        ) {
            // TODO changing heere
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
                "</span></p>"
            );
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
