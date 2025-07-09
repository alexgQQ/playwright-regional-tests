// @ts-check
import { test, expect } from '@playwright/test';


test('loads images', async ({ page, browserName  }) => {
  let baseUrl = "https://parallaxbg.com";
  let failedImage = false;
  let imageCount = 0;

  const countImageRequest = (request) => {
    const url = request.url();
    if (url.startsWith(`${baseUrl}/images`)) {
      imageCount++;
    }
  }

  const checkChromiumImageResponse = (request) => {
    const url = request.url();
    if (url.startsWith(`${baseUrl}/images`)) {
      failedImage = true;
    }
  }

  const checkImageResponse = (response) => {
    const url = response.url();
    const status = response.status();
    if (url.startsWith(`${baseUrl}/images`) && status == 403) {
      failedImage = true;
    }
  }

  // This is an annoying quirk but chromium won't register the 403 as a response event
  //  as it tries to load the image but fails to parse, causing it to raise an error and
  // flag the request as failed, whereas firefox and safari will just register the response
  // as a 403
  if (browserName === "chromium") {
    page.on('requestfailed', checkChromiumImageResponse);
  } else {
    page.on('response', checkImageResponse);
  }
  page.on('request', countImageRequest);

  await page.goto(baseUrl);
  // Give the page plenty of time to load so request events are captured
  await page.waitForTimeout(3000);

  await expect(failedImage).toBeFalsy();
  await expect(imageCount).toBeGreaterThan(0);
});
