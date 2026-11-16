# Recipe import supported sites

Recipes are imported by `RecipeScraperKit`. The scraper is picked by the
website's domain, every other site goes through the generic scraper, which
reads the schema.org recipe data most recipe websites publish.

## Supported

- [x] Allrecipes (allrecipes.com)
- [x] BBC Food (bbc.co.uk/food)
- [x] BBC Good Food (bbcgoodfood.com)
- [x] Bon Appétit (bonappetit.com)
- [x] Budget Bytes (budgetbytes.com)
- [x] Chefkoch (chefkoch.de)
- [x] Cookie and Kate (cookieandkate.com)
- [x] Delish (delish.com)
- [x] EAT SMARTER (eatsmarter.de)
- [x] Epicurious (epicurious.com)
- [x] essen & trinken (essen-und-trinken.de)
- [x] FOOBY (fooby.ch)
- [x] Food.com (food.com)
- [x] Food Network (foodnetwork.co.uk (foodnetwork.com redirects visitors outside the US there))
- [x] HelloFresh (hellofresh.com and country sites (.de, .co.uk, .at, .ch, .fr, .nl))
- [x] Jamie Oliver (jamieoliver.com)
- [x] Kitchen Stories (kitchenstories.com)
- [x] LECKER (lecker.de)
- [x] Marmiton (marmiton.org)
- [x] NYT Cooking (cooking.nytimes.com)
- [x] RecipeTin Eats (recipetineats.com)
- [x] Serious Eats (seriouseats.com)
- [x] Simply Recipes (simplyrecipes.com)
- [x] Smitten Kitchen (smittenkitchen.com)
- [x] Tasty (tasty.co)

## Supported (generic scraper)

Any site that publishes schema.org `Recipe` data (JSON-LD or microdata) should
work. Verified examples:

- [x] America's Test Kitchen (americastestkitchen.com)
- [x] Love and Lemons (loveandlemons.com)

## Partially supported

- [ ] Cookidoo (cookidoo.de: name, ingredients and times are
  imported, but the steps are only shown to logged-in subscribers.)

## Adding a site

1. Add `Sites/<Name>Scraper.swift` in `RecipeScraperKit`, subclassing
   `RecipeScraper` with its `hosts` and an override of `scrape(_:)`.
2. Register it in `RecipeScraper.siteScrapers`.
3. Add a test to `LiveSiteTests.swift` and a line to this list.
