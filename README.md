# Am I Approved?

A bureaucratic loan desk sim set in the Republic of Loria, circa 1967. You were hired as employee **#447-B** to approve loans, reject loans, and look busy between visitors. Management has full confidence in you. Management also left early.

**[Play in your browser →](https://marysue.itch.io/am-i-approved)**

## Screenshots

![Start the day](assets/start_the_day.jpg)

![The desk](assets/the_desk.jpg)

![Client database](assets/client_database.jpg)

![Credits](assets/credits.jpg)

## About

Clients arrive at your desk with stories, passports, and paperwork that does not always add up. Your job is to listen, inspect, compare, and decide who gets the money.

**What you'll do**

- **Talk to clients** — small talk, pointed questions, and the occasional lie you pretend not to notice
- **Inspect documents** — drag passports, ID cards, and contracts onto your desk and cross-check every detail
- **Work on the computer** — search the citizen database, edit records, and file loan applications on a green-screen bank terminal

**Features**

- Client dialogue and scenarios with dry, workplace humor
- Document inspection and comparison — passports, IDs, contracts, and more
- Retro bank terminal with citizen search, loan applications, and calculators
- Tutorial and employee handbook to walk you through day one
- A fully stocked desk: printer, shredder, calculator, loan folder, magnifying glass, and too much paperwork
- Pixel-art desk sim at 800×600

## Coolmath Game Jam 2026

This game was created for **[The $20K Coolmath Game Jam 2026](https://itch.io/jam/coolmath-game-jam-2026)**, hosted by Coolmath Games. The jam theme was **Break the Bank** — games about using money wisely and teaching financial literacy.

*Am I Approved?* puts those ideas into practice: you evaluate loan requests, compare income and expenses, spot inconsistencies in documents, and decide who can afford to borrow. The in-game project name *Break the Bank* reflects the jam theme; the public title is *Am I Approved?*

## Credits

| Role | Name |
| --- | --- |
| Game designer / programmer | Viktar Syanau (MarySue) |
| Artist | Anush Kalivanjyan |
| Composer / audio effects | Bohdan Potomskyi (retipupu) |
| Scenarist | Serik - Al Farabiuly Yerasyl |

**Special thanks:** Valeria Paziuk, Vadzim Trayeuski (HonieHomie), Muhammad Bakanaev (Senshi), Muzafar Bektas (horseatersson)

Sounds from [freesound.org](https://freesound.org)

## Development

Built with **HaxeFlixel** on **OpenFL**, targeting **800×600** (HTML5 and desktop).

**Requirements:** Haxe, OpenFL, Lime, HaxeFlixel

```bash
lime build html5
lime test html5
```

**Release build and itch.io zip** (patches `index.html` for itch.io hosting):

```powershell
.\scripts\package_itchio.ps1
```

Output: `dist/BreakTheBank-itchio.zip`
