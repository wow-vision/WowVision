# TBC Auction House Module - Implementation Notes

Work document for the TBC Anniversary auction house accessibility module (`tbc/auction.lua`).

## MoP vs TBC Auction House Comparison

| Aspect | MoP (`mists/auction.lua`) | TBC (`tbc/auction.lua`) |
|--------|---------------------------|--------------------------|
| Root frame | `AuctionHouseFrame` | `AuctionFrame` |
| Scroll system | Modern ScrollBox + `GetRowData()` | FauxScrollFrame + fixed buttons (`BrowseButton1-8`) |
| Item model | Commodities vs Items (separate buy flows) | All individual auctions (no commodity concept) |
| Sell location | Dedicated second tab | Combined with "My Auctions" on tab 3 |
| Tabs | Buy / Sell / Auctions(+Bids sub-tab) | Browse / Bids / Auctions(+Create) |
| Category filter | `ProxyScrollBox` on `CategoriesList.ScrollBox` | Fixed `AuctionFilterButton1-15` buttons |
| Search inputs | Single filter button + search box | Name EditBox + Min/Max Level + Rarity dropdown + Usable checkbox |
| Pagination | Infinite scroll | Prev/Next page buttons (server-side pages) |
| Price display | `C_CurrencyInfo.GetCoinText(rowData.minPrice)` | `GetAuctionItemInfo()` API + `C_CurrencyInfo.GetCoinText()` |
| Duration selector | Dropdown | Radio-style CheckButtons (12h/24h/48h) |
| Data access | `button:GetRowData()` on modern ScrollBox | `GetAuctionItemInfo("list"/"bidder"/"owner", index)` |
| Window type | `EventWindow` | `FrameWindow` |

## Frame Dump Analysis (AuctionFrame)

Initial dump taken with Browse tab active, no search performed, no item placed for auction.

### Tab Structure

- `AuctionFrameTab1` (Browse) - active (disabled=selected)
- `AuctionFrameTab2` (Bids)
- `AuctionFrameTab3` (Auctions)

### Browse Tab (`AuctionFrameBrowse`, shown=true)

**Category Filters:**
- `AuctionFilterButton1-15` - 11 visible (Weapons, Armor, Containers, Consumables, Crafting Materials, Projectiles, Quivers, Recipes, Gems, Miscellaneous, Quest Items), 4 hidden
- `BrowseFilterScrollFrame` (ScrollFrame, shown=false) - for sub-category scrolling

**Search Controls:**
- `BrowseName` (EditBox) - item name search
- `BrowseMinLevel` (EditBox) - minimum level filter
- `BrowseMaxLevel` (EditBox) - maximum level filter
- `BrowseDropdown` (Button) - rarity filter, text="Alle" (All)
- `IsUsableCheckButton` (CheckButton) - usable items only
- `ShowOnPlayerCheckButton` (CheckButton) - preview (visual-only, skip for accessibility)
- `BrowseSearchButton` (Button) - "Suchen" (Search)
- `BrowseResetButton` (Button) - "Zurücksetzen" (Reset), disabled

**Sort Headers:**
- `BrowseQualitySort` - "Seltenheit" (Rarity)
- `BrowseLevelSort` - "St." (Level)
- `BrowseDurationSort` - "Restzeit" (Time Left)
- `BrowseHighBidderSort` - "Verkäufer" (Seller)
- `BrowseCurrentBidSort` - "Aktuelles Gebot" (Current Bid)

**Results List:**
- `BrowseScrollFrame` (ScrollFrame, shown=false - no results yet)
- `BrowseButton1-8` (all shown=false - no results yet)
- Each BrowseButton contains: Item icon, ClosingTime, HighBidder, MoneyFrame (bid), YourBidText, BuyoutFrame

**Page Controls:**
- `BrowsePrevPageButton` (disabled)
- `BrowseNextPageButton` (disabled)

**Action Controls:**
- `BrowseBidPrice` frame with Gold/Silver/Copper EditBoxes
- `BrowseBidButton` (disabled)
- `BrowseBuyoutButton` (disabled)

### Bids Tab (`AuctionFrameBid`, shown=false)

**Sort Headers:** Quality, Level, Duration, Buyout, Status, Current Bid

**Results:** `BidButton1-9`, each with Item, ClosingTime, BuyoutMoneyFrame, CurrentBidMoneyFrame

**Action Controls:**
- `BidBidPrice` frame with Gold/Silver/Copper EditBoxes
- `BidBidButton` (disabled)
- `BidBuyoutButton` (disabled)

### Auctions Tab (`AuctionFrameAuctions`, shown=false)

**Sort Headers:** Quality, Duration, High Bidder, Current Bid

**My Auctions List:** `AuctionsButton1-9`, each with Item, ClosingTime, HighBidder, MoneyFrame, BuyoutFrame

**Create Auction Form:**
- `AuctionsItemButton` (Button) - drag item here to sell
- `AuctionsStackSizeEntry` (EditBox, hidden) - stack size
- `AuctionsStackSizeMaxButton` (hidden)
- `AuctionsNumStacksEntry` (EditBox, hidden) - number of stacks
- `AuctionsNumStacksMaxButton` (hidden)
- `StartPrice` frame with Gold/Silver/Copper EditBoxes - "Anfangsgebot" (Starting Bid)
- `AuctionsShortAuctionButton` (CheckButton) - 12 hours
- `AuctionsMediumAuctionButton` (CheckButton, checked) - 24 hours
- `AuctionsLongAuctionButton` (CheckButton) - 48 hours
- `BuyoutPrice` frame with Gold/Silver/Copper EditBoxes - "Kaufpreis (optional)"
- `AuctionsDepositMoneyFrame` - deposit cost display
- `AuctionsCreateAuctionButton` - "Auktion erstellen" (Create Auction)
- `AuctionsCancelAuctionButton` (disabled) - "Auktionsabbruch" (Cancel Auction)

## Implementation Approach

### Element Tree

```
auction (root Panel)
└── auction/Tabs (ProxyTabPanel on AuctionFrame)
    ├── auction/BrowseTab
    │   ├── auction/Categories (List of visible AuctionFilterButton1-15)
    │   ├── auction/SearchFilters (Panel)
    │   │   ├── ProxyEditBox: BrowseName
    │   │   ├── ProxyEditBox: BrowseMinLevel
    │   │   ├── ProxyEditBox: BrowseMaxLevel
    │   │   ├── ProxyDropdownButton: BrowseDropdown
    │   │   ├── ProxyCheckButton: IsUsableCheckButton
    │   │   ├── ProxyButton: BrowseSearchButton
    │   │   └── ProxyButton: BrowseResetButton
    │   ├── auction/BrowseResults (ProxyFauxScrollFrame with BrowseButton1-8)
    │   ├── auction/BrowsePageControls (Prev/Next buttons)
    │   └── auction/BrowseActions (bid price input + bid/buyout buttons)
    ├── auction/BidsTab
    │   ├── auction/BidResults (ProxyFauxScrollFrame with BidButton1-9)
    │   └── auction/BidActions (bid price input + bid/buyout buttons)
    └── auction/AuctionsTab
        ├── auction/MyAuctionsList (ProxyFauxScrollFrame with AuctionsButton1-9)
        ├── auction/CreateAuction (item placement, stack/price config, duration, create)
        └── ProxyButton: AuctionsCancelAuctionButton
```

### Key Patterns Used

- `ProxyFauxScrollFrame` for all scroll lists (same pattern as `tbc/QuestLog.lua`)
- `GetAuctionItemInfo()` API for auction data instead of scraping frame text
- `C_CurrencyInfo.GetCoinText()` for money formatting
- `ProxyTabPanel` for 3-tab navigation
- `FrameWindow` registration (standard TBC module pattern)

### WoW API Functions Used

- `GetNumAuctionItems("list"|"bidder"|"owner")` - item counts
- `GetAuctionItemInfo("list"|"bidder"|"owner", index)` - item data
- `GetAuctionItemTimeLeft("list"|"bidder"|"owner", index)` - time remaining (1-4)
- `FauxScrollFrame_GetOffset(scrollFrame)` - scroll offset for button index calculation
- `PanelTemplates_GetSelectedTab(AuctionFrame)` - active tab detection

## Wanted Frame Dumps for Future Testing

These dumps would help verify and refine the implementation:

1. **Browse tab with search results populated** - need to see BrowseButton1-8 with actual auction data to verify frame text content, item tooltip behavior, and button heights.

2. **Category sub-categories expanded** - click a category like "Weapons" to see how AuctionFilterButton1-15 change and whether BrowseFilterScrollFrame becomes visible.

3. **Auctions tab with an item placed for sale** - the stack size/number of stacks fields are hidden until an item is placed in AuctionsItemButton. Need to see the full create auction form.

4. **Browse tab with a result selected** - verify that BrowseBidButton/BrowseBuyoutButton become enabled and that the bid price input is populated.

5. **Bids tab with active bids** - verify BidButton1-9 data structure with actual bids.

## Resolved Issues

- **ProxyTabPanel incompatibility**: TBC's `AuctionFrame` doesn't have a `.Tabs` subtable (modern API), causing `ProxyTabPanel` to crash. Fixed by using manual tab handling with `_G["AuctionFrameTab" .. i]` and `PanelTemplates_GetSelectedTab()`, matching the pattern from `tbc/spellbook.lua`. Active tab content is determined by checking `IsShown()` on `AuctionFrameBrowse`, `AuctionFrameBid`, `AuctionFrameAuctions`.

## Known Uncertainties

- **BrowseDropdown frame name**: Dump shows `BrowseDropdown` but classic WoW convention is `BrowseDropDown`. Using `BrowseDropDown or BrowseDropdown` fallback to handle both.
- **ProxyDropdownButton compatibility**: Calls `frame:OpenMenu()` which is modern API. Works for `tbc/tradeskill.lua` dropdowns, should work here too.
- **AUCTIONS_BUTTON_HEIGHT constant**: May or may not be a global in TBC Anniversary. Using it with a fallback comment.
- **AuctionFrameBrowse_Update function**: Should be global in TBC Anniversary (Blizzard's update function for FauxScrollFrame). If not global, need alternative approach.
- **C_CurrencyInfo.GetCoinText availability**: Used in core money.lua, should be available. If not in TBC Anniversary, use GetCoinText() or manual formatting.
- **Filter sub-categories**: Current implementation renders visible buttons as a flat list. May need ProxyFauxScrollFrame wrapping for BrowseFilterScrollFrame when sub-categories exceed 15 items.
