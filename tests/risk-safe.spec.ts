import { test, expect, type Page, type Route } from '@playwright/test';

const PREDICT_URL = '**/predict';

function mockPredict(page: Page, body: object) {
  return page.route(PREDICT_URL, (route: Route) =>
    route.fulfill({ contentType: 'application/json', body: JSON.stringify(body) })
  );
}

const LOW_RESPONSE = {
  risk_level: 'LOW',
  risk_index: 42,
  confidence: 0.88,
  probabilities: { low: 0.85, medium: 0.12, high: 0.03 },
};

const MEDIUM_RESPONSE = {
  risk_level: 'MEDIUM',
  risk_index: 65,
  confidence: 0.81,
  probabilities: { low: 0.10, medium: 0.65, high: 0.25 },
};

const UNSTABLE = (page: Page) => [
  page.locator('#map'),
  page.locator('#sosList'),
  page.locator('#sosTodayCnt'),
  page.locator('#sosBadge'),
  page.locator('#respTime'),
];

// ── LOW (42) ──────────────────────────────────────────────────────────────────

test.describe('riskIndex=42 → teal safe state', () => {
  test.beforeEach(async ({ page }) => {
    await mockPredict(page, LOW_RESPONSE);
    await page.goto('/rakshak_dashboard.html');
    await expect(page.locator('#liveRiskBadge')).toBeVisible({ timeout: 10_000 });
  });

  test('badge shows score and level text', async ({ page }) => {
    await expect(page.locator('#liveRiskBadge')).toHaveText('MAX RISK 42/100 · LOW');
  });

  test('badge text color is teal/green (<50 threshold)', async ({ page }) => {
    await expect(page.locator('#liveRiskBadge')).toHaveCSS('color', 'rgb(34, 197, 94)');
  });

  test('badge background uses green tint', async ({ page }) => {
    await expect(page.locator('#liveRiskBadge')).toHaveCSS(
      'background-color',
      'rgba(34, 197, 94, 0.14)',
    );
  });

  test('zero zones counted as high risk', async ({ page }) => {
    await expect(page.locator('#highRiskCnt')).toHaveText('0');
  });

  test('screenshot – safe dashboard', async ({ page }) => {
    await page.addStyleTag({
      content: '*, *::before, *::after { animation-duration: 0s !important; transition-duration: 0s !important; }',
    });
    await expect(page).toHaveScreenshot('safe-risk.png', {
      mask: UNSTABLE(page),
      maxDiffPixelRatio: 0.02,
    });
  });
});

// ── MEDIUM (65) ───────────────────────────────────────────────────────────────

test.describe('riskIndex=65 → amber elevated state', () => {
  test.beforeEach(async ({ page }) => {
    await mockPredict(page, MEDIUM_RESPONSE);
    await page.goto('/rakshak_dashboard.html');
    await expect(page.locator('#liveRiskBadge')).toBeVisible({ timeout: 10_000 });
  });

  test('badge shows score and level text', async ({ page }) => {
    await expect(page.locator('#liveRiskBadge')).toHaveText('MAX RISK 65/100 · MEDIUM');
  });

  test('badge text color is amber (50–79 threshold)', async ({ page }) => {
    await expect(page.locator('#liveRiskBadge')).toHaveCSS('color', 'rgb(245, 158, 11)');
  });

  test('badge background uses amber tint', async ({ page }) => {
    await expect(page.locator('#liveRiskBadge')).toHaveCSS(
      'background-color',
      'rgba(245, 158, 11, 0.14)',
    );
  });

  test('zero zones counted as high risk', async ({ page }) => {
    await expect(page.locator('#highRiskCnt')).toHaveText('0');
  });
});
