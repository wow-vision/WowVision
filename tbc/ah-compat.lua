-- Workarounds for Blizzard AH bugs in TBC Anniversary.
--
-- deDE Blizzard_AuctionUI tries to call PriceDropdown:SetWidth() but the
-- frame doesn't exist in TBC Anniversary, so we stub it. Must run before
-- any code that may open the AH frames.
if not PriceDropdown then
    PriceDropdown = CreateFrame("Frame")
end
