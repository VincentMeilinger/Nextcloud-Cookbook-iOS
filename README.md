# Nextcloud-Cookbook-iOS

A Nextcloud Cookbook native iOS/iPadOS/MacOS client, built using Swift and SwiftUI.

:warning: This is not a standalone application! :warning:

See [here](https://github.com/nextcloud/cookbook) for the corresponding Nextcloud server application.

You can download the app from the AppStore:

[<img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us" alt="Download on the App Store" height="80" width="160">](https://apps.apple.com/de/app/cookbook-client/id6467141985)

## Core Features

- [x] Load recipes from nextcloud instance
- [x] Offline recipes
- [x] Recipe search function
- [x] Add new recipes
- [x] Edit recipes
- [x] Delete recipes
- [x] Login with Nextcloud account using two factor authentication
- [x] Login with Nextcloud account using app-tokens
- [x] Support for multiple languages
- [x] MacOS support (through Mac Catalyst)
- [x] Light and dark mode support
- [x] Share recipes (by name and keyword)
- [x] Import recipes
- [x] Keep display awake when viewing recipes
- [x] Ingredient shopping list

## Roadmap

- [x] **Version 1.9**: Enhancements to recipe editing for better intuitiveness; user interface design improvements for recipe viewing.

- [x] **Version 1.10**: Recipe ingredient calculator: Enables calculation of ingredient quantities based on a specifiable yield number.

- [ ] **Version 1.11**: Decoupling of internal recipe representation from the Nextcloud Cookbook recipe representation. This change provides increased flexibility for API updates and enables the introduction of features not currently supported by the Cookbook API, such as uploading images. This update will take some time, but will therefore result in simpler, better maintainable code. 

- [ ] **Version 1.12 and beyond** (Ideas for the future; integration not guaranteed!): 
  
  - Fuzzy search for recipe names and keywords.
  
  - In-app timer for the cook time specified in a recipe.
  
  - Search for recipes based on left-over ingredients.
  
  - An option to use the app without a Nextcloud account.
  
  - An option to specify the recipe folder in the Files app, to enable the app to work on the recipe files directly.
  
**If you would like to suggest new features/improvements or report bugs, please open an Issue!**

## Screenshots

The following screenshots might not be up to date, since there can always be minor user interface changes.

#### iOS Screenshots

<img src="/Screenshots/iOS_cookbooks.png" alt="/Screenshots/iOS_cookbooks.png" width="200"/> <img src="/Screenshots/iOS_recipes.png" alt="/Screenshots/iOS_recipes.png" width="200"/> <img src="/Screenshots/iOS_recipe_detail_1.png" alt="/Screenshots/iOS_recipe_detail_1.png" width="200"/> <img src="/Screenshots/iOS_recipe_detail_2.png" alt="/Screenshots/iOS_recipe_detail_2.png" width="200"/>

#### iPadOS Screenshots

<img src="/Screenshots/iPadOS_cookbooks_recipes.png" alt="/Screenshots/iPadOS_cookbooks_recipes.png" width="400"/> <img src="/Screenshots/iPadOS_recipe_detail.png" alt="/Screenshots/iPadOS_recipe_detail.png" width="400"/>

## Supported Languages

If you wish to see additional languages supported, please don't hesitate to open an Issue. Any help with translation is appreciated.

- [x] English
- [x] German
- [x] Spanish (mostly machine translated)
- [x] French (mostly machine translated)

## Further information

Cookbook Client is available on the App Store for free, and will be updated regularly. This app is a hobby project, which is why development progress may be slower than desired. If you are interested in an iOS native CookBook client, you are welcome to contribute! In case you discover any bugs or encounter problems, feel free to point them out by creating an Issue.
