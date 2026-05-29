import hashlib
import json
import random
import unicodedata
from datetime import date, timedelta

random.seed(42)

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NAMES_PATH = ROOT / "static" / "client_names.json"
OUT_PATH = ROOT / "static" / "citizens.json"


def load_names():
    with open(NAMES_PATH, encoding="utf-8") as f:
        return json.load(f)


def ascii_name(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value)
    return "".join(c for c in normalized if not unicodedata.combining(c))


def cap_text(value: str, max_len: int) -> str:
    if len(value) <= max_len:
        return value
    return value[:max_len]


def shorten_region(region: str) -> str:
    region = (
        region.replace(" Territory", " Terr")
        .replace(" Prefecture", " Pr")
        .replace(" District", " Dist")
        .replace(" Canton", " Cnt")
        .replace(" County", " Co")
        .replace(" Parish", " Par")
        .replace(" March", " Mch")
        .replace(" Ward", " Wd")
        .replace(" Vale", " Vl")
        .replace(" Shire", " Sh")
    )
    return cap_text(region, 15)


def make_email(first_name: str, last_name: str, country_code: str) -> str:
    domains = {
        "lorian": "lor",
        "valdorian": "val",
        "kethran": "kth",
        "meridian": "mer",
        "ostmark": "ost",
    }
    domain = domains.get(country_code, "ml")
    local = f"{first_name[0].lower()}{last_name[:5].lower()}"
    email = f"{local}@{domain}.m"
    if len(email) > 16:
        email = f"{first_name[0].lower()}{last_name[:3].lower()}@{domain}.m"
    return cap_text(email, 16)


def make_national_id(digest: str) -> str:
    return cap_text(digest, 9)


def make_phone() -> str:
    cc = random.randint(1, 99)
    area = random.randint(200, 999)
    block = random.randint(1000, 9999)
    phone = f"+{cc}-{area}-{block}"
    if len(phone) > 15:
        phone = f"+{cc}{area}{block}"
    return cap_text(phone, 15)


def pool(names_db, key, origin=None, funny=False):
    items = names_db[key]
    out = []
    for x in items:
        is_funny = x.get("funny", False)
        if funny != is_funny:
            continue
        if origin and x.get("origin") != origin:
            continue
        out.append(x["name"])
    return out


def main():
    names_db = load_names()

    # All nations are fictional. nameOrigin only selects name pools from client_names.json.
    countries = [
        {
            "code": "lorian",
            "name": "Republic of Loria",
            "nameOrigin": "american",
            "passportFormat": lambda n: f"LR-{n:08d}",
            "nationalIdPrefix": "",
            "taxPrefix": "LTX",
            "currency": "LOR",
            "cities": ["Aldenport", "Merrowick", "Kestral Bay", "Northvale", "Brackenford"],
            "regions": [
                "Alden Province",
                "Merrow Coast",
                "Kestral District",
                "Northvale Canton",
                "Bracken Shire",
            ],
            "streets": ["Alden", "Merrow", "Kestral", "Northvale", "Bracken"],
            "passportName": lambda fn, ln: f"{ln.upper()}, {fn}",
            "passportIssuingAuthority": "Aldenport Ministry of Civil Affairs",
            "salaryRange": (32000, 95000),
            "postalLen": 6,
        },
        {
            "code": "valdorian",
            "name": "Kingd. of Valdoria",
            "nameOrigin": "american",
            "passportFormat": lambda n: f"VD-{n // 10000:02d}-{n % 10000:06d}",
            "nationalIdPrefix": "VAL",
            "taxPrefix": "VTX",
            "currency": "VAL",
            "cities": ["Kingsport", "Harwick", "Eastmere", "Stonebridge", "Whitford"],
            "regions": [
                "Crownshire",
                "Eastmere County",
                "Harwick Parish",
                "Stonebridge Ward",
                "Whitford Vale",
            ],
            "streets": ["Crown", "Harwick", "Eastmere", "Stone", "Whit"],
            "passportName": lambda fn, ln: f"{fn.upper()} {ln.upper()}",
            "passportIssuingAuthority": "Kingsport Royal Identity Office",
            "salaryRange": (25000, 78000),
            "postalLen": 5,
        },
        {
            "code": "kethran",
            "name": "Kethran Fed",
            "nameOrigin": "canadian",
            "passportFormat": lambda n: f"KF-{n:08d}",
            "nationalIdPrefix": "KTH",
            "taxPrefix": "KTX",
            "currency": "KTH",
            "cities": ["Veldmark", "Ironmere", "Colden Reach", "Ashford Bay", "Glimmergate"],
            "regions": [
                "Northern Reach",
                "Ironmere Terr",
                "Ashford Coast",
                "Glimmergate Pr",
                "Veldmark Dist",
            ],
            "streets": ["Veld", "Iron", "Colden", "Ash", "Glimmer"],
            "passportName": lambda fn, ln: f"{fn} {ln[0]}. {ln}",
            "passportIssuingAuthority": "Veldmark Federal Registry Building",
            "salaryRange": (30000, 110000),
            "postalLen": 7,
        },
        {
            "code": "meridian",
            "name": "Meridian Commonwealth",
            "nameOrigin": "mexican",
            "passportFormat": lambda n: f"MC-{n:08d}",
            "nationalIdPrefix": "MER",
            "taxPrefix": "MTX",
            "currency": "MRD",
            "cities": ["Solhaven", "Brasswell", "Cinderford", "Maravel", "Port Selene"],
            "regions": [
                "Solhaven Canton",
                "Brasswell March",
                "Cinderford Ward",
                "Maravel Prefecture",
                "Selene Coast",
            ],
            "streets": ["Sol", "Brass", "Cinder", "Mara", "Selene"],
            "passportName": lambda fn, ln: (
                f"{fn} {random.choice(['Elira', 'Torin', 'Sera', 'Davan'])} {ln}"
            ),
            "passportIssuingAuthority": "Solhaven Commonwealth Documentation Hall",
            "salaryRange": (180000, 850000),
            "postalLen": 6,
        },
        {
            "code": "ostmark",
            "name": "Ostmark Concordat",
            "nameOrigin": "american",
            "passportFormat": lambda n: f"OC{n:09d}",
            "nationalIdPrefix": "OST",
            "taxPrefix": "OTX",
            "currency": "OST",
            "cities": ["Grimwald", "Falkenheim", "Duskreach", "Wolfsburg", "Eisenholt"],
            "regions": [
                "Grimwald Canton",
                "Falkenheim March",
                "Duskreach Prefecture",
                "Wolfsburg Territory",
                "Eisenholt District",
            ],
            "streets": ["Grim", "Falken", "Dusk", "Wolf", "Eisen"],
            "passportName": lambda fn, ln: f"{ln} / {fn}",
            "passportIssuingAuthority": "Grimwald Concordat Civic Registry",
            "salaryRange": (28000, 120000),
            "postalLen": 5,
        },
    ]

    occupations = [
        ("Teacher", 0.9),
        ("Nurse", 1.0),
        ("Software Developer", 1.4),
        ("Electrician", 1.05),
        ("Retail Manager", 0.95),
        ("Civil Engineer", 1.25),
        ("Chef", 0.85),
        ("Police Officer", 1.1),
        ("Accountant", 1.15),
        ("Truck Driver", 0.88),
        ("Dental Hygienist", 1.05),
        ("Plumber", 1.08),
        ("Graphic Designer", 0.92),
        ("Pharmacist", 1.35),
        ("Construction Foreman", 1.12),
        ("Bank Teller", 0.82),
        ("Real Estate Agent", 1.0),
        ("Mechanic", 0.95),
        ("Librarian", 0.8),
        ("Paramedic", 1.02),
    ]

    street_types = ["Way", "Lane", "Boulevard", "Road", "Path", "Arcade"]
    blood = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    eyes = ["Brown", "Blue", "Green", "Hazel", "Gray"]
    sexes = ["M", "F"]
    marital = ["single", "married", "divorced", "widowed"]

    used_pairs = set()
    citizens = []
    seq = 100001

    for country in countries:
        origin = country["nameOrigin"]
        firsts = pool(names_db, "firstNames", origin, funny=False)
        lasts = pool(names_db, "surnames", origin, funny=False)
        if len(firsts) < 10 or len(lasts) < 10:
            firsts = pool(names_db, "firstNames", funny=False)
            lasts = pool(names_db, "surnames", funny=False)

        for _ in range(10):
            for _attempt in range(200):
                fn = ascii_name(random.choice(firsts))
                ln = ascii_name(random.choice(lasts))
                if (fn, ln) not in used_pairs:
                    used_pairs.add((fn, ln))
                    break

            occ, mult = random.choice(occupations)
            lo, hi = country["salaryRange"]
            salary = int(random.randint(lo, hi) * mult)

            dob = date(1955, 1, 1) + timedelta(days=random.randint(0, 22000))
            age = (date(2026, 5, 23) - dob).days // 365
            city = random.choice(country["cities"])
            region = shorten_region(random.choice(country["regions"]))
            street_num = random.randint(100, 9899)
            street = (
                f"{street_num} {random.choice(country['streets'])} {random.choice(street_types)}"
            )
            postal = "".join(random.choices("0123456789", k=country["postalLen"]))

            passport_num = seq
            seq += 1
            passport_id = country["passportFormat"](passport_num)
            passport_name = country["passportName"](fn, ln)

            digest = hashlib.sha1(f"{fn}{ln}{passport_id}".encode()).hexdigest()[:10].upper()
            national_id = make_national_id(digest)
            tax_id = f"{country['taxPrefix']}-{digest}"

            issue = date(2020, 1, 1) + timedelta(days=random.randint(0, 1800))
            try:
                expiry = issue.replace(year=issue.year + 10)
            except ValueError:
                # Handles leap-day issue dates by rolling to Feb 28.
                expiry = issue.replace(month=2, day=28, year=issue.year + 10)
            sex_value = random.choice(sexes)
            place_of_birth = f"{random.choice(country['cities'])}, {country['name']}"

            citizens.append(
                {
                    "registryId": f"CIT-{country['code'].upper()}-{passport_num:06d}",
                    "passportId": passport_id,
                    "nationalId": national_id,
                    "taxId": tax_id,
                    "firstName": fn,
                    "lastName": ln,
                    "passportName": passport_name,
                    "country": country["code"],
                    "countryFullName": country["name"],
                    "nationality": country["name"],
                    "dateOfBirth": dob.isoformat(),
                    "placeOfBirth": place_of_birth,
                    "sex": sex_value,
                    "maritalStatus": random.choice(marital),
                    "occupation": occ,
                    "averageAnnualSalary": salary,
                    "salaryCurrency": country["currency"],
                    "address": {
                        "street": street,
                        "city": city,
                        "region": region,
                        "postalCode": postal,
                        "country": country["name"],
                    },
                    "phone": make_phone(),
                    "email": make_email(fn, ln, country["code"]),
                    "bloodType": random.choice(blood),
                    "heightCm": random.randint(155, 198),
                    "eyeColor": random.choice(eyes),
                    "passportIssued": issue.isoformat(),
                    "passportExpires": expiry.isoformat(),
                    "voterRegistered": random.choice([True, True, True, False]),
                    "militaryService": random.choice(["none", "none", "completed", "exempt"]),
                    "emergencyContact": {
                        "name": f"{random.choice(firsts)} {ln}",
                        "relationship": random.choice(
                            ["spouse", "parent", "sibling", "child", "friend"]
                        ),
                        "phone": make_phone(),
                    },
                    "bankRiskFlags": [],
                    "criminalRecord": "none",
                    "yearsAtAddress": random.randint(1, 25),
                    "dependents": random.randint(0, 3) if age > 22 else 0,
                    "passportDoc": {
                        "passportId": passport_id,
                        "nationalId": national_id,
                        "firstName": fn,
                        "lastName": ln,
                        "dateOfBirth": dob.isoformat(),
                        "sex": sex_value,
                        "placeOfBirth": place_of_birth,
                        "issuingAuthority": country["passportIssuingAuthority"],
                        "dateOfExpiration": "",
                        "issuedDate": issue.isoformat(),
                    },
                    "idCardDoc": {
                        "nationalId": national_id,
                        "firstName": fn,
                        "lastName": ln,
                        "dateOfBirth": dob.isoformat(),
                        "sex": sex_value,
                        "address": {
                            "street": street,
                            "city": city,
                            "region": region,
                            "postalCode": postal,
                            "country": country["name"],
                        },
                    },
                    "employmentContractDoc": {
                        "firstName": fn,
                        "lastName": ln,
                        "occupation": occ,
                        "annualSalary": salary,
                        "salaryCurrency": country["currency"],
                    },
                }
            )

    payload = {
        "meta": {
            "count": len(citizens),
            "countries": [c["code"] for c in countries],
            "generated": "2026-05-23",
            "nameSource": "static/client_names.json",
        },
        "citizens": citizens,
    }

    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)

    print(f"Wrote {len(citizens)} citizens to {OUT_PATH}")


if __name__ == "__main__":
    main()
