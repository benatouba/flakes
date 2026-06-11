#!/usr/bin/env python3

from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from pathlib import Path
import re
import subprocess
import sys


TRANSACTION_RE = re.compile(
    r"^\s*(\d{2}\.\d{2}\.)\s+(\d{2}\.\d{2}\.)\s+(.+?)\s+([+-])\s*([\d.]+,\d{2})\s*$"
)
YEAR_LINE_RE = re.compile(r"^\s*(\d{4})\s+(\d{4})\s+(.+?)\s*$")
PERIOD_RE = re.compile(
    r"Kontoauszug vom\s+(\d{2}\.\d{2}\.\d{4})\s+bis\s+(\d{2}\.\d{2}\.\d{4})"
)
OPENING_BALANCE_RE = re.compile(
    r"Alter Saldo per\s+(\d{2}\.\d{2}\.\d{4}).*?EUR\s+([+-])\s*([\d.]+,\d{2})",
    re.S,
)
CLOSING_BALANCE_RE = re.compile(r"Neuer Saldo.*?EUR\s+([+-])\s*([\d.]+,\d{2})", re.S)
SECTION_HEADER_RE = re.compile(r"^\s*Buchung\s+Valuta\s+Vorgang")
PAGE_HEADER_RE = re.compile(r"^\s*Auszug\s+Seite\s+von\s+IBAN")
PAGE_NUMBER_RE = re.compile(r"^\s*\d+\s+\d+\s+\d+\s+DE\d{2}\b")
PAGE_FOOTER_RE = re.compile(r"^\s*\d{10}\s*/\s*\d{8}\s*/\s*\d{8}\s*$")

GENERIC_MARKER = "Verwendungszweck/ Kundenreferenz"
STOP_PREFIXES = (
    "Filialnummer",
    "Wichtige Hinweise",
    "Bitte erheben Sie",
    "Die abgerechneten Leistungen",
    "Guthaben sind als Einlagen",
)
DETAIL_METADATA_PREFIXES = (
    "IBAN ",
    "BIC ",
    "Gläubiger-ID",
    "Mand-ID",
    "RCUR ",
    "OOFF ",
    "RINP ",
    "CDBL ",
    "SALA ",
    "OTHR ",
    "CGDD ",
    "ABWA ",
    "NOWS ",
)
PAYPAL_COUNTERPARTY_AFTER_RE = re.compile(
    r"Ihr Einkauf bei (?P<merchant>.+?)(?: \d{6,}(?: [A-Z0-9.]+)* PAYPAL\b|$)"
)
PAYPAL_COUNTERPARTY_BEFORE_RE = re.compile(
    r"\d{6,}(?:\s+PP\.8221\.PP)?\s*\.\s*(?P<merchant>.+?), Ihr Einkauf bei"
)
PAYPAL_REFERENCE_RE = re.compile(r"^\d{6,}(?:\s+PP\.8221\.PP)?\s*\.\s*")
PAYPAL_TRAILING_REFERENCE_RE = re.compile(r"\s+\d{6,}(?: [A-Z0-9.]+)* PAYPAL\b.*$")
PAYPAL_BARE_REFERENCE_RE = re.compile(r"^\d{6,}(?:\s+[A-Z0-9.]+)+$")
CARD_TIMESTAMP_RE = re.compile(r" \d{2}-\d{2}-\d{4}(?:T\d{2}:\d{2}:\d{2})?$")
LEADING_MERCHANT_CODE_RE = re.compile(r"^\d{3,}(?:\s+\d+)*\s+(?=[A-Za-z])")
LEADING_COMPACT_MERCHANT_CODE_RE = re.compile(r"^\d{3,}(?=[A-Za-z])")


@dataclass
class Transaction:
    booking_date: str
    value_date: str
    transaction_type: str
    payee: str | None
    narration: str
    detail_text: str
    amount: Decimal


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert Postbank statements to Beancount candidates."
    )
    parser.add_argument("--source-dir", required=True)
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--pdftotext", required=True)
    parser.add_argument("--ledger-account", required=True)
    parser.add_argument("--income-account", required=True)
    parser.add_argument("--expense-account", required=True)
    parser.add_argument("--currency", default="EUR")
    return parser.parse_args()


def normalize_spaces(value: str) -> str:
    return " ".join(value.split())


def parse_date(day_month: str, year: str) -> str:
    return datetime.strptime(f"{day_month}{year}", "%d.%m.%Y").date().isoformat()


def parse_german_amount(sign: str, number: str) -> Decimal:
    normalized = number.replace(".", "").replace(",", ".")
    value = Decimal(normalized)
    if sign == "-":
        value = -value
    return value.quantize(Decimal("0.01"))


def format_amount(value: Decimal) -> str:
    return f"{value.quantize(Decimal('0.01')):.2f}"


def bean_string(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def should_skip_line(line: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return True
    return bool(
        PAGE_FOOTER_RE.match(stripped)
        or PAGE_HEADER_RE.match(stripped)
        or PAGE_NUMBER_RE.match(stripped)
        or SECTION_HEADER_RE.match(stripped)
    )


def is_detail_metadata(line: str) -> bool:
    if line == GENERIC_MARKER:
        return True
    return any(line.startswith(prefix) for prefix in DETAIL_METADATA_PREFIXES)


def first_non_metadata(details: list[str]) -> str | None:
    for line in details:
        if not is_detail_metadata(line):
            return line
    return None


def extract_purpose_lines(details: list[str]) -> list[str]:
    purpose_lines: list[str] = []
    capture = False
    for line in details:
        if line == GENERIC_MARKER:
            capture = True
            continue
        if capture:
            if is_detail_metadata(line):
                break
            purpose_lines.append(line)
    return purpose_lines


def strip_merchant_noise(value: str) -> str:
    for separator in ("//", " T", " Kartennr.", " Folgenr."):
        if separator in value:
            value = value.split(separator, 1)[0]

    value = normalize_spaces(value.strip(" ,.-"))
    value = LEADING_MERCHANT_CODE_RE.sub("", value)
    value = LEADING_COMPACT_MERCHANT_CODE_RE.sub("", value)
    return normalize_spaces(value)


def clean_paypal_counterparty(candidate: str) -> str | None:
    candidate = normalize_spaces(candidate)
    candidate = PAYPAL_REFERENCE_RE.sub("", candidate)
    candidate = PAYPAL_TRAILING_REFERENCE_RE.sub("", candidate)
    candidate = candidate.removesuffix(" PAYPAL")
    candidate = candidate.strip(" ,.-")

    if not candidate or candidate.startswith("PayPal"):
        return None

    if re.fullmatch(r"(?:\d{6,}|PP\.8221\.PP(?: PAYPAL)?)", candidate):
        return None

    if PAYPAL_BARE_REFERENCE_RE.fullmatch(candidate):
        return None

    return candidate


def extract_paypal_counterparty(purpose_lines: list[str]) -> str | None:
    joined = normalize_spaces(" ".join(purpose_lines))

    for pattern in (PAYPAL_COUNTERPARTY_AFTER_RE, PAYPAL_COUNTERPARTY_BEFORE_RE):
        match = pattern.search(joined)
        if match is None:
            continue

        candidate = clean_paypal_counterparty(match.group("merchant"))
        if candidate:
            return candidate

    return None


def extract_card_payee(first_detail: str) -> str:
    value = normalize_spaces(first_detail)

    if "//" in value:
        value = value.split("//", 1)[0]
    elif "/" in value:
        value = value.split("/", 1)[0]

    for separator in (" Kartennr.", " Folgenr.", " Verfalld.", " T"):
        if separator in value:
            value = value.split(separator, 1)[0]

    value = CARD_TIMESTAMP_RE.sub("", value)
    return strip_merchant_noise(value)


def extract_cash_withdrawal_payee(first_detail: str) -> str:
    value = normalize_spaces(first_detail)

    if "//" in value:
        bank = value.split("//", 1)[1]
        bank = bank.split("/DE", 1)[0].split("/", 1)[0]
        bank = strip_merchant_noise(bank)
        if bank:
            return f"ATM {bank}"

    parts = [normalize_spaces(part) for part in value.split("/") if part]
    location_parts: list[str] = []

    for index, part in enumerate(parts):
        if part == "DE" or CARD_TIMESTAMP_RE.fullmatch(f" {part}"):
            break

        if index == 0 and re.fullmatch(r"[0-9 ]+", part):
            continue

        location_parts.append(part)

    if location_parts:
        return f"ATM {', '.join(location_parts[:2])}"

    return "ATM cash withdrawal"


def derive_payee(
    transaction_type: str,
    secondary_line: str,
    details: list[str],
    purpose_lines: list[str],
) -> str | None:
    if secondary_line != GENERIC_MARKER and secondary_line:
        if secondary_line.startswith("PayPal"):
            paypal_payee = extract_paypal_counterparty(purpose_lines)
            if paypal_payee:
                return paypal_payee
            return "PayPal"
        return strip_merchant_noise(secondary_line)

    first_detail = first_non_metadata(details)
    if first_detail is None or first_detail == "Saldo der Abschlussposten":
        return None

    if transaction_type == "Kartenzahlung":
        return extract_card_payee(first_detail)

    if transaction_type.startswith("Bargeldauszahlung"):
        return extract_cash_withdrawal_payee(first_detail)

    return strip_merchant_noise(first_detail)


def derive_narration(
    transaction_type: str,
    payee: str | None,
    purpose_lines: list[str],
    details: list[str],
) -> str:
    if transaction_type == GENERIC_MARKER:
        first_detail = first_non_metadata(details)
        if first_detail:
            return first_detail
        return "Postbank statement adjustment"

    if payee and payee.startswith("PayPal"):
        return transaction_type

    if purpose_lines and (
        "Ihr Einkauf bei" in " ".join(purpose_lines)
        or "PAYPAL" in " ".join(purpose_lines)
    ):
        return transaction_type

    if purpose_lines:
        first_purpose = purpose_lines[0]
        if payee and payee in first_purpose:
            return transaction_type
        return first_purpose

    return transaction_type


def render_transaction(
    transaction: Transaction,
    ledger_account: str,
    income_account: str,
    expense_account: str,
    currency: str,
    source_pdf: str,
) -> list[str]:
    if transaction.payee:
        header = f"{transaction.booking_date} * {bean_string(transaction.payee)} {bean_string(transaction.narration)}"
    else:
        header = f"{transaction.booking_date} * {bean_string(transaction.narration)}"

    counter_account = expense_account if transaction.amount < 0 else income_account

    lines = [
        header,
        f"  source_pdf: {bean_string(source_pdf)}",
        f"  postbank_value_date: {bean_string(transaction.value_date)}",
        f"  postbank_type: {bean_string(transaction.transaction_type)}",
    ]

    if transaction.detail_text:
        lines.append(f"  postbank_details: {bean_string(transaction.detail_text)}")

    lines.extend(
        [
            f"  {ledger_account}  {format_amount(transaction.amount)} {currency}",
            f"  {counter_account}",
            "",
        ]
    )
    return lines


def extract_text(pdftotext: str, pdf_path: Path) -> str:
    result = subprocess.run(
        [pdftotext, "-layout", str(pdf_path), "-"],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.replace("\f", "\n")


def parse_statement(
    text: str,
) -> tuple[str, str, Decimal | None, Decimal | None, list[Transaction]]:
    period_match = PERIOD_RE.search(text)
    if period_match is None:
        raise ValueError("Could not find statement period")

    opening_match = OPENING_BALANCE_RE.search(text)
    closing_match = CLOSING_BALANCE_RE.search(text)
    statement_start = (
        datetime.strptime(period_match.group(1), "%d.%m.%Y").date().isoformat()
    )
    statement_end = (
        datetime.strptime(period_match.group(2), "%d.%m.%Y").date().isoformat()
    )
    opening_balance = (
        parse_german_amount(opening_match.group(2), opening_match.group(3))
        if opening_match is not None
        else None
    )
    closing_balance = (
        parse_german_amount(closing_match.group(1), closing_match.group(2))
        if closing_match is not None
        else None
    )

    lines = text.splitlines()
    body_start = None
    for index, line in enumerate(lines):
        if SECTION_HEADER_RE.match(line.strip()):
            body_start = index + 1
            break

    if body_start is None:
        raise ValueError("Could not find transaction table")

    transactions: list[Transaction] = []
    current: dict[str, object] | None = None

    def finalize(entry: dict[str, object]) -> Transaction:
        booking_year = entry.get("booking_year")
        value_year = entry.get("value_year")
        secondary_line = entry.get("secondary_line")
        if (
            not isinstance(booking_year, str)
            or not isinstance(value_year, str)
            or not isinstance(secondary_line, str)
        ):
            raise ValueError(
                f"Incomplete transaction header for {entry['transaction_type']}"
            )

        details = [line for line in entry["details"] if isinstance(line, str)]
        purpose_lines = extract_purpose_lines(details)
        payee = derive_payee(
            entry["transaction_type"], secondary_line, details, purpose_lines
        )
        narration = derive_narration(
            entry["transaction_type"], payee, purpose_lines, details
        )
        detail_text = " | ".join([secondary_line] + details)

        return Transaction(
            booking_date=parse_date(entry["booking_day_month"], booking_year),
            value_date=parse_date(entry["value_day_month"], value_year),
            transaction_type=entry["transaction_type"],
            payee=payee,
            narration=narration,
            detail_text=detail_text,
            amount=entry["amount"],
        )

    for raw_line in lines[body_start:]:
        line = raw_line.rstrip()
        stripped = line.strip()

        if should_skip_line(line):
            continue

        if any(stripped.startswith(prefix) for prefix in STOP_PREFIXES):
            if current is not None:
                transactions.append(finalize(current))
                current = None
            break

        transaction_match = TRANSACTION_RE.match(line)
        if transaction_match:
            if current is not None:
                transactions.append(finalize(current))

            current = {
                "booking_day_month": transaction_match.group(1),
                "value_day_month": transaction_match.group(2),
                "transaction_type": normalize_spaces(transaction_match.group(3)),
                "amount": parse_german_amount(
                    transaction_match.group(4), transaction_match.group(5)
                ),
                "booking_year": None,
                "value_year": None,
                "secondary_line": None,
                "details": [],
            }
            continue

        if current is None:
            continue

        year_match = YEAR_LINE_RE.match(line)
        if year_match and current["secondary_line"] is None:
            current["booking_year"] = year_match.group(1)
            current["value_year"] = year_match.group(2)
            current["secondary_line"] = normalize_spaces(year_match.group(3))
            continue

        current["details"].append(normalize_spaces(stripped))

    if current is not None:
        transactions.append(finalize(current))

    if not transactions:
        raise ValueError("No transactions parsed from statement")

    return (
        statement_start,
        statement_end,
        opening_balance,
        closing_balance,
        transactions,
    )


def render_statement(
    source_pdf: Path,
    relative_pdf: Path,
    ledger_account: str,
    income_account: str,
    expense_account: str,
    currency: str,
    pdftotext: str,
) -> str:
    text = extract_text(pdftotext, source_pdf)
    statement_start, statement_end, opening_balance, closing_balance, transactions = (
        parse_statement(text)
    )
    relative_source = relative_pdf.as_posix()

    output_lines = [
        "; Generated from Postbank statement PDF.",
        f"; Source: {relative_source}",
        f"; Statement period: {statement_start} to {statement_end}",
    ]

    if opening_balance is not None:
        output_lines.append(
            f"; Opening balance: {format_amount(opening_balance)} {currency}"
        )

    output_lines.append("")

    for transaction in transactions:
        output_lines.extend(
            render_transaction(
                transaction,
                ledger_account=ledger_account,
                income_account=income_account,
                expense_account=expense_account,
                currency=currency,
                source_pdf=relative_source,
            )
        )

    if closing_balance is not None:
        output_lines.extend(
            [
                f"{statement_end} balance {ledger_account} {format_amount(closing_balance)} {currency}",
                "",
            ]
        )

    return "\n".join(output_lines)


def convert_statements(args: argparse.Namespace) -> int:
    source_dir = Path(args.source_dir).expanduser().resolve()
    output_dir = Path(args.output_dir).expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    pdf_paths = sorted(source_dir.rglob("Kontoauszug_*.pdf"))
    if not pdf_paths:
        print(f"No Postbank statement PDFs found in {source_dir}", file=sys.stderr)
        return 0

    for pdf_path in pdf_paths:
        relative_pdf = pdf_path.relative_to(source_dir)
        output_path = output_dir / relative_pdf.with_suffix(".beancount")
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(
            render_statement(
                source_pdf=pdf_path,
                relative_pdf=relative_pdf,
                ledger_account=args.ledger_account,
                income_account=args.income_account,
                expense_account=args.expense_account,
                currency=args.currency,
                pdftotext=args.pdftotext,
            )
            + "\n",
            encoding="utf-8",
        )
        print(f"Wrote {output_path}")

    return 0


def main() -> int:
    try:
        return convert_statements(parse_args())
    except Exception as exc:  # noqa: BLE001
        print(f"postbank-import: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
