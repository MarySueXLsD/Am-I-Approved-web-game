"""Loan scenario math and dialogue generation for citizens.json visits."""

from __future__ import annotations

import math
import random
from typing import Any

KTH_PER_LOR = 68.42
OST_PER_LOR = 157.83
VAL_PER_LOR = 0.27
MRD_PER_LOR = 34.17

PRODUCT_PROFILES = {
    "personal": {
        "base_rate": 11.5,
        "secured_discount": 0.50,
        "unsecured_premium": 1.25,
    },
    "auto": {
        "base_rate": 7.5,
        "secured_discount": 0.75,
        "unsecured_premium": 1.0,
    },
    "mortgage": {
        "base_rate": 5.25,
        "secured_discount": 0.40,
        "unsecured_premium": 0.50,
    },
}

AMOUNT_TIERS = [
    (0, 0.0),
    (25000, 0.25),
    (75000, 0.50),
    (200000, 0.75),
    (500000, 1.0),
]

AFFORDABLE_MIN_REMAINING = 30.0
MARGINAL_MIN_REMAINING = 10.0
MAX_DTI_AFFORDABLE = 35.0
MAX_DTI_MARGINAL = 45.0
MIN_NOTE_RATE = 2.0

LOAN_THEMES = [
    {
        "key": "wedding",
        "products": ["personal"],
        "secured_bias": 0.72,
        "marital": {"married"},
        "opening": [
            "Hey! How are you?",
            "I need a loan for my wedding.",
            "About {amount} LOR should cover it.",
            "Here's my ID.",
        ],
        "borrow_amount": "About {amount} LOR — for the wedding wishlist.",
        "loan_purpose": "The wedding — venue, catering, all of it.",
        "loan_security_unsure": True,
        "loan_security_answer": "Oh! Let's make it secure.",
        "small_talk_label": "How's the wedding planning?",
        "small_talk": [
            "Stressful — but exciting!",
            "The wishlist keeps growing though.",
        ],
        "thanks": ["Thank you!", "She's going to love this.", "Have a good one!"],
    },
    {
        "key": "car",
        "products": ["auto", "personal"],
        "secured_bias": 0.85,
        "opening": [
            "Hi there.",
            "I'm looking to finance a car.",
            "I need about {amount} LOR.",
            "Here's my ID.",
        ],
        "borrow_amount": "Around {amount} LOR — for the car.",
        "loan_purpose": "A used car — something reliable for work.",
        "loan_security_unsure": False,
        "small_talk_label": "Found a good car yet?",
        "small_talk": [
            "A few options — trying not to rush it.",
            "Just need the loan sorted first.",
        ],
        "thanks": ["Perfect.", "I'll pick it up this weekend.", "Thanks for your help!"],
    },
    {
        "key": "home_repair",
        "products": ["personal", "mortgage"],
        "secured_bias": 0.55,
        "opening": [
            "Hello.",
            "We've got roof damage after last month's storms.",
            "I need roughly {amount} LOR to cover repairs.",
            "Here's my ID.",
        ],
        "borrow_amount": "About {amount} LOR — roof and gutter work.",
        "loan_purpose": "Home repairs — the roof can't wait.",
        "loan_security_unsure": True,
        "loan_security_answer": "Secured sounds safer — let's do that.",
        "small_talk_label": "How bad was the damage?",
        "small_talk": [
            "Bad enough that we tarped the attic.",
            "Insurance is dragging their feet.",
        ],
        "thanks": ["That helps a lot.", "Contractor's booked for next week.", "Appreciate it."],
    },
    {
        "key": "debt",
        "products": ["personal"],
        "secured_bias": 0.25,
        "opening": [
            "Hi.",
            "I'd like to consolidate some debts.",
            "About {amount} LOR should clear the high-interest stuff.",
            "Here's my ID.",
        ],
        "borrow_amount": "Around {amount} LOR — to consolidate debts.",
        "loan_purpose": "Paying off credit cards and a store loan.",
        "loan_security_unsure": False,
        "small_talk_label": "Been juggling a lot of bills?",
        "small_talk": [
            "More than I'd like to admit.",
            "One payment would be a relief.",
        ],
        "thanks": ["That's a weight off.", "Thanks for walking me through it.", "Have a good one."],
    },
    {
        "key": "education",
        "products": ["personal"],
        "secured_bias": 0.35,
        "opening": [
            "Good morning.",
            "I'm paying for a professional certification course.",
            "I need about {amount} LOR.",
            "Here's my ID.",
        ],
        "borrow_amount": "About {amount} LOR — tuition and materials.",
        "loan_purpose": "A certification program — career advancement.",
        "loan_security_unsure": False,
        "small_talk_label": "What are you studying?",
        "small_talk": [
            "Advanced accounting — night classes.",
            "Worth it if it lands a better role.",
        ],
        "thanks": ["Great.", "Classes start next month.", "Thanks!"],
    },
    {
        "key": "medical",
        "products": ["personal"],
        "secured_bias": 0.30,
        "opening": [
            "Hello.",
            "I have medical bills that didn't fully clear.",
            "I'm hoping for about {amount} LOR.",
            "Here's my ID.",
        ],
        "borrow_amount": "Around {amount} LOR — outstanding medical bills.",
        "loan_purpose": "Hospital and follow-up care costs.",
        "loan_security_unsure": False,
        "small_talk_label": "Everything alright now?",
        "small_talk": [
            "Much better, thanks.",
            "Just cleaning up the paperwork side.",
        ],
        "thanks": ["Thank you.", "That's a huge help.", "Goodbye."],
    },
    {
        "key": "general",
        "products": ["personal"],
        "secured_bias": 0.45,
        "opening": [
            "Hi — thanks for seeing me.",
            "I'd like to apply for a personal loan.",
            "I'm looking at about {amount} LOR.",
            "Here's my ID.",
        ],
        "borrow_amount": "About {amount} LOR.",
        "loan_purpose": "Personal expenses — some planned, some not.",
        "loan_security_unsure": True,
        "loan_security_answer": "Unsecured is fine — keep it simple.",
        "small_talk_label": "Busy day at the branch?",
        "small_talk": [
            "Seems like it!",
            "Glad I caught you.",
        ],
        "thanks": ["Thanks.", "Appreciate the help.", "Have a good one!"],
    },
]


def format_lor(value: float) -> str:
    rounded = int(round(value))
    negative = rounded < 0
    digits = str(abs(rounded))
    parts = []
    while digits:
        parts.insert(0, digits[-3:])
        digits = digits[:-3]
    text = ",".join(parts)
    return f"-{text}" if negative else text


def amount_tier_discount(amount: float) -> float:
    discount = 0.0
    for min_amount, rate_discount in AMOUNT_TIERS:
        if amount >= min_amount:
            discount = rate_discount
    return discount


def resolve_note_rate(product: str, amount: float, security: str) -> float:
    profile = PRODUCT_PROFILES.get(product, PRODUCT_PROFILES["personal"])
    discount = amount_tier_discount(amount)
    if security == "secured":
        adjustment = -profile["secured_discount"]
    else:
        adjustment = profile["unsecured_premium"]
    note_rate = profile["base_rate"] - discount + adjustment
    return max(MIN_NOTE_RATE, note_rate)


def amortized_payment(principal: float, months: int, annual_note_rate: float) -> float:
    if months <= 0:
        return 0.0
    monthly_rate = annual_note_rate / 100.0 / 12.0
    if monthly_rate <= 0.0000001:
        return principal / months
    factor = (1 + monthly_rate) ** months
    return principal * monthly_rate * factor / (factor - 1)


def assess_verdict(disposable: float, afford_pct: float, dti: float) -> str:
    if disposable <= 0 or afford_pct < 0:
        return "NOT AFFORDABLE"
    if dti > MAX_DTI_MARGINAL or afford_pct < MARGINAL_MIN_REMAINING:
        return "NOT AFFORDABLE"
    if dti > MAX_DTI_AFFORDABLE or afford_pct < AFFORDABLE_MIN_REMAINING:
        return "MARGINAL"
    return "AFFORDABLE"


def compute_affordability(
    *,
    amount: float,
    term: int,
    monthly_salary: float,
    housing: float,
    living: float,
    other: float,
    product: str,
    security: str,
) -> dict[str, Any]:
    note_rate = resolve_note_rate(product, amount, security)
    payment = amortized_payment(amount, term, note_rate)
    total_spending = housing + living + other
    disposable = monthly_salary - total_spending
    dti = (payment / monthly_salary * 100.0) if monthly_salary > 0 else 0.0
    afford_pct = ((disposable - payment) / disposable * 100.0) if disposable > 0 else 0.0
    verdict = assess_verdict(disposable, afford_pct, dti)
    return {
        "note_rate": note_rate,
        "monthly_payment": payment,
        "disposable": disposable,
        "dti": dti,
        "afford_pct": afford_pct,
        "verdict": verdict,
    }


def derive_expenses(annual_salary: float, dependents: int, marital_status: str) -> tuple[float, float, float]:
    monthly = max(0, annual_salary / 12.0)
    if monthly <= 0:
        return 700.0, 400.0, 150.0

    housing_ratio = 0.34 if marital_status in ("married", "widowed") else 0.28
    housing = round(monthly * housing_ratio / 50.0) * 50.0
    housing = max(600.0, min(housing, 1800.0))

    living_base = 650.0 + dependents * 120.0
    living = round(living_base / 25.0) * 25.0
    living = max(500.0, min(living, 1200.0))

    other = round((monthly * 0.08 + dependents * 40.0) / 25.0) * 25.0
    other = max(100.0, min(other, 350.0))
    return housing, living, other


def pick_theme(citizen: dict[str, Any], rng: random.Random) -> dict[str, Any]:
    marital = citizen.get("maritalStatus", "single")
    scored = []
    for theme in LOAN_THEMES:
        score = 1.0
        allowed = theme.get("marital")
        if allowed and marital not in allowed:
            score -= 2.0
        scored.append((score + rng.random() * 0.5, theme))
    scored.sort(key=lambda item: item[0], reverse=True)
    return scored[0][1]


def find_affordable_terms(
    *,
    amount: float,
    monthly_salary: float,
    housing: float,
    living: float,
    other: float,
    product: str,
    security: str,
    target_payment: float,
    payment_tolerance: float,
) -> list[int]:
    acceptable: list[int] = []
    for term in range(6, 73):
        calc = compute_affordability(
            amount=amount,
            term=term,
            monthly_salary=monthly_salary,
            housing=housing,
            living=living,
            other=other,
            product=product,
            security=security,
        )
        if calc["verdict"] != "AFFORDABLE":
            continue
        payment = calc["monthly_payment"]
        if abs(payment - target_payment) <= payment_tolerance:
            acceptable.append(term)
    if acceptable:
        return acceptable[-3:]
    for term in range(6, 73):
        calc = compute_affordability(
            amount=amount,
            term=term,
            monthly_salary=monthly_salary,
            housing=housing,
            living=living,
            other=other,
            product=product,
            security=security,
        )
        if calc["verdict"] == "AFFORDABLE":
            acceptable.append(term)
    return acceptable[-3:] if acceptable else [24]


def build_loan_package(
    citizen: dict[str, Any],
    *,
    amount: float | None = None,
    product: str | None = None,
    security: str | None = None,
    theme: dict[str, Any] | None = None,
    rng: random.Random,
) -> dict[str, Any]:
    annual = float(citizen.get("averageAnnualSalary") or 0)
    monthly_salary = round(annual / 12.0) if annual > 0 else 0
    dependents = int(str(citizen.get("dependents", 0)) or 0)
    marital = citizen.get("maritalStatus", "single")

    housing, living, other = derive_expenses(annual, dependents, marital)
    disposable = max(0.0, monthly_salary - housing - living - other)

    if theme is None:
        theme = pick_theme(citizen, rng)

    if product is None:
        product = rng.choice(theme["products"])

    if security is None:
        secured_bias = theme.get("secured_bias", 0.5)
        security = "secured" if rng.random() < secured_bias else "unsecured"

    if amount is None:
        if annual > 0:
            ratio = rng.uniform(0.35, 0.75)
            raw_amount = annual * ratio
            amount = round(raw_amount / 500.0) * 500.0
            amount = max(12000.0, min(amount, 60000.0))
        else:
            amount = float(rng.choice([15000, 20000, 25000, 30000, 35000]))

    if disposable > 0:
        target_payment = round(disposable * rng.uniform(0.45, 0.62) / 25.0) * 25.0
        target_payment = max(450.0, min(target_payment, 2200.0))
    else:
        target_payment = 1200.0

    payment_tolerance = max(75.0, round(target_payment * 0.08 / 25.0) * 25.0)
    terms = find_affordable_terms(
        amount=amount,
        monthly_salary=max(monthly_salary, 1.0),
        housing=housing,
        living=living,
        other=other,
        product=product,
        security=security,
        target_payment=target_payment,
        payment_tolerance=payment_tolerance,
    )
    primary_term = terms[-1]
    calc = compute_affordability(
        amount=amount,
        term=primary_term,
        monthly_salary=max(monthly_salary, 1.0),
        housing=housing,
        living=living,
        other=other,
        product=product,
        security=security,
    )

    amount_text = format_lor(amount)
    dialogue = {
        "opening": [line.format(amount=amount_text) for line in theme["opening"]],
        "borrow_amount": theme["borrow_amount"].format(amount=amount_text),
        "loan_purpose": theme["loan_purpose"],
        "loan_security": (
            "secured"
            if security == "secured"
            else ("unsecured" if not theme.get("loan_security_unsure") else "secured")
        ),
        "loan_security_unsure": bool(theme.get("loan_security_unsure")),
        "loan_security_answer": theme.get("loan_security_answer", "Unsecured is fine."),
        "living_expenses": [
            f"Rent's about {format_lor(housing)}.",
            f"Living costs maybe {format_lor(living)}, other stuff around {format_lor(other)}.",
        ],
        "comfortable_rate": f"Around {format_lor(target_payment)} LOR a month — give or take {format_lor(payment_tolerance)}.",
        "annual_salary": "Check your database.",
        "monthly_salary": "Not sure — divide my annual salary by twelve.",
        "small_talk_label": theme["small_talk_label"],
        "small_talk": list(theme["small_talk"]),
        "thanks": list(theme["thanks"]),
        "quickAnswers": {
            "borrow_amount": f"{amount_text} LOR.",
            "loan_purpose": theme["loan_purpose"].split("—")[0].strip().rstrip(".") + ".",
            "loan_security": "Secured." if security == "secured" else "Unsecured.",
            "living_expenses": f"{format_lor(housing)} housing, {format_lor(living)} living, {format_lor(other)} other.",
            "comfortable_rate": f"About {format_lor(target_payment)} LOR a month.",
            "annual_salary": "Check the database.",
            "monthly_salary": "Use the annual from the system.",
        },
    }

    return {
        "loanAmountLOR": int(round(amount)),
        "loanProduct": product,
        "loanSecurity": security,
        "loanTerms": terms,
        "comfortablePaymentLOR": round(target_payment),
        "comfortablePaymentToleranceLOR": round(payment_tolerance),
        "spendHousingLOR": round(housing),
        "spendLivingLOR": round(living),
        "spendOtherLOR": round(other),
        "expectedMonthlySalaryLOR": monthly_salary,
        "primaryTermMonths": primary_term,
        "affordabilityVerdict": calc["verdict"],
        "monthlyPaymentLOR": round(calc["monthly_payment"]),
        "theme": theme["key"],
        "dialogue": dialogue,
    }


def chef_tutorial_loan() -> dict[str, Any]:
    amount = 25500
    housing, living, other = 700, 400, 150
    monthly_salary = 3500
    target_payment = 1200
    payment_tolerance = 125
    terms = [24]
    return {
        "loanAmountLOR": amount,
        "loanProduct": "personal",
        "loanSecurity": "unsecured",
        "loanTerms": terms,
        "comfortablePaymentLOR": target_payment,
        "comfortablePaymentToleranceLOR": payment_tolerance,
        "spendHousingLOR": housing,
        "spendLivingLOR": living,
        "spendOtherLOR": other,
        "expectedMonthlySalaryLOR": monthly_salary,
        "primaryTermMonths": 24,
        "theme": "tutorial",
        "dialogue": {
            "opening": [],
            "borrow_amount": f"{format_lor(amount)} LOR.",
            "loan_purpose": "Personal — same as on the application.",
            "loan_security": "unsecured",
            "living_expenses": [
                f"About {format_lor(housing)} for housing, {format_lor(living)} living, and {format_lor(other)} other."
            ],
            "comfortable_rate": f"Around {format_lor(target_payment)} LOR a month.",
            "annual_salary": "42,000 LOR — you just fixed that for me.",
            "monthly_salary": "Annual divided by twelve.",
            "quickAnswers": {
                "borrow_amount": f"{format_lor(amount)} LOR.",
                "loan_purpose": "Personal — check the application.",
                "loan_security": "Not secured.",
                "living_expenses": f"{format_lor(housing)} housing, {format_lor(living)} living, {format_lor(other)} other.",
                "comfortable_rate": f"About {format_lor(target_payment)} LOR a month.",
                "annual_salary": "42,000 LOR — check the system.",
                "monthly_salary": "Annual divided by twelve.",
            },
        },
    }


def first_client_wedding_loan() -> dict[str, Any]:
    amount = 35000
    housing, living, other = 1200, 900, 200
    monthly_salary = 0
    target_payment = 1600
    payment_tolerance = 100
    terms = [23, 24, 25]
    theme = LOAN_THEMES[0]
    amount_text = format_lor(amount)
    return {
        "loanAmountLOR": amount,
        "loanProduct": "personal",
        "loanSecurity": "secured",
        "loanTerms": terms,
        "comfortablePaymentLOR": target_payment,
        "comfortablePaymentToleranceLOR": payment_tolerance,
        "spendHousingLOR": housing,
        "spendLivingLOR": living,
        "spendOtherLOR": other,
        "expectedMonthlySalaryLOR": monthly_salary,
        "primaryTermMonths": 24,
        "theme": "wedding",
        "dialogue": {
            "opening": [line.format(amount=amount_text) for line in theme["opening"]],
            "borrow_amount": theme["borrow_amount"].format(amount=amount_text),
            "loan_purpose": theme["loan_purpose"],
            "loan_security": "secured",
            "loan_security_unsure": True,
            "loan_security_answer": theme["loan_security_answer"],
            "living_expenses": [
                f"Rent's about {format_lor(housing)}.",
                f"Living costs maybe {format_lor(living)}, other stuff around {format_lor(other)}.",
            ],
            "comfortable_rate": f"Around {format_lor(target_payment)} LOR a month — give or take {format_lor(payment_tolerance)}.",
            "annual_salary": "Check your database.",
            "monthly_salary": "Not sure — I submitted my contract a while back. Divide by twelve.",
            "small_talk_label": theme["small_talk_label"],
            "small_talk": list(theme["small_talk"]),
            "thanks": [
                "Thank you!",
                "They're going to love this.",
                "Have a good one!",
            ],
            "quickAnswers": {
                "borrow_amount": f"{amount_text} LOR.",
                "loan_purpose": "For the wedding.",
                "loan_security": "Secured.",
                "living_expenses": f"{format_lor(housing)} housing, {format_lor(living)} living, {format_lor(other)} other.",
                "comfortable_rate": f"About {format_lor(target_payment)} LOR a month.",
                "annual_salary": "Check the database.",
                "monthly_salary": "Use the annual from the system.",
            },
        },
    }
