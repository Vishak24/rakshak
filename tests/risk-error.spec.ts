import { test, expect, type Page } from '@playwright/test';

const PREDICT_URL = '**/predict';

const UNSTABLE = (page: Page) => [
  page.locator('#map'),
  page.locator('#sosList'),
  page.locator('#sosTodayCnt'),
  page.locator('#sosBadge'),
  page.locator('#respTime'),
];

test.describe('API failure → error state', () => {
  test.beforeEach(async ({ page }) => {
    // All zone requests fail with 500
    await page.route(PREDICT_URL, route =>
      route.fulfill({ status: 500, contentType: 'application/json', body: '{"error":"internal"}' })
    );
    await page.goto('/rakshak_dashboard.html');
    // Wait for fetchAll to finish: apiStatus text is updated last in showErrorState
    await expect(page.locator('#apiStatus')).toHaveText(
      'API unavailable · fallback data',
      { timeout: 10_000 },
    );
  });

  test('error message shown in status bar', async ({ page }) => {
    await expect(page.locator('#apiStatus')).toHaveText('API unavailable · fallback data');
  });

  test('live dot turns red', async ({ page }) => {
    await expect(page.locator('#liveDot')).toHaveCSS('background-color', 'rgb(255, 59, 92)');
  });

  test('fallback badge is still visible with static data', async ({ page }) => {
    // renderDashboard still runs; fallback gives HIGH zones riskIndex=82
    await expect(page.locator('#liveRiskBadge')).toBeVisible();
    await expect(page.locator('#liveRiskBadge')).toHaveText(/MAX RISK \d+\/100 · (HIGH|MEDIUM|LOW)/);
  });

  test('fallback badge shows red (riskIndex=82 from HIGH fallback)', async ({ page }) => {
    await expect(page.locator('#liveRiskBadge')).toHaveCSS('color', 'rgb(255, 59, 92)');
  });

  test('high risk zone count reflects static fallback (5 zones)', async ({ page }) => {
    await expect(page.locator('#highRiskCnt')).toHaveText('5');
  });

  test('screenshot – error state dashboard', async ({ page }) => {
    await page.addStyleTag({
      content: '*, *::before, *::after { animation-duration: 0s !important; transition-duration: 0s !important; }',
    });
    await expect(page).toHaveScreenshot('error-state.png', {
      mask: UNSTABLE(page),
      maxDiffPixelRatio: 0.02,
    });
  });
});
