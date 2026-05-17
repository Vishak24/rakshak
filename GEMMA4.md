# Rakshak 2.0 — Gemma 4 Integration

## Why Rakshak 2.0

Rakshak was independently validated by the AWS Builder Center as a working, production-grade system — not a prototype. The original version demonstrated a complete event-driven Lambda + SageMaker architecture, 44 manually verified zone coordinates, and a closed-loop citizen-to-police workflow. That foundation is real.

The core limitation of that system, however, is inherent to its ML layer: XGBoost makes purely statistical predictions. A zone that has historically low crime reports may receive a "safe" prediction even when current conditions — an unusual gathering, a poorly lit route at 2 AM, a recent spike in nearby incidents — suggest otherwise. This is the false-negative problem. In a women's safety context, a false negative is not a tolerable error rate. It is a failure with physical consequences.

Rakshak 2.0 replaces the static ML prediction layer with Gemma 4's dynamic contextual reasoning. Where XGBoost asks "what does historical data say about this pincode at this hour?", Gemma 4 asks "given everything known about this location right now — risk score, time, patrol availability, recent patterns — what is the safest interpretation?". Gemma 4 is explicitly instructed to err toward caution, making false negatives structurally less likely by design rather than by training data.

The result is a system where the validated infrastructure (Lambda, DynamoDB, API Gateway, the SOS dispatch pipeline) remains intact, and the intelligence layer upgrades from pattern matching to judgment.

## Architecture Change

| Layer | Rakshak 1.0 (AWS) | Rakshak 2.0 (Gemma 4) |
|---|---|---|
| Risk prediction | XGBoost (statistical) | XGBoost score → Gemma 4 reasoning |
| Explainability | SHAP values | Natural language explanation |
| Dispatch | Rule-based alert | Gemma 4 patrol recommendation |
| Suraksha Mode | Not present | Gemma 4 check-in + escalation |
| False-negative handling | Model accuracy (89%) | Explicit caution instruction |

## Endpoints

- `POST /gemma/explain` — contextual risk explanation for a zone
- `POST /gemma/dispatch` — patrol deployment recommendation
- `POST /gemma/checkin` — bilingual safety check-in message (Suraksha Mode)
- `POST /gemma/escalate` — police dispatch alert when user doesn't respond
