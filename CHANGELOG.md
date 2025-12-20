# Changelog - ItemTooltipProfessionIcons (Ascension Edition)

All notable changes to this project will be documented in this file.

## [1.2.0-Ascension] - 2025-12-19
### Added
- Professional badges for total downloads and documentation hub in README.
- "At a Glance" summary section to the project README for quicker value proposition.

### Fixed
- Fixed technical typo "Luckup" to "Lookup" in all documentation and descriptions.
- Synchronized versioning across all metadata points (.toc, README, docs).


## [1.1.0-Ascension] - 2025-12-19
### Backport & Optimization (3.3.5a / Project Ascension)
- **Author**: Xurkon
- **Target Client**: World of Warcraft 3.3.5a (Project Ascension)
- **Compatibility**:
  - Updated TOC Interface version to `30300`.
  - Replaced `GetItemInfoInstant` with a more robust item ID extraction method from `itemLink` to handle uncached items (e.g., in the Auction House).
  - Replaced dynamic `GetSpellInfo` texture lookups with hardcoded file paths for instant icon loading.
  - Implemented a fallback for the `bit` library to ensure compatibility with older Lua environments.
  - Fixed issues with the configuration frame's Slider by removing incompatible 3.3.5a methods like `SetStepsPerPage`.
- **Features**:
  - Added support for all standard tooltips: `GameTooltip`, `ItemRefTooltip`, `ShoppingTooltip1/2`, and `WorldMapTooltip`.
  - Implemented `/itpi test` for quick status verification (Database count, Realm/Char detection).
  - Implemented `/itpi debug` to toggle technical output for troubleshooting.
  - Increased maximum icon size from 32 to 64 to accommodate high-resolution displays or accessibility needs.
- **Reliability**:
  - Centralized character-specific settings under an improved `ConfigChanged` logic that auto-initializes for new characters.
  - Added event-driven configuration loading via `PLAYER_ENTERING_WORLD` to prevent silent failures during login.
  - Standardized the slash command to reliably open the Interface Options menu in the 3.3.5a client.
  - Fixed a critical "nil value" error when opening the options menu before character variables were initialized.
  - Optimized tooltip updates to prevent icon duplication (removed redundant manual function hooks).
- **Cleanup**:
  - Removed all hardcoded debug prints from the main tooltip loop for a clean user experience.
  - Standardized texture strings to the `|TTexture:Size|t` format for maximum client compatibility.
  - Reorganized project constants into a centralized `ItemProfConstants` global table.
