import { test, expect, type Page, type Route } from '@playwright/test';

const PREDICT_URL = '**/predict';

function mockPredict(page: Page, body: object) {
  return page.route(PREDICT_URL, (route: Route) =>
    route.fulfill({ contentType: 'application/json', body: JSON.stringify(body) })
  );
}

const HIGH_RESPONSE = {
  risk_level: 'HIGH',
  risk_index: 90,
  confidence: 0.95,
  probabilities: { low: 0.02, medium: 0.08, high: 0.90 },
};

// Masks for unstable elements so screenshots are deterministic
const UNSTABLE = (page: Page) => [
  page.locator('#map'),
  page.locator('#sosList'),
  page.locator('#sosTodayCnt'),
  page.locator('#sosBadge'),
  page.locator('#respTime'),
];

test.describe('riskIndex=90 → red critical state', () => {
  test.beforeEach(async ({ page }) => {
    await mockPredict(page, HIGH_RESPONSE);
    await page.goto('/rakshak_dashboard.html');
    // Badge visibility is the signal that fetchAll + renderDashboard completed
    await expect(page.locator('#liveRiskBadge')).toBeVisible({ timeout: 10_000 });
  });

  test('badge shows score and level text', async ({ page }) => {
    await expect(page.locator('#liveRiskBadge')).toHaveText('MAX RISK 90/100 · HIGH');
  });

  test('badge text color is red (≥80 threshold)', async ({ page }) => {
    await expect(page.locator('#liveRiskBadge')).toHaveCSS('color', 'rgb(255, 59, 92)');
  });

  test('badge background uses red tint', async ({ page }) => {
    await expect(page.locator('#liveRiskBadge')).toHaveCSS(
      'background-color',
      'rgba(255, 59, 92, 0.14)',
    );
  });

  test('all 44 zones counted as high risk', async ({ page }) => {
    await expect(page.locator('#highRiskCnt')).toHaveText('44');
  });

  test('live dot remains green (no error)', async ({ page }) => {
    // Default --safe color; clearErrorState was called
    await expect(page.locator('#liveDot')).toHaveCSS('background-color', 'rgb(34, 197, 94)');
  });

  test('screenshot – high risk dashboard', async ({ page }) => {
    await page.addStyleTag({
      content: '*, *::before, *::after { animation-duration: 0s !important; transition-duration: 0s !important; }',
    });
    await expect(page).toHaveScreenshot('high-risk.png', {
      mask: UNSTABLE(page),
      maxDiffPixelRatio: 0.02,
    });
  });
});
