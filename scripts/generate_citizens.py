import hashlib
import json
import random
import sys
import unicodedata
from copy import deepcopy
from datetime import date, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from loan_scenario_calc import (  # noqa: E402
    build_loan_package,
    chef_tutorial_loan,
    first_client_wedding_loan,
    format_lor,
)

random.seed(42)

ROOT = Path(__file__).resolve().parents[1]
NAMES_PATH = ROOT / "static" / "client_names.json"
OUT_PATH = ROOT / "static" / "citizens.json"

PER_COUNTRY = 20
GAME_YEAR = 1986
GAME_DATE = date(GAME_YEAR, 6, 7)
MIN_AGE = 20
MAX_AGE = 40
OST_TO_LOR_RATE = 157.83
SALARY_CURRENCY = "LOR"
VADZIM_CONTRACT_OST = 13_453_560
VADZIM_SALARY_LOR = 85240.82
CHEF_NATIONAL_ID = "AAA3493A"


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
    clean_last = last_name.replace("-", "").replace("'", "")
    local = f"{first_name[0].lower()}{clean_last[:5].lower()}"
    email = f"{local}@{domain}.m"
    if len(email) > 16:
        email = f"{first_name[0].lower()}{clean_last[:3].lower()}@{domain}.m"
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


def build_citizen(country, fn, ln, passport_num, names_db, scenario=None, overrides=None):
    origin = country["nameOrigin"]
    firsts = pool(names_db, "firstNames", origin, funny=False)
    lasts = pool(names_db, "surnames", origin, funny=False)
    if len(firsts) < 10 or len(lasts) < 10:
        firsts = pool(names_db, "firstNames", funny=False)
        lasts = pool(names_db, "surnames", funny=False)

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

    occ, mult = random.choice(occupations)
    lo, hi = country["salaryRange"]
    salary = int(random.randint(lo, hi) * mult)

    dob_start = GAME_DATE.replace(year=GAME_YEAR - MAX_AGE)
    dob_end = GAME_DATE.replace(year=GAME_YEAR - MIN_AGE)
    dob = dob_start + timedelta(days=random.randint(0, (dob_end - dob_start).days))
    age = (GAME_DATE - dob).days // 365
    city = random.choice(country["cities"])
    region = shorten_region(random.choice(country["regions"]))
    street_num = random.randint(100, 9899)
    street = f"{street_num} {random.choice(country['streets'])} {random.choice(street_types)}"
    postal = "".join(random.choices("0123456789", k=country["postalLen"]))

    passport_id = country["passportFormat"](passport_num)
    passport_name = country["passportName"](fn, ln)

    digest = hashlib.sha1(f"{fn}{ln}{passport_id}".encode()).hexdigest()[:10].upper()
    national_id = make_national_id(digest)
    tax_id = f"{country['taxPrefix']}-{digest}"

    adult_on = date(dob.year + 18, dob.month, min(dob.day, 28))
    issue_earliest = max(adult_on, date(GAME_YEAR - 10, 1, 1))
    issue_span = max(0, (GAME_DATE - issue_earliest).days)
    issue = issue_earliest + timedelta(days=random.randint(0, issue_span))
    try:
        expiry = issue.replace(year=issue.year + 10)
    except ValueError:
        expiry = issue.replace(month=2, day=28, year=issue.year + 10)
    sex_value = random.choice(sexes)
    place_of_birth = f"{random.choice(country['cities'])}, {country['name']}"

    citizen = {
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
        "salaryCurrency": SALARY_CURRENCY,
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
            "relationship": random.choice(["spouse", "parent", "sibling", "child", "friend"]),
            "phone": make_phone(),
        },
        "bankRiskFlags": [],
        "criminalRecord": "none",
        "yearsAtAddress": random.randint(1, max(1, min(age - 5, 18))),
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
            "salaryCurrency": SALARY_CURRENCY,
        },
    }

    if scenario:
        citizen["visit"] = deepcopy(scenario)

    if overrides:
        for key, value in overrides.items():
            if isinstance(value, dict) and isinstance(citizen.get(key), dict):
                citizen[key].update(value)
            else:
                citizen[key] = value

    return citizen


def apply_identity(citizen, first_name, last_name, sex):
    citizen["firstName"] = first_name
    citizen["lastName"] = last_name
    citizen["sex"] = sex
    citizen["passportDoc"]["firstName"] = first_name
    citizen["passportDoc"]["lastName"] = last_name
    citizen["passportDoc"]["sex"] = sex
    citizen["idCardDoc"]["firstName"] = first_name
    citizen["idCardDoc"]["lastName"] = last_name
    citizen["idCardDoc"]["sex"] = sex
    citizen["employmentContractDoc"]["firstName"] = first_name
    citizen["employmentContractDoc"]["lastName"] = last_name


def apply_scenario_mismatch(citizen, mismatch_type):
    if mismatch_type == "passport_dob":
        wrong = date.fromisoformat(citizen["dateOfBirth"]) + timedelta(days=random.randint(365, 4000))
        citizen["passportDoc"]["dateOfBirth"] = wrong.isoformat()
    elif mismatch_type == "passport_name":
        citizen["passportDoc"]["lastName"] = citizen["passportDoc"]["lastName"] + "X"
    elif mismatch_type == "id_name":
        citizen["idCardDoc"]["firstName"] = citizen["idCardDoc"]["firstName"][:-1] + "a"
    elif mismatch_type == "contract_salary":
        citizen["employmentContractDoc"]["annualSalary"] = int(
            citizen["employmentContractDoc"]["annualSalary"] * 1.15
        )
    elif mismatch_type == "db_salary_low":
        citizen["averageAnnualSalary"] = int(citizen["averageAnnualSalary"] * 0.6)
    elif mismatch_type == "national_id":
        citizen["passportDoc"]["nationalId"] = citizen["nationalId"][:-1] + "0"


def scenario_loan_approve(amount):
    return {
        "purpose": "loan",
        "target": f"Loan {amount} LOR approved because all data is correct",
        "loanAmountLOR": amount,
        "outcome": "approve",
    }


def scenario_loan_decline(reason):
    return {
        "purpose": "loan",
        "target": f"Decline loan: {reason}",
        "outcome": "decline",
    }


def scenario_db_change(field_path, correct_value, reason, tolerance=None):
    visit = {
        "purpose": "loan",
        "target": f"DB change: set {field_path} to {correct_value} — {reason}",
        "outcome": "approve_after_db_change",
        "dbChange": {"path": field_path, "value": str(correct_value)},
    }
    if tolerance is not None:
        visit["valueTolerance"] = tolerance
    return visit


def scenario_input_change(field, value, reason):
    return {
        "purpose": "loan",
        "target": f"Inputs: set {field} to {value} — {reason}",
        "outcome": "approve_after_input_change",
        "inputChange": {"field": field, "value": str(value)},
    }


def attach_loan_details(visit, citizen, rng, *, amount=None, product=None, security=None, theme=None):
    loan = build_loan_package(
        citizen,
        amount=amount,
        product=product,
        security=security,
        theme=theme,
        rng=rng,
    )
    visit.update(loan)
    return visit


def db_change_opening_dialogue(loan_amount_text, reason):
    return [
        "Hi — I'm here about a loan and a database fix.",
        f"I need about {loan_amount_text} LOR.",
        reason,
        "Here's my ID and contract.",
    ]


def input_change_opening_dialogue(loan_amount_text):
    return [
        "Hello.",
        f"I'd like to borrow around {loan_amount_text} LOR.",
        "Everything should be on file already.",
        "Here's my ID.",
    ]


def decline_opening_dialogue(loan_amount_text):
    return [
        "Hi.",
        f"I need a loan — about {loan_amount_text} LOR.",
        "I'm in a bit of a hurry.",
        "Here's my ID.",
    ]


def main():
    names_db = load_names()

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

    scenario_plan = [
        ("loan_approve", 40),
        ("loan_decline", 18),
        ("db_change", 14),
        ("input_change", 12),
        ("correct_values", 16),
    ]
    scenario_queue = []
    for kind, count in scenario_plan:
        scenario_queue.extend([kind] * count)
    random.shuffle(scenario_queue)

    decline_reasons = [
        "passport date of birth does not match ID card",
        "passport name does not match registry",
        "employment contract salary does not match database",
        "national ID on passport does not match registry",
        "applicant has no salary on file",
        "ID card name does not match registry",
        "database salary is far below contract amount",
    ]
    mismatch_for_decline = {
        "passport date of birth does not match ID card": "passport_dob",
        "passport name does not match registry": "passport_name",
        "employment contract salary does not match database": "contract_salary",
        "national ID on passport does not match registry": "national_id",
        "ID card name does not match registry": "id_name",
        "database salary is far below contract amount": "db_salary_low",
    }

    loan_amounts = [15000, 20000, 25000, 30000, 35000, 40000, 45000, 50000, 55000, 60000]

    used_pairs = set()
    citizens = []
    seq = 100001
    special_by_country = {
        "kethran": ("Yerasyl", "Serik-AF"),
        "ostmark": ("Vadzim", "Trayeuski"),
        "lorian": ("Henri", "Moreau"),
    }
    extra_special_names = [
        ("Aoife", "Murphy-Smith"),
        ("Soren", "Berg-Hansen"),
        ("Lucia", "DiMarco"),
    ]
    story_identity_by_slot = {
        ("lorian", 1): ("Denis", "Grusetchii", "M"),
        ("lorian", 2): ("Garrett", "Sloan", "M"),
        ("valdorian", 1): ("Marcus", "Whitford", "M"),
        ("valdorian", 2): ("Rachel", "Ashton", "F"),
    }
    extra_special_idx = 0
    scenario_idx = 0

    for country in countries:
        origin = country["nameOrigin"]
        firsts = pool(names_db, "firstNames", origin, funny=False)
        lasts = pool(names_db, "surnames", origin, funny=False)
        if len(firsts) < 10 or len(lasts) < 10:
            firsts = pool(names_db, "firstNames", funny=False)
            lasts = pool(names_db, "surnames", funny=False)

        for slot in range(PER_COUNTRY):
            scenario_kind = scenario_queue[scenario_idx]
            scenario_idx += 1

            fn = ln = None
            story_identity = story_identity_by_slot.get((country["code"], slot))
            if story_identity is not None:
                fn, ln, _story_sex = story_identity
            elif slot == 0 and country["code"] in special_by_country:
                fn, ln = special_by_country[country["code"]]
            elif slot == 1 and extra_special_idx < len(extra_special_names):
                fn, ln = extra_special_names[extra_special_idx]
                extra_special_idx += 1

            if fn is None:
                for _attempt in range(200):
                    fn = ascii_name(random.choice(firsts))
                    ln = ascii_name(random.choice(lasts))
                    if (fn, ln) not in used_pairs:
                        used_pairs.add((fn, ln))
                        break

            passport_num = seq
            seq += 1

            visit = None
            overrides = None

            if fn == "Yerasyl" and ln == "Serik-AF":
                visit = scenario_db_change(
                    "averageAnnualSalary",
                    32446,
                    "convert monthly 185000 KTH from kethran_job_contract_with_name_1.png at 68.42 KTH/LOR",
                    tolerance=100.0,
                )
                visit["contractSalaryKTH"] = 185000
                visit["expectedSalaryLOR"] = 32446
                visit["salaryToleranceLOR"] = 100.0
                overrides = {
                    "sex": "M",
                    "salaryCurrency": SALARY_CURRENCY,
                    "averageAnnualSalary": 0,
                    "occupation": "Teacher",
                    "passportName": "Yerasyl S. Serik-AF",
                    "employmentContractDoc": {
                        "occupation": "Teacher",
                        "annualSalary": 185000,
                        "salaryCurrency": "KTH",
                    },
                }
            elif fn == "Vadzim" and ln == "Trayeuski":
                visit = scenario_db_change(
                    "averageAnnualSalary",
                    VADZIM_SALARY_LOR,
                    f"convert {VADZIM_CONTRACT_OST} OST from ostmark_job_contract_with_name_1.png at {OST_TO_LOR_RATE} OST/LOR",
                    tolerance=2.0,
                )
                visit["contractSalaryOST"] = VADZIM_CONTRACT_OST
                visit["expectedSalaryLOR"] = VADZIM_SALARY_LOR
                visit["salaryToleranceLOR"] = 2.0
                visit["loanAmountLOR"] = 40000
                overrides = {
                    "sex": "M",
                    "salaryCurrency": SALARY_CURRENCY,
                    "averageAnnualSalary": 0,
                    "occupation": "Accountant",
                    "employmentContractDoc": {
                        "firstName": "Vadzim",
                        "lastName": "Trayeuski",
                        "occupation": "Accountant",
                        "annualSalary": VADZIM_CONTRACT_OST,
                        "salaryCurrency": "OST",
                    },
                }
            elif fn == "Marcus" and ln == "Whitford":
                amount = 35000
                visit = scenario_loan_approve(amount)
                overrides = {
                    "sex": "M",
                    "maritalStatus": "married",
                    "averageAnnualSalary": 54664,
                    "salaryCurrency": SALARY_CURRENCY,
                    "employmentContractDoc": {
                        "annualSalary": 54664,
                        "salaryCurrency": SALARY_CURRENCY,
                    },
                }
            elif fn == "Denis" and ln == "Grusetchii":
                amount = 30000
                visit = scenario_loan_approve(amount)
                overrides = {"sex": "M"}
            elif fn == "Henri" and ln == "Moreau":
                visit = scenario_loan_decline("applicant has no salary on file")
                overrides = {
                    "firstName": "Henri",
                    "lastName": "Moreau",
                    "sex": "M",
                    "nationalId": CHEF_NATIONAL_ID,
                    "taxId": f"LTX-{CHEF_NATIONAL_ID}4",
                    "passportName": "MOREAU, Henri",
                    "occupation": "Branch Manager",
                    "averageAnnualSalary": 0,
                    "email": "h.moreau@lor.m",
                    "passportDoc": {"nationalId": CHEF_NATIONAL_ID},
                    "idCardDoc": {"nationalId": CHEF_NATIONAL_ID},
                    "employmentContractDoc": {
                        "firstName": "Henri",
                        "lastName": "Moreau",
                        "occupation": "Branch Manager",
                        "annualSalary": 0,
                        "salaryCurrency": "LOR",
                    },
                    "emergencyContact": {
                        "name": "Claire Moreau",
                        "relationship": "spouse",
                        "phone": "+18-721-9085",
                    },
                }
            else:
                if scenario_kind == "loan_approve":
                    amount = random.choice(loan_amounts)
                    visit = scenario_loan_approve(amount)
                elif scenario_kind == "loan_decline":
                    reason = random.choice(decline_reasons)
                    if reason == "applicant has no salary on file":
                        overrides = {
                            "averageAnnualSalary": 0,
                            "employmentContractDoc": {"annualSalary": 0},
                        }
                    visit = scenario_loan_decline(reason)
                elif scenario_kind == "db_change":
                    correct = random.randint(40000, 90000)
                    visit = scenario_db_change(
                        "averageAnnualSalary",
                        correct,
                        "database salary must match employment contract",
                    )
                    overrides = {"averageAnnualSalary": int(correct * 0.55)}
                elif scenario_kind == "input_change":
                    salary = random.randint(45000, 85000)
                    visit = scenario_input_change(
                        "declaredSalary",
                        salary,
                        "loan form salary must match verified annual income",
                    )
                elif scenario_kind == "correct_values":
                    amount = random.choice(loan_amounts)
                    visit = {
                        "purpose": "loan",
                        "target": f"Correct values verified — loan {amount} LOR approved",
                        "loanAmountLOR": amount,
                        "outcome": "approve",
                    }

            citizen = build_citizen(
                country,
                fn,
                ln,
                passport_num,
                names_db,
                scenario=visit,
                overrides=overrides,
            )

            if story_identity is not None:
                apply_identity(citizen, story_identity[0], story_identity[1], story_identity[2])
            elif fn == "Henri" and ln == "Moreau":
                apply_identity(citizen, "Henri", "Moreau", "M")
            elif fn == "Yerasyl" and ln == "Serik-AF":
                apply_identity(citizen, "Yerasyl", "Serik-AF", "M")
            elif fn == "Vadzim" and ln == "Trayeuski":
                apply_identity(citizen, "Vadzim", "Trayeuski", "M")
            elif fn == "Lucia" and ln == "DiMarco":
                apply_identity(citizen, "Lucia", "DiMarco", "F")

            if citizen.get("visit") is not None and citizen["visit"].get("purpose") == "loan":
                visit = citizen["visit"]
                if fn == "Henri" and ln == "Moreau":
                    visit.update(chef_tutorial_loan())
                    visit["dialogue"]["opening"] = []
                elif fn == "Marcus" and ln == "Whitford":
                    visit.update(first_client_wedding_loan())
                elif fn == "Yerasyl" and ln == "Serik-AF":
                    loan = build_loan_package(citizen, amount=25000, product="personal", security="unsecured", rng=random)
                    visit.update(loan)
                    visit["dialogue"]["opening"] = [
                        "Hi — I need my salary corrected in your database.",
                        "Here's my Kethran ID and job contract.",
                        "The contract lists one hundred eighty-five thousand KTH.",
                        "That's my monthly salary — not annual.",
                        "Please fix my annual salary to match.",
                    ]
                    visit["dialogue"]["borrow_amount"] = "I'm not here for a loan — just the salary update."
                    visit["dialogue"]["quickAnswers"]["borrow_amount"] = "No loan — salary update only."
                elif fn == "Vadzim" and ln == "Trayeuski":
                    loan = build_loan_package(
                        citizen,
                        amount=visit.get("loanAmountLOR", 40000),
                        product="personal",
                        security="unsecured",
                        rng=random,
                    )
                    visit.update(loan)
                    visit["dialogue"]["opening"] = [
                        "Hey. I need a loan. Today.",
                        "Forty thousand LOR — personal, unsecured.",
                        "Can we hurry? I'm late.",
                        "Here's my ID.",
                    ]
                    visit["dialogue"]["borrow_amount"] = "Forty thousand LOR. Personal."
                    visit["dialogue"]["loan_purpose"] = "Personal expenses. Look, just process it."
                    visit["dialogue"]["loan_security"] = "unsecured"
                    visit["dialogue"]["quickAnswers"]["borrow_amount"] = "40,000 LOR — hurry up."
                    visit["dialogue"]["quickAnswers"]["loan_purpose"] = "Personal."
                    visit["dialogue"]["quickAnswers"]["loan_security"] = "Unsecured."
                else:
                    preset_amount = visit.get("loanAmountLOR")
                    attach_loan_details(visit, citizen, random, amount=preset_amount)
                    amount_text = format_lor(visit["loanAmountLOR"])
                    outcome = visit.get("outcome", "approve")
                    if outcome == "approve_after_db_change":
                        reason = visit["target"].split(" — ", 1)[-1]
                        visit["dialogue"]["opening"] = db_change_opening_dialogue(amount_text, reason)
                        visit["dialogue"]["borrow_amount"] = (
                            "I'm not here for a loan today — please fix my annual salary in the database."
                        )
                        visit["dialogue"]["quickAnswers"]["borrow_amount"] = "No loan — salary update only."
                    elif outcome == "approve_after_input_change":
                        visit["dialogue"]["opening"] = input_change_opening_dialogue(amount_text)
                    elif outcome == "decline":
                        visit["dialogue"]["opening"] = decline_opening_dialogue(amount_text)
                        visit["dialogue"]["borrow_amount"] = f"{amount_text} LOR. Can we move faster?"
                        visit["dialogue"]["loan_purpose"] = "Personal. Just process it."
                        visit["dialogue"]["loan_security"] = visit.get("loanSecurity", "unsecured")
                        visit["dialogue"]["quickAnswers"]["borrow_amount"] = f"{amount_text} LOR — hurry up."
                        visit["dialogue"]["quickAnswers"]["loan_purpose"] = "Personal."

            if (
                visit
                and visit.get("outcome") == "decline"
                and visit["target"] != "Decline loan: applicant has no salary on file"
            ):
                reason = visit["target"].replace("Decline loan: ", "")
                mismatch = mismatch_for_decline.get(reason)
                if mismatch:
                    apply_scenario_mismatch(citizen, mismatch)

            citizens.append(citizen)

    payload = {
        "meta": {
            "count": len(citizens),
            "countries": [c["code"] for c in countries],
            "generated": GAME_DATE.isoformat(),
            "gameYear": GAME_YEAR,
            "nameSource": "static/client_names.json",
            "scenarioTypes": [
                "loan_approve",
                "loan_decline",
                "db_change",
                "input_change",
                "correct_values",
            ],
            "exchangeRates": {"OST_per_LOR": OST_TO_LOR_RATE},
        },
        "citizens": citizens,
    }

    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)

    print(f"Wrote {len(citizens)} citizens to {OUT_PATH}")
    featured = [c for c in citizens if c["lastName"] in ("Serik-AF", "Trayeuski", "Moreau")]
    for c in featured:
        print(f"  {c['firstName']} {c['lastName']} ({c['country']}): {c['visit']['target']}")


if __name__ == "__main__":
    main()
